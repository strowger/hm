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
$starttime = $timestamp;

open LOGFILE, ">>", "$logdirectory/$logfile" or die $!;
print LOGFILE "starting air.pl at $timestamp\n";

open CONFIG, "<", "$config" or die $!;

# we just get the MAC from the config at the moment

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
      $advlen2 = $packetraw[33];
      $advmanufdata = $packetraw[34];
      $dataheader1 = $packetraw[35];
      $dataheader2 = $packetraw[36];
      if ( ($dataheader1 == 11) || ($dataheader1 == 21) || ($dataheader1 == 31) )
      { 
        print "sensor data part 1 packet: "; 
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
        # these aren't implemented and should be zero?
        $cohi = $packetdec[43];
        $colo = $packetdec[44];
        $co = ($cohi * 256) + $colo;
        # documentation is contradictory about whether o3 is 8-bit or 16 - but
        # there are no more values in the packet after this one... also it
        # flaps like crazy - probably it's a crc?
        $o3 = $packetdec[45];
        print "co2 ppme: $co2,";
        print "pm2.5 micrograms per m3: $pm25,";
        print "pm10 micrograms per m3: $pm10\n";
#        print "co values raw: $cohi $colo, cacluated value: $co\n";
#        print "o3 value: $o3\n";
        
      }
      if ( ($dataheader1 == 12) || ($dataheader1 == 22) || ($dataheader1 == 32) )
      { 
        print "sensor data part 2 packet: "; 
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
        $humidity = $packetdec[42];
# wtf! it's in their doc but it makes fuck-all sense to me
        $fact1 = ($temp * 17.62) / ($temp + 243.12);
        $fact2 = ($realtemp * 17.62) / ($realtemp + 243.12);
        $realhumidity = $humidity * ($fact1 / $fact2);
        $iaqhi = $packetdec[43];
        $iaqlo = $packetdec[44];
        $iaq = ($iaqhi * 256) + $iaqlo;        
        $crc = $packetdec[45];

        print "tvoc ppb $tvoc,";
        print "temperature $realtemp,"; 
#        print "humidity value: $humidity, processed humidity: $realhumidity\n";
        print "iaq $iaq\n";
#        print "crc $crc\n";
      }
    }
    else { print LOGFILE "Ignored a packet\n"; }
    ## finish manipulating the packet here and move on
    @packetraw = ();
    print "\n\n";
  }
  push (@packetraw, @lineitems);
}

close LOGFILE;
#close LOCKFILE;
#unlink $lockfile;

