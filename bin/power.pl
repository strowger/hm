#!/usr/bin/perl -w
 
# 20101009
# designed to run constantly in background. captures data from
# currentcost and writes to rrd and logfile
# 20130312
# add 'optismart' meter
# 20150619 GH
# move to styes, alter device name, paths

$logdirectory="/data/hm/log";
$logfile="power.log";
$rrddirectory="/data/hm/rrd";

`stty -F /dev/currentcost 57600`;
`stty -F /dev/currentcost oddp`;

# the old logfile only held clamp meter data
open LOGFILE, "+>>", "$logdirectory/$logfile" or die $!;
open SERIAL, "<", "/dev/currentcost" or die $!;

while (1) {
# run forever

while ($line = <SERIAL>)
{
  $timestamp = time();
  print LOGFILE "$timestamp $line";
  # catch only the real-time data and not the historical stuff it chucks out periodically
  # sensor 0 is the clamp meter
  # sensor 8 is the calculated watts value from the optismart??
  # sensor 9 we ignore, it's the raw value of impulses from the optismart??
  if ($line =~ m!<tmpr>\s*(-*[\d.]+)</tmpr><sensor>0</sensor>.*<ch1><watts>0*(\d+)</watts></ch1>!)
  {
     $temp = $1;
     $powerclamp = $2;
     print LOGFILE "Got $powerclamp W $temp C from clamp meter\n";
##     `rrdtool update $rrddirectory/currentcost.rrd $timestamp:$temp:$powerclamp`;
  }
  if ($line =~ m!<tmpr>\s*(-*[\d.]+)</tmpr><sensor>8</sensor>.*<ch1><watts>0*(\d+)</watts></ch1>!)
  {
     $temp = $1;
     $poweropti = $2;
     print LOGFILE "Got $poweropti W $temp C from optical meter\n";
     # no point keeping the temperature again.
##     `rrdtool update $rrddirectory/currentcostoptical.rrd $timestamp:$poweropti`;	
  }
  if ($line =~ m!<tmpr>\s*(-*[\d.]+)</tmpr><sensor>9</sensor>.*<imp>0*(\d+)</imp>!)
  {
    $temp = $1;
    $powerimp = $2;
    print LOGFILE "Got $powerimp count $temp C from optical meter\n";
##    `rrdtool update $rrddirectory/currentcostcount.rrd $timestamp:$powerimp`;
    last;
  }
}
}
close(SERIAL);

