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
$datestamp = `date +%F\\ %R\\ %z`;                                                   

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
$col10="2222FF"; # darkish blue 
$col11="FF3300"; # brightish orange
$col12="000000"; # black

$linetype="LINE2";
# do thin lines if we're graphing months or years
if (($time =~ /mo/ ) || ($time =~ /y/ ))
{
  $linetype="LINE1";
}

if ( -f $lockfile ) 
{
  die "Lockfile exists in $lockfile; exiting";
}

open LOCKFILE, ">", $lockfile or die $!;


$output = `rrdtool graph $graphdirectory/temps${time}.png -a PNG -l 0 -y 5:1 --vertical-label "deg c" -s -${time} -w 1024 -h 300 'DEF:inside='$rrddirectory/roomtemp.rrd:temp:LAST 'DEF:outside='$rrddirectory/os1temp.rrd:temp:LAST 'DEF:kitchen='$rrddirectory/kitchentemp.rrd:temp:LAST 'DEF:boilerrm='$rrddirectory/boilerrmtemp.rrd:temp:LAST 'DEF:cellar='$rrddirectory/cellartemp.rrd:temp:LAST 'DEF:office='$rrddirectory/officetemp.rrd:temp:LAST 'DEF:officeunderfloor='$rrddirectory/officeunderfloor.rrd:temp:LAST  'DEF:coal='$rrddirectory/coaltemp.rrd:temp:LAST 'DEF:cav='$rrddirectory/cavity1temp.rrd:temp:LAST 'DEF:porch='$rrddirectory/porch1temp.rrd:temp:LAST 'DEF:landing='$rrddirectory/landingtemp.rrd:temp:LAST '${linetype}:inside#${col01}:kitchen temp - thermostat' '${linetype}:outside#${col02}:outside temp' '${linetype}:kitchen#${col03}:kitchen temp - swe3' '${linetype}:boilerrm#${col04}:boiler room temp' '${linetype}:cellar#${col05}:cellar temp' '${linetype}:office#${col06}:office temp' '${linetype}:officeunderfloor#${col07}:office underfloor temp' '${linetype}:coal#${col08}:coal cellar temp' '${linetype}:cav#${col09}:wall cavity temp' '${linetype}:porch#${col10}:porch temp' '${linetype}:landing#${col11}:landing temp' -W "${datestamp}" -t "household temperatures" `;

$output = `rrdtool graph $graphdirectory/humidity${time}.png -a PNG -l 0 -y 5:1 --vertical-label "percent rh" -s -${time} -w 1024 -h 300 'DEF:boilerrm='$rrddirectory/boilerrmhum.rrd:hum:LAST 'DEF:cellar='$rrddirectory/cellarhum.rrd:hum:LAST 'DEF:office='$rrddirectory/officehum.rrd:hum:LAST 'DEF:coal='$rrddirectory/coalhum.rrd:hum:LAST 'DEF:outside='$rrddirectory/os1hum.rrd:hum:LAST 'DEF:kitchen='$rrddirectory/kitchenhum.rrd:hum:LAST 'DEF:landing='$rrddirectory/landinghum.rrd:hum:LAST   '${linetype}:cellar#${col01}:cellar' '${linetype}:boilerrm#${col02}:boiler room' '${linetype}:office#${col03}:office' '${linetype}:coal#${col04}:coal cellar' '${linetype}:outside#${col05}:outside' '${linetype}:kitchen#${col06}:kitchen' '${linetype}:landing#${col07}:landing'  -W "${datestamp}" -t "humidity"`;

