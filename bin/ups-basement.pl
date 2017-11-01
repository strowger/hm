#!/usr/bin/perl -w
 
# this is an older powerwalker vi 650 ups which uses the blazer_usb driver
# designed to be run from cron every minute

# GH 2017-10-29
# begun

$logdirectory="/data/hm/log";
#$logfile="ups-basement.log";
#$rrddirectory="/data/hm/rrd";
$lockfile="/tmp/ups-basement.lock";

if ( -f $lockfile )
{
  die "Lockfile exists in $lockfile; exiting";
}
open LOCKFILE, ">", $lockfile or die $!;


$checkforups = `/bin/lsusb|grep 0665|grep 5161`;
if ( $checkforups eq "" )
  { die "ups not detected\n"; }

@upsraw = split (" ",`/bin/upsc basement`);
$batterycharge = $upsraw[1];
$batteryvolts = $upsraw[3];
# this does not correspond well to http://www.dynamicdemand.co.uk/grid.htm
$mainsfreq = $upsraw[29];
$mainsvolts = $upsraw[33];
# this has non-obvious meaning and only reads the anomalous value once,
# after a fault: http://networkupstools.org/protocols/megatec.html
#$mainsfaultvolts = $upsraw[35];
$outputvolts = $upsraw[39];
# unclear what the units of load are
$upsload = $upsraw[47];
# "OL" online "OB" on battery
$upsstatus = $upsraw[51];
$upstemp = $upsraw[53];

if ( $upsstatus eq "OB" )
{ 
  print "UPS is on battery\n"; 
  `echo "basement UPS on battery" | /data/hm/bin/alert.pl`;
}

$timestamp = time();

open BATTERYCHARGE, ">>", "$logdirectory/upsb-batterycharge.log" or die $!;
print BATTERYCHARGE "$timestamp $batterycharge\n";
close BATTERYCHARGE;

open BATTERYVOLTS, ">>", "$logdirectory/upsb-batteryvolts.log" or die $!;
print BATTERYVOLTS "$timestamp $batteryvolts\n";
close BATTERYVOLTS;

open MAINSFREQ, ">>", "$logdirectory/upsb-mainsfreq.log" or die $!;
print MAINSFREQ "$timestamp $mainsfreq\n";
close MAINSFREQ;

open MAINSVOLTS, ">>", "$logdirectory/upsb-mainsvolts.log" or die $!;
print MAINSVOLTS "$timestamp $mainsvolts\n";
close MAINSVOLTS;

open OUTPUTVOLTS, ">>", "$logdirectory/upsb-outputvolts.log" or die $!;
print OUTPUTVOLTS "$timestamp $outputvolts\n";
close OUTPUTVOLTS;

open UPSLOAD, ">>", "$logdirectory/upsb-upsload.log" or die $!;
print UPSLOAD "$timestamp $upsload\n";
close UPSLOAD;

open UPSTEMP, ">>", "$logdirectory/upsb-upstemp.log" or die $!;
print UPSTEMP "$timestamp $upstemp\n";
close UPSTEMP;

#print "battery - charge (percent?): $batterycharge, voltage: $batteryvolts\n";
#print "ac power - frequency:  $mainsfreq, input voltage: $mainsvolts, output voltage: $outputvolts\n";
#print "ups load (units?): $upsload, status: $upsstatus, temperature: $upstemp\n";

close LOCKFILE;
unlink $lockfile;

exit 0;

