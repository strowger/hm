#! /usr/bin/perl -w
#
# graph.pl - draw graphs
#
# GH 2015-06-19
# begun
#
$rrddirectory="/data/hm/rrd";
$logdirectory="/data/hm/log";
$graphdirectory="/data/hm/graph";
$logfile="graph.log";
$lockfile="/tmp/graph.lock";

if ( -f $lockfile ) 
{
  die "Lockfile exists in $lockfile; exiting";
}

open LOCKFILE, ">", $lockfile or die $!;

$output = `rrdtool graph $graphdirectory/temps.png -a PNG -l 0 -y 5:1 --vertical-label "deg c" -s -36h -w 1024 -h 300 'DEF:inside='$rrddirectory/roomtemp.rrd:temp:LAST 'DEF:outside='$rrddirectory/outdoortemp.rrd:temp:LAST 'DEF:boilerrm='$rrddirectory/cctemp.rrd:temp:LAST  'LINE1:inside#ff0000:inside temperature' 'LINE1:outside#0400ff:outside temperature' 'LINE1:boilerrm#00dd00:boiler room temperature' `;

$output = `rrdtool graph $graphdirectory/chtemps.png -a PNG -l 0 -y 10:1 --vertical-label "deg c" -s -36h -w 1024 -h 300 'DEF:cyl='$rrddirectory/cylindertemp.rrd:temp:LAST 'DEF:flow='$rrddirectory/flowtemp.rrd:temp:LAST 'DEF:desflow='$rrddirectory/desiredflowtemp.rrd:temp:LAST 'DEF:modtd='$rrddirectory/modtempdesired.rrd:temp:LAST 'LINE1:cyl#ff0000:cylinder temperature' 'LINE1:flow#0400ff:flow temperature' 'LINE1:desflow#111111:desired flow temperature' 'LINE1:modtd#666666:desired modulation'`;

$output = `rrdtool graph $graphdirectory/power.png -a PNG -l 0 -y 50:5 --vertical-label "watts" -s -36h -w 1024 -h 300 'DEF:optical='$rrddirectory/ccoptiwatts.rrd:power:LAST 'DEF:clamp='$rrddirectory/ccclampwatts.rrd:power:LAST 'LINE1:optical#ff0000:pulse-counter reading' 'LINE1:clamp#0400ff:clamp meter reading'`;

$output = `rrdtool graph $graphdirectory/waterpressure.png -a PNG -y 0.1:1 --vertical-label "bar" -s -36h -w 1024 -h 300 'DEF:pressure='$rrddirectory/waterpressure.rrd:pres:LAST 'LINE1:pressure#ff0000:water pressure'`;

$output = `rrdtool graph $graphdirectory/ionisationvolts.png -a PNG --vertical-label "volts/modulation percentage" -s -36h -w 1024 -h 300 'DEF:ion='$rrddirectory/ionisationvolts.rrd:volts:LAST 'DEF:modtd='$rrddirectory/modtempdesired.rrd:temp:LAST 'LINE1:ion#ff0000:flame sensor ionisation volts' 'LINE1:modtd#666666:desired modulation'  `;


close LOCKFILE;
unlink $lockfile;