# RPN IF to make modulation be zero if the fire is out, as explained in comment below, for the gasmeter graph
# this one has upper limit specified as 80 - no temperature should exceed this, but the modulation percentage does (which is ok). we also specify -r to disable auto-scaling.
$output = `rrdtool graph $graphdirectory/chtemps${time}.png -a PNG -u 80 -l 0 -r -y 10:1 --vertical-label "deg c" -s -${time} -w 1024 -h 300 'DEF:ebflow='$rrddirectory/ebflowtemp.rrd:temp:LAST 'DEF:ebreturn='$rrddirectory/ebreturntemp.rrd:temp:LAST 'DEF:desflow='$rrddirectory/desiredflowtemp.rrd:temp:LAST 'DEF:modtd='$rrddirectory/modtempdesired.rrd:temp:LAST 'DEF:ion='$rrddirectory/ionisationvolts.rrd:volts:LAST  'CDEF:modtdif=ion,65,GT,0,modtd,IF' 'DEF:zvu='$rrddirectory/zvupstairsflow.rrd:temp:LAST 'DEF:zvd='$rrddirectory/zvdownstairsflow.rrd:temp:LAST 'DEF:zvh='$rrddirectory/zvhwflow.rrd:temp:LAST '${linetype}:ebflow#${col01}:flow temp - ebus' '${linetype}:ebreturn#${col02}:return temp - ebus' '${linetype}:desflow#${col03}:desired flow temp' '${linetype}:modtdif#${col04}:boiler output (percent of max)' '${linetype}:zvu#${col05}:flow temp to upstairs radiators' '${linetype}:zvd#${col06}:flow temp to downstairs radiators' '${linetype}:zvh#${col07}:flow temp to hw tank' -W "${datestamp}" -t "heating system temperatures"`;

$output = `rrdtool graph $graphdirectory/power${time}.png -a PNG -l 0 -y 50:5 --vertical-label "watts" -s -${time} -w 1024 -h 300 'DEF:optical='$rrddirectory/ccoptiwatts.rrd:power:LAST 'DEF:clamp='$rrddirectory/ccclampwatts.rrd:power:LAST '${linetype}:optical#${col01}:pulse-counter reading' '${linetype}:clamp#${col02}:clamp meter reading' -W "${datestamp}" -t "electricity consumption"`;

$output = `rrdtool graph $graphdirectory/waterpressure${time}.png -a PNG -y 0.1:1 --vertical-label "bar" -s -${time} -w 1024 -h 300 'DEF:pressure='$rrddirectory/waterpressure.rrd:pres:LAST '${linetype}:pressure#${col01}:water pressure' -W "${datestamp}" -t "water pressure in central heating system"`;

$output = `rrdtool graph $graphdirectory/ionisationvolts${time}.png -a PNG --vertical-label "volts/modulation percentage" -s -${time} -w 1024 -h 300 'DEF:ion='$rrddirectory/ionisationvolts.rrd:volts:LAST 'DEF:modtd='$rrddirectory/modtempdesired.rrd:temp:LAST '${linetype}:ion#${col01}:flame sensor ionisation volts' '${linetype}:modtd#${col02}:desired modulation' -W "${datestamp}" -t "boiler flame detection (ionisation sensor)" `;

$output = `rrdtool graph $graphdirectory/watermeter${time}.png -a PNG -y 0.1:1 --vertical-label "litres" -s -${time} -w 1024 -h 300 'DEF:tenlitrespersec='$rrddirectory/watermeter.rrd:tenlitres:LAST 'CDEF:litrespertenmin=tenlitrespersec,60,*' '${linetype}:litrespertenmin#${col01}:water usage' -W "${datestamp}" -t "water consumption"  `;

