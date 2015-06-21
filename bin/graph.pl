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

$output = `rrdtool graph $graphdirectory/temps.png -a PNG -l 0 -y 5:1 --vertical-label "deg c" -s -36h -w 1024 -h 300 'DEF:inside='$rrddirectory/roomtemp.rrd:temp:LAST 'DEF:outside='$rrddirectory/outdoortemp.rrd:temp:LAST 'LINE1:inside#ff0000:inside temperature' 'LINE1:outside#0400ff:outside temperature'`;

close LOCKFILE;
unlink $lockfile;
