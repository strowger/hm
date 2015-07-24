#! /usr/bin/perl -w
#
# graph.pl - draw graphs
#
# GH 2015-06-19
# begun
#

# suggested cron entries:
# */10 * * * * /data/hm/bin/graph.pl 3h > /data/hm/log/graph-run.log 2> /data/hm/log/graph-err.log && /data/hm/bin/upload-gh.sh > /data/hm/log/upload-run.log 2> /data/hm/log/upload-err.log
#
# 13 * * * * /data/hm/bin/graph.pl 36h > /data/hm/log/graph-run.log 2> /data/hm/log/graph-err.log
#
# 23 05 * * * /data/hm/bin/graph.pl 10d > /data/hm/log/graph-run.log 2> /data/hm/log/graph-err.log
#
# 33 05 * * * /data/hm/bin/graph.pl 3mon > /data/hm/log/graph-run.log 2> /data/hm/log/graph-err.log

if (length $ARGV[0])
{
  $time = $ARGV[0]
}
else
{
  die "No period specified\n"
}

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


if ( -f $lockfile ) 
{
  die "Lockfile exists in $lockfile; exiting";
}

open LOCKFILE, ">", $lockfile or die $!;


$output = `rrdtool graph $graphdirectory/temps${time}.png -a PNG -l 0 -y 5:1 --vertical-label "deg c" -s -${time} -w 1024 -h 300 'DEF:inside='$rrddirectory/roomtemp.rrd:temp:LAST 'DEF:outside='$rrddirectory/outdoortemp.rrd:temp:LAST 'DEF:boilerrmcc='$rrddirectory/cctemp.rrd:temp:LAST 'DEF:boilerrm='$rrddirectory/boilerrmtemp.rrd:temp:LAST 'DEF:cellar='$rrddirectory/cellartemp.rrd:temp:LAST 'DEF:office='$rrddirectory/officetemp.rrd:temp:LAST 'DEF:officeunderfloor='$rrddirectory/officeunderfloor.rrd:temp:LAST  'DEF:coal='$rrddirectory/coaltemp.rrd:temp:LAST 'LINE2:inside#${col01}:kitchen temp' 'LINE2:outside#${col02}:outside temp' 'LINE2:boilerrmcc#${col03}:boiler room temp - cc' 'LINE2:boilerrm#${col04}:boiler room temp - swe3' 'LINE2:cellar#${col05}:cellar temp' 'LINE2:office#${col06}:office temp' 'LINE2:officeunderfloor#${col07}:office underfloor temp' 'LINE2:coal#${col08}:coal cellar temp' `;

$output = `rrdtool graph $graphdirectory/humidity${time}.png -a PNG -l 0 -y 5:1 --vertical-label "percent rh" -s -${time} -w 1024 -h 300 'DEF:boilerrm='$rrddirectory/boilerrmhum.rrd:hum:LAST 'DEF:cellar='$rrddirectory/cellarhum.rrd:hum:LAST 'DEF:office='$rrddirectory/officehum.rrd:hum:LAST 'DEF:coal='$rrddirectory/coalhum.rrd:hum:LAST 'LINE2:cellar#${col01}:cellar' 'LINE2:boilerrm#${col02}:boiler room' 'LINE2:office#${col03}:office' 'LINE2:coal#${col04}:coal cellar' `;

$output = `rrdtool graph $graphdirectory/chtemps${time}.png -a PNG -l 0 -y 10:1 --vertical-label "deg c" -s -${time} -w 1024 -h 300 'DEF:cyl='$rrddirectory/cylindertemp.rrd:temp:LAST 'DEF:ebflow='$rrddirectory/ebflowtemp.rrd:temp:LAST 'DEF:ebreturn='$rrddirectory/ebreturntemp.rrd:temp:LAST 'DEF:desflow='$rrddirectory/desiredflowtemp.rrd:temp:LAST 'DEF:modtd='$rrddirectory/modtempdesired.rrd:temp:LAST 'DEF:bflow='$rrddirectory/boilerflow.rrd:temp:LAST 'DEF:brtn='$rrddirectory/boilerreturn.rrd:temp:LAST 'DEF:zvu='$rrddirectory/zvupstairsflow.rrd:temp:LAST 'DEF:zvd='$rrddirectory/zvdownstairsflow.rrd:temp:LAST 'DEF:zvh='$rrddirectory/zvhwflow.rrd:temp:LAST  'LINE2:cyl#${col01}:cylinder temp - ebus' 'LINE2:ebflow#${col02}:flow temp - ebus' 'LINE2:ebreturn#${col03}:return temp - ebus' 'LINE2:desflow#${col04}:desired flow temp' 'LINE2:modtd#${col05}:desired modulation' 'LINE2:bflow#${col06}:flow temp - 1wire' 'LINE2:brtn#${col07}:return temp - 1wire' 'LINE2:zvu#${col08}:flow temp to upstairs radiators' 'LINE2:zvd#${col09}:flow temp to downstairs radiators' 'LINE2:zvh#${col10}:flow temp to hw tank'`;

$output = `rrdtool graph $graphdirectory/power${time}.png -a PNG -l 0 -y 50:5 --vertical-label "watts" -s -${time} -w 1024 -h 300 'DEF:optical='$rrddirectory/ccoptiwatts.rrd:power:LAST 'DEF:clamp='$rrddirectory/ccclampwatts.rrd:power:LAST 'LINE2:optical#${col01}:pulse-counter reading' 'LINE2:clamp#${col02}:clamp meter reading'`;

