#!/usr/bin/perl -w
 
# 20101009
# designed to run constantly in background. captures data from
# currentcost and writes to rrd and logfile
# 20130312
# add 'optismart' meter
# 20150619 GH
# move to styes, alter device name, paths, tidy up logging
# 20170404 GH
# stop logging the clamp meter as that's now the car charger and will
# be handled by the new rtl433 scripts
# 20180408 GH
# influxdb added

# log everything we get in the temp log, delete it at startup
# log the values we capture in the power log and keep forever

$logdirectory="/data/hm/log";
$templogfile="powertemp.log";
$logfile="power.log";
$rrddirectory="/data/hm/rrd";

$influxcmd="curl -s -S -i -XPOST ";
$influxurl="http://localhost:8086/";
$influxdb="styes_power";

# relies on udev having been configured to create a /dev/currentcost
# pointing at the correct serial device and with suitable permissions

`stty -F /dev/currentcost 57600`;
`stty -F /dev/currentcost oddp`;

open TEMPLOG, ">", "$logdirectory/$templogfile" or die $!;
open LOGFILE, "+>>", "$logdirectory/$logfile" or die $!;
open SERIAL, "<", "/dev/currentcost" or die $!;

while (1) {
# run forever

while ($line = <SERIAL>)
{
  $timestamp = time();
  print TEMPLOG "$timestamp: $line";
  # catch only the real-time data and not the historical stuff it chucks out periodically
  # sensor 0 is the clamp meter
  # sensor 8 is the calculated watts value from the optismart??
  # sensor 9 is the raw value of impulses from the optismart??
  if ($line =~ m!<tmpr>\s*(-*[\d.]+)</tmpr><sensor>0</sensor>.*<ch1><watts>0*(\d+)</watts></ch1>!)
  {
#     $temp = $1;
#     $powerclamp = $2;
#     print LOGFILE "$timestamp clamp ${powerclamp}W ${temp}C\n";
#     $output = `rrdtool update $rrddirectory/ccclampwatts.rrd $timestamp:$powerclamp`;
##     print TEMPLOG "rrdtool said $output\n";
#     $output = `rrdtool update $rrddirectory/cctemp.rrd $timestamp:$temp`;
##     print TEMPLOG "rrdtool said $output\n";
  }
  if ($line =~ m!<tmpr>\s*(-*[\d.]+)</tmpr><sensor>8</sensor>.*<ch1><watts>0*(\d+)</watts></ch1>!)
  {
     $temp = $1;
     $poweropti = $2;
     print LOGFILE "$timestamp opti ${poweropti}W ${temp}C\n";
     $output = `rrdtool update $rrddirectory/ccoptiwatts.rrd $timestamp:$poweropti`;
     $output2 = `${influxcmd} '${influxurl}write?db=${influxdb}' --data-binary 'wholehouse_optical value=${poweropti} ${timestamp}000000000\n'`;
#     print TEMPLOG "rrdtool said $output\n";
     $output = `rrdtool update $rrddirectory/cctemp.rrd $timestamp:$temp`;
#     print TEMPLOG "rrdtool said $output\n";
  }
  if ($line =~ m!<tmpr>\s*(-*[\d.]+)</tmpr><sensor>9</sensor>.*<imp>0*(\d+)</imp>!)
  {
    $temp = $1;
    $powerimp = $2;
    print LOGFILE "$timestamp opti ${powerimp}cnt ${temp}C\n";
    $output = `rrdtool update $rrddirectory/ccopticount.rrd $timestamp:$powerimp`;
#    print TEMPLOG "rrdtool said $output\n";
    $output = `rrdtool update $rrddirectory/cctemp.rrd $timestamp:$temp`;
#    print TEMPLOG "rrdtool said $output\n";
  }
}
}
close(SERIAL);