$output = `rrdtool graph $graphdirectory/hwtank${time}.png -a PNG --vertical-label "deg c" -s -${time} -w 1024 -h 300 'DEF:t0='$rrddirectory/hwtank0.rrd:temp:LAST 'DEF:t1='$rrddirectory/hwtank1.rrd:temp:LAST 'DEF:t2='$rrddirectory/hwtank2.rrd:temp:LAST 'DEF:t3='$rrddirectory/hwtank3.rrd:temp:LAST 'DEF:t4='$rrddirectory/hwtank4.rrd:temp:LAST 'DEF:t5='$rrddirectory/hwtank5.rrd:temp:LAST 'DEF:fl='$rrddirectory/hwfeed0.rrd:temp:LAST 'DEF:rn='$rrddirectory/hwsec0.rrd:temp:LAST 'DEF:eb='$rrddirectory/cylindertemp.rrd:temp:LAST 'DEF:cwsh='$rrddirectory/cwsh.rrd:temp:LAST 'DEF:cwsc='$rrddirectory/cwsc.rrd:temp:LAST '${linetype}:t0#${col01}:position 0 - top' '${linetype}:t1#${col02}:position 1' '${linetype}:t2#${col03}:position 2' '${linetype}:t3#${col04}:position 3' '${linetype}:t4#${col05}:position 4' '${linetype}:t5#${col06}:position 5 - bottom' '${linetype}:eb#${col07}:ebus cylinder probe'  '${linetype}:fl#${col08}:hw feed' '${linetype}:rn#${col09}:hw rtn' '${linetype}:cwsh#${col10}:cold feed - sh' '${linetype}:cwsc#${col11}:cold feed - sc' -W "${datestamp}" -t "hot water tank temperatures"`;

$output = `rrdtool graph $graphdirectory/hotwater${time}.png -a PNG --vertical-label "deg c" -s -${time} -w 1024 -h 300 'DEF:fl='$rrddirectory/hwfeed0.rrd:temp:LAST 'DEF:rn0='$rrddirectory/hwsec0.rrd:temp:LAST 'DEF:eb='$rrddirectory/cylindertemp.rrd:temp:LAST 'DEF:rnbath='$rrddirectory/hwsec1.rrd:temp:LAST 'DEF:rnkit='$rrddirectory/hwsec2.rrd:temp:LAST 'DEF:floffice='$rrddirectory/hwfeed3.rrd:temp:LAST 'DEF:rnoffice='$rrddirectory/hwsec3.rrd:temp:LAST '${linetype}:eb#${col01}:ebus cylinder probe'  '${linetype}:fl#${col02}:hw feed' '${linetype}:rn0#${col03}:combined hw return'  '${linetype}:rnbath#${col04}:hw rtn from upstairs' '${linetype}:rnkit#${col05}:hw rtn from kitchen' '${linetype}:floffice#${col06}:hw feed at office' '${linetype}:rnoffice#${col07}:hw rtn at office' -W "${datestamp}" -t "hot water system temperatures" `;

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

# the calculation stuff uses rrd rpn syntax to bring the modulation line
# down to zero if the flame ionisation sensor indicates the fire is out
# otherwise it stays up at the last known value until the fire is re-lit
# https://oss.oetiker.ch/rrdtool/tut/rpntutorial.en.html
# the logic is "if ionisation > 65 then zero else modtdpc"

$output = `rrdtool graph $graphdirectory/gasmeter${time}.png -a PNG --vertical-label "kwh per hour" -s -${time} -w 1024 -h 300 'DEF:dm3persec='$rrddirectory/gasmeter.rrd:dmcubed:LAST 'CDEF:kw=dm3persec,409,*' 'DEF:ion='$rrddirectory/ionisationvolts.rrd:volts:LAST 'DEF:modtd='$rrddirectory/modtempdesired.rrd:temp:LAST 'CDEF:modtdpc=modtd,0.22385,*' 'CDEF:modtdpcif=ion,65,GT,0,modtdpc,IF' '${linetype}:kw#${col01}:gas kwh per hour from meter' '${linetype}:modtdpcif#${col02}:boiler ebus modulation percentage scaled to kW' -W "${datestamp}" -t "gas consumption" `;

$output = `rrdtool graph $graphdirectory/igntime${time}.png -a PNG --vertical-label "seconds" -s -${time} -w 1024 -h 300 'DEF:avg='$rrddirectory/igntimeavg.rrd:secs:LAST 'DEF:min='$rrddirectory/igntimemin.rrd:secs:LAST 'DEF:max='$rrddirectory/igntimemax.rrd:secs:LAST '${linetype}:avg#${col01}:average ignition time' '${linetype}:min#${col02}:minimum ignition time' '${linetype}:max#${col03}:maximum ignition time' -W "${datestamp}" -t "boiler igntion times"`;