$output = `rrdtool graph $graphdirectory/waterpressure${time}.png -a PNG -y 0.1:1 --vertical-label "bar" -s -${time} -w 1024 -h 300 'DEF:pressure='$rrddirectory/waterpressure.rrd:pres:LAST 'LINE2:pressure#${col01}:water pressure'`;

$output = `rrdtool graph $graphdirectory/ionisationvolts${time}.png -a PNG --vertical-label "volts/modulation percentage" -s -${time} -w 1024 -h 300 'DEF:ion='$rrddirectory/ionisationvolts.rrd:volts:LAST 'DEF:modtd='$rrddirectory/modtempdesired.rrd:temp:LAST 'LINE2:ion#${col01}:flame sensor ionisation volts' 'LINE2:modtd#${col02}:desired modulation'  `;

$output = `rrdtool graph $graphdirectory/busvolts${time}.png -a PNG --vertical-label "volts" -s -${time} -w 1024 -h 300 'DEF:boilerrm='$rrddirectory/boilerrmvdd.rrd:vdd:LAST 'DEF:cellar='$rrddirectory/cellarvdd.rrd:vdd:LAST 'DEF:office='$rrddirectory/officevdd.rrd:vdd:LAST 'DEF:coal='$rrddirectory/coalvdd.rrd:vdd:LAST 'LINE2:boilerrm#${col01}:boiler room' 'LINE2:cellar#${col02}:cellar' 'LINE2:office#${col03}:office' 'LINE2:coal#${col04}:coal cellar' `;

$output = `rrdtool graph $graphdirectory/watermeter${time}.png -a PNG -y 0.1:1 --vertical-label "litres" -s -${time} -w 1024 -h 300 'DEF:tenlitrespersec='$rrddirectory/watermeter.rrd:tenlitres:LAST 'CDEF:litrespertenmin=tenlitrespersec,60,*' 'LINE2:litrespertenmin#${col01}:water usage'  `;

$output = `rrdtool graph $graphdirectory/hwtank${time}.png -a PNG --vertical-label "deg c" -s -${time} -w 1024 -h 300 'DEF:t0='$rrddirectory/hwtank0.rrd:temp:LAST 'DEF:t1='$rrddirectory/hwtank1.rrd:temp:LAST 'DEF:t2='$rrddirectory/hwtank2.rrd:temp:LAST 'DEF:t3='$rrddirectory/hwtank3.rrd:temp:LAST 'DEF:t4='$rrddirectory/hwtank4.rrd:temp:LAST 'DEF:t5='$rrddirectory/hwtank5.rrd:temp:LAST 'DEF:fl='$rrddirectory/hwfeed0.rrd:temp:LAST 'DEF:rn='$rrddirectory/hwsec0.rrd:temp:LAST 'DEF:eb='$rrddirectory/cylindertemp.rrd:temp:LAST 'DEF:cwsh='$rrddirectory/cwsh.rrd:temp:LAST 'DEF:cwsc='$rrddirectory/cwsc.rrd:temp:LAST 'LINE2:t0#${col01}:position 0 - top' 'LINE2:t1#${col02}:position 1' 'LINE2:t2#${col03}:position 2' 'LINE2:t3#${col04}:position 3' 'LINE2:t4#${col05}:position 4' 'LINE2:t5#${col06}:position 5 - bottom' 'LINE2:eb#${col07}:ebus cylinder probe'  'LINE2:fl#${col08}:hw feed' 'LINE2:rn#${col09}:hw rtn' 'LINE2:cwsh#${col10}:cold feed - sh' 'LINE2:cwsc#${col11}:cold feed - sc' `;

# this probably deserves a bit of explanation
# the boiler is an ecotec plus 618, nominally 18kW
# manual says the gas rate is 1.97m3/h +5%/-10%
# that's 22.385kW !!
# SEDBUK 89.3% = 19.98kW useful output
# modulation between 4.2 - 19.3kW with 50 flow/30 return
# modulation between 3.8 - 18.5kW with 80 flow/60 return
# guess we should work with the 22.385 figure - hence 'modtd' CDEF
#
# gas bill says kwh = m3 * 1.02264 * 40 (corr. factor, calorific value) / 3.6 
# 1 m3 = 11.363kWh/m3
# the gas meter gives a pulse per dm3, which is .001 m3
# the 409 in the kw CDEF is from 6*60*11.363

$output = `rrdtool graph $graphdirectory/gasmeter${time}.png -a PNG --vertical-label "kwh per hour" -s -${time} -w 1024 -h 300 'DEF:dm3persec='$rrddirectory/gasmeter.rrd:dmcubed:LAST 'CDEF:kw=dm3persec,409,*' 'DEF:modtd='$rrddirectory/modtempdesired.rrd:temp:LAST 'CDEF:modtdpc=modtd,0.22385,*' 'LINE2:kw#${col01}:gas kwh per hour from meter' 'LINE2:modtdpc#${col02}:boiler ebus modulation percentage scaled to kW' `;

$output = `rrdtool graph $graphdirectory/igntime${time}.png -a PNG --vertical-label "seconds" -s -${time} -w 1024 -h 300 'DEF:avg='$rrddirectory/igntimeavg.rrd:secs:LAST 'DEF:min='$rrddirectory/igntimemin.rrd:secs:LAST 'DEF:max='$rrddirectory/igntimemax.rrd:secs:LAST 'LINE2:avg#${col01}:average ignition time' 'LINE2:min#${col02}:minimum ignition time' 'LINE2:max#${col03}:maximum ignition time' `;


close LOCKFILE;
unlink $lockfile;

