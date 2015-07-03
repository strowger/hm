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

@periods = ("1h", "36h", "10d");

if ( -f $lockfile ) 
{
  die "Lockfile exists in $lockfile; exiting";
}

open LOCKFILE, ">", $lockfile or die $!;

foreach $time (@periods)
{

  $output = `rrdtool graph $graphdirectory/temps${time}.png -a PNG -l 0 -y 5:1 --vertical-label "deg c" -s -${time} -w 1024 -h 300 'DEF:inside='$rrddirectory/roomtemp.rrd:temp:LAST 'DEF:outside='$rrddirectory/outdoortemp.rrd:temp:LAST 'DEF:boilerrmcc='$rrddirectory/cctemp.rrd:temp:LAST 'DEF:boilerrm='$rrddirectory/boilerrmtemp.rrd:temp:LAST 'DEF:cellar='$rrddirectory/cellartemp.rrd:temp:LAST 'LINE1:inside#ff0000:kitchen temp' 'LINE1:outside#0400ff:outside temp' 'LINE1:boilerrmcc#00dd00:boiler room temp - cc' 'LINE1:boilerrm#00dddd:boiler room temp - swe3' 'LINE1:cellar#dd00dd:cellar temp' `;

  $output = `rrdtool graph $graphdirectory/humidity${time}.png -a PNG -l 0 -y 5:1 --vertical-label "percent rh" -s -${time} -w 1024 -h 300 'DEF:boilerrm='$rrddirectory/boilerrmhum.rrd:hum:LAST 'DEF:cellar='$rrddirectory/cellarhum.rrd:hum:LAST 'LINE1:cellar#ff0000:cellar' 'LINE1:boilerrm#0000ff:boiler room' `;

  $output = `rrdtool graph $graphdirectory/chtemps${time}.png -a PNG -l 0 -y 10:1 --vertical-label "deg c" -s -${time} -w 1024 -h 300 'DEF:cyl='$rrddirectory/cylindertemp.rrd:temp:LAST 'DEF:ebflow='$rrddirectory/ebflowtemp.rrd:temp:LAST 'DEF:desflow='$rrddirectory/desiredflowtemp.rrd:temp:LAST 'DEF:modtd='$rrddirectory/modtempdesired.rrd:temp:LAST 'DEF:bflow='$rrddirectory/boilerflow.rrd:temp:LAST 'DEF:brtn='$rrddirectory/boilerreturn.rrd:temp:LAST 'LINE1:cyl#ff0000:cylinder temp - ebus' 'LINE1:ebflow#0400ff:flow temp - ebus' 'LINE1:desflow#009999:desired flow temp' 'LINE1:modtd#666666:desired modulation' 'LINE1:bflow#330033:flow temp - 1wire' 'LINE1:brtn#888800:return temp - 1wire' `;

  $output = `rrdtool graph $graphdirectory/power${time}.png -a PNG -l 0 -y 50:5 --vertical-label "watts" -s -${time} -w 1024 -h 300 'DEF:optical='$rrddirectory/ccoptiwatts.rrd:power:LAST 'DEF:clamp='$rrddirectory/ccclampwatts.rrd:power:LAST 'LINE1:optical#ff0000:pulse-counter reading' 'LINE1:clamp#0400ff:clamp meter reading'`;

  $output = `rrdtool graph $graphdirectory/waterpressure${time}.png -a PNG -y 0.1:1 --vertical-label "bar" -s -${time} -w 1024 -h 300 'DEF:pressure='$rrddirectory/waterpressure.rrd:pres:LAST 'LINE1:pressure#ff0000:water pressure'`;

  $output = `rrdtool graph $graphdirectory/ionisationvolts${time}.png -a PNG --vertical-label "volts/modulation percentage" -s -${time} -w 1024 -h 300 'DEF:ion='$rrddirectory/ionisationvolts.rrd:volts:LAST 'DEF:modtd='$rrddirectory/modtempdesired.rrd:temp:LAST 'LINE1:ion#ff0000:flame sensor ionisation volts' 'LINE1:modtd#666666:desired modulation'  `;
}

close LOCKFILE;
unlink $lockfile;