# downstairs bath, sensors are numbered bottom-to-top
$output = `rrdtool graph $graphdirectory/dsbath${time}.png -a PNG --vertical-label "deg c" -s -${time} -w 1024 -h 300 'DEF:s1='$rrddirectory/dbath1.rrd:temp:LAST 'DEF:s2='$rrddirectory/dbath2.rrd:temp:LAST 'DEF:s3='$rrddirectory/dbath3.rrd:temp:LAST 'DEF:s4='$rrddirectory/dbath4.rrd:temp:LAST 'DEF:s5='$rrddirectory/dbath5.rrd:temp:LAST 'DEF:hwbefore='$rrddirectory/dbathfeed1.rrd:temp:LAST 'DEF:hwafter='$rrddirectory/dbathfeed2.rrd:temp:LAST '${linetype}:s1#${col01}:bottom of bath' '${linetype}:s2#${col02}:first point up bath' '${linetype}:s3#${col03}:second point up bath' '${linetype}:s4#${col04}:third point up bath' '${linetype}:s5#${col05}:top of bath' '${linetype}:hwbefore#${col06}:hot water supply to blending valve' '${linetype}:hwafter#${col07}:hot water supply from blending valve'  -W "${datestamp}" -t "downstairs bath temperatures"`;

# barometer
$output = `rrdtool graph $graphdirectory/barometer${time}.png -a PNG --vertical-label "millibars" -s -${time} -w 1024 -h 300 'DEF:pres='$rrddirectory/barompressure.rrd:pres:LAST '${linetype}:pres#${col01}:barometric pressure' -W "${datestamp}" -t "barometer"`;

# 20151118 taaralabs thermocouple - stove
$output = `rrdtool graph $graphdirectory/stove${time}.png -a PNG --vertical-label "deg c" -s -${time} -w 1024 -h 300 'DEF:sto1='$rrddirectory/stovetemp1.rrd:temp:LAST '${linetype}:sto1#${col01}:stove temperature' -W "${datestamp}" -t "stove"`;

# unknown boiler shit

#$output = `rrdtool graph $graphdirectory/boilershit${time}.png -a PNG --vertical-label "counts" -s -${time} -w 1024 -h 300 'DEF:prhc1='$rrddirectory/prenergycounthc1.rrd:count:LAST '${linetype}:prhc1#${col01}:prenergycounthc1' 'DEF:prhwc1='$rrddirectory/prenergycounthwc1.rrd:count:LAST '${linetype}:prhwc1#${col02}:prenergycounthwc1' 'DEF:prshc1='$rrddirectory/prenergysumhc1.rrd:count:LAST '${linetype}:prshc1#${col03}:prenergysumhc1' 'DEF:prshwc1='$rrddirectory/prenergysumhwc1.rrd:count:LAST '${linetype}:prshwc1#${col04}:prenergysumhwc1'  -W "${datestamp}" -t "stuff on test"`;
$output = `rrdtool graph $graphdirectory/boilershit${time}.png -a PNG --vertical-label "counts" -s -${time} -w 1024 -h 300 'DEF:prhc1='$rrddirectory/prenergycounthc1.rrd:count:LAST '${linetype}:prhc1#${col01}:prenergycounthc1' 'DEF:prhwc1='$rrddirectory/prenergycounthwc1.rrd:count:LAST -W "${datestamp}" -t "stuff on test"`;


# bus stuff
# number of devices on each
$output = `rrdtool graph $graphdirectory/1wdevicecount${time}.png -a PNG -l 0 --vertical-label "devices" -s -${time} -w 1024 -h 300 'DEF:b0='$rrddirectory/1wdevicecount0.rrd:curve:LAST 'DEF:b1='$rrddirectory/1wdevicecount1.rrd:curve:LAST 'DEF:b2='$rrddirectory/1wdevicecount2.rrd:curve:LAST  'DEF:owtime='$rrddirectory/runtime1w.rrd:secs:LAST  'AREA:b0#${col01}:bus 0' 'AREA:b1#${col02}:bus 1':STACK 'AREA:b2#${col03}:bus 2':STACK  '${linetype}:owtime#${col03}:script runtime'  -W "${datestamp}" -t "1-wire devices connected / seconds"`; 

