#! /usr/bin/perl -w
#
# beacon.pl
#
# GH 20160923
#
# To run this script, pipe the "hcidump" output in to it, while 
# "hcitool lescan" is running. Note that these must be done as root otherwise
# the hcidump command will produce no output. Usually need to "hciconfig hci0 up"
# at boot-time before all this will work.
#
# In the event of error, do these and restart:
#  hciconfig hci0 down ; hciconfig hci0 reset ; hciconfig hci0 up
#
# Usage:
# sudo hcidump -i hci0 -R|./beacon.pl
# sudo hcidump -i hci0 -XR is friendlier for manual examingation (shows ascii too, & rssi)
 
$config="/data/hm/conf/beacon.conf";
##$rrddirectory="/data/hm/rrd";
##$logdirectory="/data/hm/log";
##$logfile="beacon.log";
## FIXME no locking during dev
##$lockfile="/tmp/beacon.lock";
##
##if ( -f $lockfile )
##{
##  die "Lockfile exists in $lockfile; exiting";
##}

##open LOCKFILE, ">", $lockfile or die $!;

##$timestamp = time();

##open LOGFILE, ">>", "$logdirectory/$logfile" or die $!;
##print LOGFILE "\nstarting beacon.pl at $timestamp\n";

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
##    print LOGFILE "$timestamp: read mac $macaddress, name $devicename from config\n";
  }
}

if ((! defined $macaddress) || (! defined $devicename))
{ die ("haven't got a device mac and name from config"); }

# the mac occurs backwards in the packets as-captured
@revmac = reverse (split(":","$macaddress"));

print "use a window at least 137 cols wide\n";
print "00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45\n";
print "-----------------------------------------------------------------------------------------------------------------------------------------\n";

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
    @revpacketmac = @packetraw[7..12];
    @packetmac = reverse @revpacketmac;
    $packetlength = scalar (@packetraw);

    # comparing arrays is hard, we coerce them in to strings and lowercase them
    if (($packetlength == "46") && (lc "@revmac" eq lc "@revpacketmac"))
    {
#      print "yay got a frame from our beloved's mac $macaddress\n";
      # SUPPOSEDLY the last 3 bytes are a CRC, the first 7 are "preamble", "access address", and "pdu header", which i think never change and then the next 6 are our mac
      # in practice it looks like
      # 00
      # 01
      # 02
      # 03
      # 04
      # 05
      # 06
      # 07-12 related to service 0x180A characteristic 0x2a23 ?
      # 08 
      # 09
      # 10
      # 11
      # 12
      # 13
      # 14
      # 15
      # 16
      # 17 
      # 18
      # 19
      # 20
      # 21
      # 22
      # 23 - 38 ibeacon uuid
      # 39 spec says is 2-byte major no; seems to change if i warm it up
      # 40 spec says is 2-byte major no; seems to change if i warm it up
      # 41 spec says is 2-byte minor no; seems to change if i warm it up 
      # 42 spec says is 2-byte minor no; seems to change if i warm it up
      # 43 power level value configured (measured power - defaults to 203 / 0xCB)
      # 44 battery level as percentage? ref https://www.beaconzone.co.uk/blog/getting-the-ankhmaway-battery-level-from-advertising-data/
      # 45 changes even when nothing else on the line has changed - suggests is not crc
      #
      print "@packetraw[0..45]\n"; # whole frame
#       print "@packetraw[13..45]\n"; # the actual data
#       print "@packetraw[39..42]\n"
      $uuid = join('', @packetraw[23..26]) . "-" . join('', @packetraw[27..28]) . "-" . join('', @packetraw[29..30]) . "-" . join('', @packetraw[31..32]) . "-" . join('', @packetraw[33..38]);
      $majorhi = $packetdec[39];
      $majorlo = $packetdec[40];
      $minorhi = $packetdec[41];
      $minorlo = $packetdec[42];
      # $powervalue = $packdec[43]; # really uninteresting
      $batterylevel = $packetdec[44];
      
      print "mac @packetmac, uuid $uuid, major values $majorhi $majorlo, minor values $minorhi $minorlo, battery % $batterylevel\n";
    }
    else
    {
##      print "ignored a frame from some other fucker who has mac @packetmac\n";
    }
    ## finish manipulating the packet here and move on
    @packetraw = ();
  }
  push (@packetraw, @lineitems);
}

##close LOGFILE;
## FIXME no locking during dev
##close LOCKFILE;
##unlink $lockfile;

