#! /usr/bin/perl -w
#
# graph-car.pl - draw car graphs
#
# GH 2017-02-01 
# split off from graph.pl
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
#$logdirectory="/data/hm/log";
$graphdirectory="/root/Dropbox/Public/styes-graphs";
#$logfile="graph.log";
$lockfile="/tmp/graph-car.lock";
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

# 20170307 nissan leaf stuff
#
# this car stuff needs splitting to a separate file where the longer-term graphs are 
#  drawn from max/min/avg not last
#
#TODO: capacity bars
# -u 100: upper y-axis limit 100; -l 0: lower y-axis limit 0
#
# we plot the percentage calculated from the number of bars 
# left (out of 12) which ought to match the percentage
#
# this is the old one which just used the api data
#$output = `rrdtool graph $graphdirectory/leafbatt${time}.png -a PNG -u 100 -l 0 -r -y 10:1 --vertical-label "percent" -s -${time} -w 1024 -h 300 'DEF:pc='$rrddirectory/leafbattpc.rrd:pc:LAST 'DEF:bars='$rrddirectory/leafbattbars.rrd:bars:LAST 'CDEF:barspc=bars,0.12,/' '${linetype}:pc#${col01}:traction battery percent charged' '${linetype}:barspc#${col02}:traction battery bars remaining' -W "${datestamp}" -t "nissan leaf battery"`;

$output = `rrdtool graph $graphdirectory/leafruntime${time}.png -a PNG  --vertical-label "seconds" -s -${time} -w 1024 -h 300 'DEF:secs='$rrddirectory/runtimeleaf.rrd:secs:LAST  '${linetype}:secs#${col01}:leaf monitoring script run time'  -W "${datestamp}" -t "time taken to retrieve data from car"`;

# this doesn't work
## battery capacity - 3 measures - don't expect it to change more than once or twice a year
#$output = `rrdtool graph $graphdirectory/leafbattcap${time}.png -a PNG -u 100 -l 0 -r -y 10:1 --vertical-label "percent" -s -${time} -w 1024 -h 300 'DEF:cap1='$rrddirectory/leafbattcap1.rrd:bars:LAST 'DEF:cap2='$rrddirectory/leafbattcap2.rrd:bars:LAST 'DEF:cap3='$rrddirectory/leafbattcap3.rrd:bars:LAST  'CDEF:cap1pc=cap1,0.12,/' 'CDEF:cap2pc=cap1,0.12,/' 'CDEF:cap3pc=cap1,0.12,/' '${linetype}:cap1pc#${col01}:traction battery capacity 1' '${linetype}:cap2pc#${col02}:traction battery capacity 2' '${linetype}:cap3pc#${col03}:traction battery capacity 3' -W "${datestamp}" -t "nissan leaf battery capacity"`;

# 20170129 leafspy stuff
# batteries - car from api and leafspy, car phone/logger
$output = `rrdtool graph $graphdirectory/leafbatt${time}.png -a PNG -u 100 -l 0 -r -y 10:1 --vertical-label "percent" -s -${time} -w 1024 -h 300 'DEF:api='$rrddirectory/leafbattpc.rrd:pc:LAST 'DEF:ls='$rrddirectory/ls-soc.rrd:soc:LAST 'DEF:ph='$rrddirectory/ls-phonebatt.rrd:phonebatt:LAST '${linetype}:api#${col01}:traction battery percent charged - from api' '${linetype}:ls#${col02}:traction battery percent charge from leafspy' '${linetype}:ph#${col03}:monitoring system battery percent charge' -W "${datestamp}" -t "nissan leaf battery"`;

# speed, traction and regen power
# regen and motor are both stored in watts but graphed in kW
$output = `rrdtool graph $graphdirectory/leafspeedpower${time}.png -a PNG --vertical-label "kilowatts/mph" -s -${time} -w 1024 -h 300 'DEF:sp='$rrddirectory/ls-speed.rrd:speed:LAST 'DEF:mpw='$rrddirectory/ls-drivemotor.rrd:drivemotor:LAST 'DEF:rew='$rrddirectory/ls-regenwh.rrd:regenwh:LAST 'CDEF:re=rew,1000,/' 'CDEF:mp=mpw,1000,/' '${linetype}:sp#${col01}:vehicle speed mph' '${linetype}:mp#${col02}:motor power kW' '${linetype}:re#${col03}:regen power kW' -W "${datestamp}" -t "nissan leaf - speed and power"`;

# temperatures - pack and ambient
$output = `rrdtool graph $graphdirectory/leaftemps${time}.png -a PNG --vertical-label "deg c" -s -${time} -w 1024 -h 300 'DEF:p1='$rrddirectory/ls-packtemp1.rrd:packtemp1:LAST 'DEF:p2='$rrddirectory/ls-packtemp2.rrd:packtemp2:LAST 'DEF:p4='$rrddirectory/ls-packtemp4.rrd:packtemp4:LAST 'DEF:amb='$rrddirectory/ls-ambienttemp.rrd:ambienttemp:LAST '${linetype}:p1#${col01}:battery sensor 1' '${linetype}:p2#${col02}:battery sensor 2' '${linetype}:p4#${col03}:battery sensor 4' '${linetype}:amb#${col04}:ambient sensor' -W "${datestamp}" -t "nissan leaf temperatures"`; 

# power - auxiliaries
$output = `rrdtool graph $graphdirectory/leafpoweraux${time}.png -a PNG --vertical-label "watts" -s -${time} -w 1024 -h 300 'DEF:ac='$rrddirectory/ls-acpower.rrd:acpower:LAST 'DEF:hp='$rrddirectory/ls-acpower2.rrd:acpower2:LAST 'DEF:rh='$rrddirectory/ls-heatpower.rrd:heatpower:LAST 'DEF:ap='$rrddirectory/ls-auxpower.rrd:auxpower:LAST '${linetype}:ac#${col01}:aircon power' '${linetype}:hp#${col02}:heat-pump power' '${linetype}:rh#${col03}:resistive heater power' '${linetype}:ap#${col04}:other auxiliaries power' -W "${datestamp}" -t "nissan leaf auxiliaries power"`;

# pack voltages
$output = `rrdtool graph $graphdirectory/leafpackvolts${time}.png -a PNG --vertical-label "volts" -s -${time} -w 1024 -h 300 'DEF:p1='$rrddirectory/ls-packvolts.rrd:packvolts:LAST 'DEF:p2='$rrddirectory/ls-packvolts2.rrd:packvolts2:LAST 'DEF:p3='$rrddirectory/ls-packvolts3.rrd:packvolts3:LAST '${linetype}:p1#${col01}:pack volts sensor 1' '${linetype}:p2#${col02}:pack volts sensor 2' '${linetype}:p3#${col03}:pack volts sensor 3' -W "${datestamp}" -t "nissan leaf traction battery voltage"`;

# 12v battery voltage
$output = `rrdtool graph $graphdirectory/leafauxbatt${time}.png -a PNG --vertical-label "volts" -s -${time} -w 1024 -h 300 'DEF:p1='$rrddirectory/ls-voltsla.rrd:voltsla:LAST '${linetype}:p1#${col01}:12v battery voltage' -W "${datestamp}" -t "nissan leaf auxiliary/12v battery voltage"`;

close LOCKFILE;
unlink $lockfile;