# volts (at humidity sensors)
$output = `rrdtool graph $graphdirectory/busvolts${time}.png -a PNG --vertical-label "volts" -s -${time} -w 1024 -h 300 'DEF:boilerrm='$rrddirectory/boilerrmvdd.rrd:vdd:LAST 'DEF:cellar='$rrddirectory/cellarvdd.rrd:vdd:LAST 'DEF:office='$rrddirectory/officevdd.rrd:vdd:LAST 'DEF:coal='$rrddirectory/coalvdd.rrd:vdd:LAST 'DEF:kitchen='$rrddirectory/kitchenvdd.rrd:vdd:LAST 'DEF:landing='$rrddirectory/landingvdd.rrd:vdd:LAST  '${linetype}:boilerrm#${col01}:boiler room' '${linetype}:cellar#${col02}:cellar' '${linetype}:office#${col03}:office' '${linetype}:coal#${col04}:coal cellar' '${linetype}:kitchen#${col05}:kitchen' '${linetype}:landing#${col06}:landing'  -W "${datestamp}" -t "1-wire bus voltages"`;

# errors
foreach $bus (0..2)
{
  $output = `rrdtool graph $graphdirectory/bus${bus}errors${time}.png -a PNG --vertical-label "count" -s -${time} -w 1024 -h 300 'DEF:close='$rrddirectory/bus${bus}close_errors.rrd:count:LAST 'DEF:detect='$rrddirectory/bus${bus}detect_errors.rrd:count:LAST 'DEF:errors='$rrddirectory/bus${bus}errors.rrd:count:LAST 'DEF:locks='$rrddirectory/bus${bus}locks.rrd:count:LAST 'DEF:open='$rrddirectory/bus${bus}open_errors.rrd:count:LAST 'DEF:program='$rrddirectory/bus${bus}program_errors.rrd:count:LAST 'DEF:pullup='$rrddirectory/bus${bus}pullup_errors.rrd:count:LAST 'DEF:read='$rrddirectory/bus${bus}read_errors.rrd:count:LAST 'DEF:reconnect='$rrddirectory/bus${bus}reconnect_errors.rrd:count:LAST 'DEF:reconnects='$rrddirectory/bus${bus}reconnects.rrd:count:LAST 'DEF:reset='$rrddirectory/bus${bus}reset_errors.rrd:count:LAST 'DEF:resets='$rrddirectory/bus${bus}resets.rrd:count:LAST 'DEF:select='$rrddirectory/bus${bus}select_errors.rrd:count:LAST 'DEF:shorts='$rrddirectory/bus${bus}shorts.rrd:count:LAST 'DEF:status='$rrddirectory/bus${bus}status_errors.rrd:count:LAST 'DEF:timeouts='$rrddirectory/bus${bus}timeouts.rrd:count:LAST 'DEF:unlocks='$rrddirectory/bus${bus}unlocks.rrd:count:LAST '${linetype}:close#${col01}:close errors' '${linetype}:detect#${col02}:detect errors' '${linetype}:errors#${col03}:errors' '${linetype}:locks#${col04}:locks' '${linetype}:open#${col05}:open errors' '${linetype}:program#${col06}:program errors' '${linetype}:pullup#${col07}:pullup errors' '${linetype}:read#${col08}:read errors' '${linetype}:reconnect#${col09}:reconnect errors' '${linetype}:reconnects#${col10}:reconnects' '${linetype}:reset#${col11}:reset errors' '${linetype}:resets#${col12}:resets' '${linetype}:select#${col01}:select errors:dashes' '${linetype}:shorts#${col02}:shorts:dashes' '${linetype}:status#${col03}:status errors:dashes' '${linetype}:timeouts#${col04}:timeouts:dashes' '${linetype}:unlocks#${col05}:unlocks:dashes'  -W "${datestamp}" -t "1-wire bus ${bus} incidents"`;
}


close LOCKFILE;
unlink $lockfile;

