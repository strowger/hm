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

# http://html-color-codes.com/
$col01="CC0033"; # darkish red
$col02="99CC00"; # putrid green
$col03="00CC99"; # turquoise
$col04="3300CC"; # purple
$col05="FF00CC"; # pink
$col06="FF9933"; # beige
$col07="EEEE33"; # yellowish
$col08="33FF00"; # hivis green
$col09="00FFFF"; # lightish blue
$col10="0000FF"; # darkish blue
$col11="FF3300"; # brightish orange
$col12="000000"; # black


# FIXME it's a bit mad to generate the 3month graphs every time
@periods = ("1h", "36h", "10d", "3mon");
#@periods = ("1h", "36h", "10d");

if ( -f $lockfile ) 
{
  die "Lockfile exists in $lockfile; exiting";
}

open LOCKFILE, ">", $lockfile or die $!;

foreach $time (@periods)
{

  $output = `rrdtool graph $graphdirectory/temps${time}.png -a PNG -l 0 -y 5:1 --vertical-label "deg c" -s -${time} -w 1024 -h 300 'DEF:inside='$rrddirectory/roomtemp.rrd:temp:LAST 'DEF:outside='$rrddirectory/outdoortemp.rrd:temp:LAST 'DEF:boilerrmcc='$rrddirectory/cctemp.rrd:temp:LAST 'DEF:boilerrm='$rrddirectory/boilerrmtemp.rrd:temp:LAST 'DEF:cellar='$rrddirectory/cellartemp.rrd:temp:LAST 'DEF:office='$rrddirectory/officetemp.rrd:temp:LAST 'DEF:officeunderfloor='$rrddirectory/officeunderfloor.rrd:temp:LAST  'DEF:coal='$rrddirectory/coaltemp.rrd:temp:LAST 'LINE1:inside#${col01}:kitchen temp' 'LINE1:outside#${col02}:outside temp' 'LINE1:boilerrmcc#${col03}:boiler room temp - cc' 'LINE1:boilerrm#${col04}:boiler room temp - swe3' 'LINE1:cellar#${col05}:cellar temp' 'LINE1:office#${col06}:office temp' 'LINE1:officeunderfloor#${col07}:office underfloor temp' 'LINE1:coal#${col08}:coal cellar temp' `;

  $output = `rrdtool graph $graphdirectory/humidity${time}.png -a PNG -l 0 -y 5:1 --vertical-label "percent rh" -s -${time} -w 1024 -h 300 'DEF:boilerrm='$rrddirectory/boilerrmhum.rrd:hum:LAST 'DEF:cellar='$rrddirectory/cellarhum.rrd:hum:LAST 'DEF:office='$rrddirectory/officehum.rrd:hum:LAST 'DEF:coal='$rrddirectory/coalhum.rrd:hum:LAST 'LINE1:cellar#${col01}:cellar' 'LINE1:boilerrm#${col02}:boiler room' 'LINE1:office#${col03}:office' 'LINE1:coal#${col04}:coal cellar' `;

  $output = `rrdtool graph $graphdirectory/chtemps${time}.png -a PNG -l 0 -y 10:1 --vertical-label "deg c" -s -${time} -w 1024 -h 300 'DEF:cyl='$rrddirectory/cylindertemp.rrd:temp:LAST 'DEF:ebflow='$rrddirectory/ebflowtemp.rrd:temp:LAST 'DEF:ebreturn='$rrddirectory/ebreturntemp.rrd:temp:LAST 'DEF:desflow='$rrddirectory/desiredflowtemp.rrd:temp:LAST 'DEF:modtd='$rrddirectory/modtempdesired.rrd:temp:LAST 'DEF:bflow='$rrddirectory/boilerflow.rrd:temp:LAST 'DEF:brtn='$rrddirectory/boilerreturn.rrd:temp:LAST 'DEF:zvu='$rrddirectory/zvupstairsflow.rrd:temp:LAST 'DEF:zvd='$rrddirectory/zvdownstairsflow.rrd:temp:LAST 'DEF:zvh='$rrddirectory/zvhwflow.rrd:temp:LAST  'LINE1:cyl#${col01}:cylinder temp - ebus' 'LINE1:ebflow#${col02}:flow temp - ebus' 'LINE1:ebreturn#${col03}:return temp - ebus' 'LINE1:desflow#${col04}:desired flow temp' 'LINE1:modtd#${col05}:desired modulation' 'LINE1:bflow#${col06}:flow temp - 1wire' 'LINE1:brtn#${col07}:return temp - 1wire' 'LINE1:zvu#${col08}:flow temp to upstairs' 'LINE1:zvd#${col09}:flow temp to downstairs' 'LINE1:zvh#${col10}:flow temp to hw tank'`;

  $output = `rrdtool graph $graphdirectory/power${time}.png -a PNG -l 0 -y 50:5 --vertical-label "watts" -s -${time} -w 1024 -h 300 'DEF:optical='$rrddirectory/ccoptiwatts.rrd:power:LAST 'DEF:clamp='$rrddirectory/ccclampwatts.rrd:power:LAST 'LINE1:optical#${col01}:pulse-counter reading' 'LINE1:clamp#${col02}:clamp meter reading'`;

  $output = `rrdtool graph $graphdirectory/waterpressure${time}.png -a PNG -y 0.1:1 --vertical-label "bar" -s -${time} -w 1024 -h 300 'DEF:pressure='$rrddirectory/waterpressure.rrd:pres:LAST 'LINE1:pressure#${col01}:water pressure'`;

  $output = `rrdtool graph $graphdirectory/ionisationvolts${time}.png -a PNG --vertical-label "volts/modulation percentage" -s -${time} -w 1024 -h 300 'DEF:ion='$rrddirectory/ionisationvolts.rrd:volts:LAST 'DEF:modtd='$rrddirectory/modtempdesired.rrd:temp:LAST 'LINE1:ion#${col01}:flame sensor ionisation volts' 'LINE1:modtd#${col02}:desired modulation'  `;

  $output = `rrdtool graph $graphdirectory/busvolts${time}.png -a PNG --vertical-label "volts" -s -${time} -w 1024 -h 300 'DEF:boilerrm='$rrddirectory/boilerrmvdd.rrd:vdd:LAST 'DEF:cellar='$rrddirectory/cellarvdd.rrd:vdd:LAST 'DEF:office='$rrddirectory/officevdd.rrd:vdd:LAST 'DEF:coal='$rrddirectory/coalvdd.rrd:vdd:LAST 'LINE1:boilerrm#${col01}:boiler room' 'LINE1:cellar#${col02}:cellar' 'LINE1:office#${col03}:office' 'LINE1:coal#${col04}:coal cellar' `;

  $output = `rrdtool graph $graphdirectory/watermeter${time}.png -a PNG -y 0.1:1 --vertical-label "litres" -s -${time} -w 1024 -h 300 'DEF:tenlitrespersec='$rrddirectory/watermeter.rrd:tenlitres:LAST 'CDEF:litrespertenmin=tenlitrespersec,60,*' 'LINE1:litrespertenmin#${col01}:water usage'  `;

  $output = `rrdtool graph $graphdirectory/hwtank${time}.png -a PNG --vertical-label "deg c" -s -${time} -w 1024 -h 300 'DEF:t0='$rrddirectory/hwtank0.rrd:temp:LAST 'DEF:t1='$rrddirectory/hwtank1.rrd:temp:LAST 'DEF:t2='$rrddirectory/hwtank2.rrd:temp:LAST 'DEF:t3='$rrddirectory/hwtank3.rrd:temp:LAST 'DEF:t4='$rrddirectory/hwtank4.rrd:temp:LAST 'DEF:t5='$rrddirectory/hwtank5.rrd:temp:LAST 'DEF:fl='$rrddirectory/hwfeed0.rrd:temp:LAST 'DEF:rn='$rrddirectory/hwsec0.rrd:temp:LAST 'DEF:eb='$rrddirectory/cylindertemp.rrd:temp:LAST 'LINE1:t0#${col01}:position 0 - top' 'LINE1:t1#${col02}:position 1' 'LINE1:t2#${col03}:position 2' 'LINE1:t3#${col04}:position 3' 'LINE1:t4#${col05}:position 4' 'LINE1:t5#${col06}:position 5 - bottom' 'LINE1:eb#${col07}:ebus cylinder probe'  'LINE1:fl#${col08}:hw feed' 'LINE1:rn#${col09}:hw rtn' `;

  $output = `rrdtool graph $graphdirectory/gasmeter${time}.png -a PNG --vertical-label "kwh per hour" -s -${time} -w 1024 -h 300 'DEF:dm3persec='$rrddirectory/gasmeter.rrd:dmcubed:LAST 'CDEF:kwhperhour=dm3persec,3960,*' 'LINE1:kwhperhour#${col01}:gas kwh per hour' `;

  $output = `rrdtool graph $graphdirectory/igntime${time}.png -a PNG --vertical-label "seconds" -s -${time} -w 1024 -h 300 'DEF:avg='$rrddirectory/igntimeavg.rrd:secs:LAST 'DEF:min='$rrddirectory/igntimemin.rrd:secs:LAST 'DEF:max='$rrddirectory/igntimemax.rrd:secs:LAST 'LINE1:avg#${col01}:average ignition time' 'LINE1:min#${col02}:minimum ignition time' 'LINE1:max#${col03}:maximum ignition time' `;


}

close LOCKFILE;
unlink $lockfile;
