#! /usr/bin/perl -w
#
# air.pl
#
# GH 20160313
#
# This script parses Bluetooth LE broadcasts from an air quality monitoring
# device. The name of the device and its vendor do not appear in this script
# as the vendor is not willing to have its details disclosed.
#
# To run this script, pipe the "hcidump" output in to it, while 
# "hcitool lescan" is running. Note that these must be done as root otherwise
# the hcidump command will produce no output.
#
# sudo hcidump -i hci0 -R|./am.pl
# sudo hcidump -i hci0 -XR is friendlier for manual (shows ascii too, and rssi)
 
$config="/data/hm/conf/air.conf";
$rrddirectory="/data/hm/rrd";
$logdirectory="/data/hm/log";
$logfile="air.log";
$lockfile="/tmp/air.lock";

if ( -f $lockfile )
{
  die "Lockfile exists in $lockfile; exiting";
}

# not doing locking during dev - too annoying
#open LOCKFILE, ">", $lockfile or die $!;

$timestamp = time();

open LOGFILE, ">>", "$logdirectory/$logfile" or die $!;
print LOGFILE "\nstarting air.pl at $timestamp\n";

open CONFIG, "<", "$config" or die $!;

# we just get the MAC and a name for the rrds and logs from the config at the moment

foreach $configline (<CONFIG>)
{
  # really we should build a list of devices here but for now we just need to
  # keep our device's mac out of the code
  ($macaddress, $devicename) = split(',',$configline);
  if (($macaddress !~ /\#.*/) && (defined $macaddress) && (defined $devicename))
  {
    chomp $devicename;
    print "$timestamp: read mac $macaddress, name $devicename from config\n";
  }
}

if ((! defined $macaddress) || (! defined $devicename))
{ die ("haven't got a device mac and name from config"); }

# the mac occurs backwards in the packets as-captured
@mac = reverse (split(":","$macaddress"));

# we'll track the last time we had a packet of each type so we don't
# thrash the system constantly calling rrdtool
$lastpt1packet = 0;
$lastpt2packet = 0;

while (<STDIN>)
{
  $line = $_;
  chomp $line;
  # 20 things per line + a ">" at the start of a new packet
  @lineitems = split (" ", $line);
  # ignore the two preamble lines hcidump produces on startup
  if ( ($lineitems[0] eq "HCI") || ($lineitems[0] eq "device:"))
  { next; }

  # new packet marker in the hcidump output is a > at start of line
  if ($lineitems[0] eq ">")
  {
    # remove the ">" character at the start
    splice (@lineitems, 0, 1);
    ## manipulate the packet here
    @packetdec = ();
    @packetascii = ();
    # print the packet as hex
    # and ascii
    foreach $byte (@packetraw)
    {
      $convbyte = hex ($byte);
      push (@packetdec, $convbyte);
      $asciibyte = chr ($convbyte);
      push (@packetascii, $asciibyte);
    }
    # get the MAC - remember it's reversed
    @packetmac = @packetraw[7..12];
# the device's name - we should check for this in the packets as it does appear
# but as per comment at start of script, we don't
#    $vendorstring = join('',@packetascii[19..32]);
    $packetlength = scalar (@packetraw);
#    if (( $vendorstring eq "Air Mentor Pro") && ($packetlength == "46"))
    # instead, we'll check the length and the mac
    # comparing arrays is hard, we coerce them in to strings and lowercase them
    if (($packetlength == "46") && (lc "@mac" eq lc "@packetmac"))
    {
#      $advlen2 = $packetraw[33];
#      $advmanufdata = $packetraw[34];
      $dataheader1 = $packetraw[35];
#      $dataheader2 = $packetraw[36];
      if ( ($dataheader1 == 11) || ($dataheader1 == 21) || ($dataheader1 == 31) )
      { 
        $timestamp = time();
        print LOGFILE "$timestamp sensor pt 1 packet: "; 
        # these are 16-bit numbers
        $co2hi = $packetdec[37];
        $co2lo = $packetdec[38];
        $co2 = ($co2hi * 256) + $co2lo;
        $pm25hi = $packetdec[39];
        $pm25lo = $packetdec[40];
        $pm25 = ($pm25hi * 256) + $pm25lo;
        $pm10hi = $packetdec[41];
        $pm10lo = $packetdec[42];
        $pm10 = ($pm10hi * 256) + $pm10lo;
        # these aren't implemented and should be zero
        $co = $packetdec[43];
        $o3 = $packetdec[44];
#        $crc = $packetdec[45];
        print LOGFILE "co2: $co2,";
        print LOGFILE "pm25: $pm25,";
        print LOGFILE "pm10: $pm10,";
        print LOGFILE "co: $co,";
        print LOGFILE "o3: $o3";
#        print "crc: $crc\n";
        if (($timestamp - $lastpt1packet) < 50)
        {
          # less than 50 seconds since the last update, don't write
          print LOGFILE "\n";
        }
        else
        {
          $lastpt1packet = $timestamp;
          print LOGFILE " - writing to rrd and log ";
          # co2
          open LINE, ">>", "$logdirectory/air${devicename}-co2.log" or die $!;
          print LINE "$timestamp $co2\n";
          close LINE;
          if ( -f "$rrddirectory/air${devicename}-co2.rrd" )
          {
            $output = `rrdtool update $rrddirectory/air${devicename}-co2.rrd $timestamp:$co2`;
            if (length $output) { print LOGFILE "rrdtool errored $output"; }  
          }
          else { print LOGFILE "rrd for air${devicename}-co2 doesn't exist, skipping update"; }
          # pm2.5
          open LINE, ">>", "$logdirectory/air${devicename}-pm25.log" or die $!;
          print LINE "$timestamp $pm25\n";
          close LINE;
          if ( -f "$rrddirectory/air${devicename}-pm25.rrd" )
          {
            $output = `rrdtool update $rrddirectory/air${devicename}-pm25.rrd $timestamp:$pm25`;
            if (length $output) { print LOGFILE "rrdtool errored $output"; }
          }
          else { print LOGFILE "rrd for air${devicename}-pm25 doesn't exist, skipping update"; }          
          # pm10
          open LINE, ">>", "$logdirectory/air${devicename}-pm10.log" or die $!;
          print LINE "$timestamp $pm10\n";
          close LINE;
          if ( -f "$rrddirectory/air${devicename}-pm10.rrd" )
          {
            $output = `rrdtool update $rrddirectory/air${devicename}-pm10.rrd $timestamp:$pm10`;
            if (length $output) { print LOGFILE "rrdtool errored $output"; }
          }
          else { print LOGFILE "rrd for air${devicename}-pm10 doesn't exist, skipping update"; }          
          print LOGFILE "\n"; 
        }
      }
      if ( ($dataheader1 == 12) || ($dataheader1 == 22) || ($dataheader1 == 32) )
      { 
        $timestamp = time();
        print LOGFILE "$timestamp sensor pt2 packet: "; 
        $tvochi = $packetdec[37];
        $tvoclo = $packetdec[38];
        $tvoc = ($tvochi * 256) + $tvoclo;
        $temphi = $packetdec[39];
        $templo = $packetdec[40];
        $temp = ($temphi * 256) + $templo;
        # doc says "temp - 4000 x 0.01 X"
        $proctemp = ($temp - 4000) * 0.01; 
        $deltatemp = $packetdec[41];
        $realtemp = $proctemp - ($deltatemp * 0.1);
# the humidity values i get don't make sense to me, or match the phone app
#        $humidity = $packetdec[42];
# wtf! it's in their doc but it makes fuck-all sense to me
#        $fact1 = ($temp * 17.62) / ($temp + 243.12);
#        $fact2 = ($realtemp * 17.62) / ($realtemp + 243.12);
#        $realhumidity = $humidity * ($fact1 / $fact2);
        $iaqhi = $packetdec[43];
        $iaqlo = $packetdec[44];
        $iaq = ($iaqhi * 256) + $iaqlo;        
#        $crc = $packetdec[45];

        print LOGFILE "tvoc: $tvoc,";
        print LOGFILE "temp: $realtemp,"; 
#        print "humidity value: $humidity, processed humidity: $realhumidity\n";
        print LOGFILE "iaq: $iaq";
#        print "crc $crc\n";
        if (($timestamp - $lastpt2packet) < 50)
        {
        # less than 50 seconds since the last update, don't write
          print LOGFILE "\n";
        }
        else
        {
          $lastpt2packet = $timestamp;
          print LOGFILE " - writing to rrd and log ";
          # tvoc
          open LINE, ">>", "$logdirectory/air${devicename}-tvoc.log" or die $!;
          print LINE "$timestamp $tvoc\n";
          close LINE;
          if ( -f "$rrddirectory/air${devicename}-tvoc.rrd" )
          {
            $output = `rrdtool update $rrddirectory/air${devicename}-tvoc.rrd $timestamp:$tvoc`;
            if (length $output) { print LOGFILE "rrdtool errored $output"; }
          }
          else { print LOGFILE "rrd for air${devicename}-tvoc doesn't exist, skipping update"; }
          # iaq
          open LINE, ">>", "$logdirectory/air${devicename}-iaq.log" or die $!;
          print LINE "$timestamp $iaq\n";
          close LINE;
          if ( -f "$rrddirectory/air${devicename}-iaq.rrd" )
          {
            $output = `rrdtool update $rrddirectory/air${devicename}-iaq.rrd $timestamp:$iaq`;
            if (length $output) { print LOGFILE "rrdtool errored $output"; }
          }
          else { print LOGFILE "rrd for air${devicename}-iaq doesn't exist, skipping update"; }
          print LOGFILE "\n";
        }
      }
    }
    else { print LOGFILE "Ignored a packet\n"; } # FIXME print its mac or something at least
    ## finish manipulating the packet here and move on
    @packetraw = ();
    print ".";
  }
  push (@packetraw, @lineitems);
}

close LOGFILE;
#close LOCKFILE;
#unlink $lockfile;

