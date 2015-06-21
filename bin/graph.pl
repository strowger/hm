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

$output = `rrdtool graph $graphdirectory/power.png -a PNG -l 0 -y 50:5 --vertical-label "watts" -s -36h -w 1024 -h 300 'DEF:optical='$rrddirectory/ccoptiwatts.rrd:power:LAST 'DEF:clamp='$rrddirectory/ccclampwatts.rrd:power:LAST 'LINE1:optical#ff0000:pulse-counter reading' 'LINE1:clamp#0400ff:clamp meter reading'`;

close LOCKFILE;
unlink $lockfile;
