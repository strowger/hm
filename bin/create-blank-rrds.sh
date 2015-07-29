#! /bin/bash -w
#
#
# GH 2015-06-18
# begun - re-use of old code from pexwood
#
# we don't every want to really run as a script i guess, we blow away
# all the data
#
exit 0

#options to create, in order left to right:
#start time when the s/w was first used
#step time in seconds (how often we record a value)
#DS - name, counter/gauge type, time without a value before entering "nothing" in rrd, min value, max value
#
#RRA - 0.5 - can't remember
#next - how many seconds between records
#how many records to keep

# we want 30 years of data
# once per minute = 1440 per day, 527040 per (366 day)year, 15811200 per 30 years

# daily, weekly, 4weekly average min/max 
# 1440 per day, 10980 days in 30 (366 day) years
# 10080 per week, 1569 weeks in 30 years
# 40320 per 28-day month, 393 "months" in 30 years


## 20150619 styes
## 20101009 original
# currentcost
# outputs a value in watts and a temperature (of the receiver) every 6 seconds
# we'll capture them all but only save one per minute 
# we have two different data sources - the clamp meter and the pulse counter
# the clamp meter is less accurate and gives a number of watts
# the pulse counter gives a number of pulses as well as a calculated number of watts
# daily, weekly, 4weekly average,min,max 

rrdtool create cctemp.rrd --start 1434700000 --step 60 \
DS:temp:GAUGE:120:-10:110 \
RRA:LAST:0.5:1:15811200 \
RRA:AVERAGE:0.1:1440:10980 \
RRA:AVERAGE:0.1:10080:1569 \
RRA:AVERAGE:0.1:40320:393 \
RRA:MIN:0.1:1440:10980 \
RRA:MIN:0.1:10080:1569 \
RRA:MIN:0.1:40320:393 \
RRA:MAX:0.1:1440:10980 \
RRA:MAX:0.1:10080:1569 \
RRA:MAX:0.1:40320:393

rrdtool create ccclampwatts.rrd --start 1434700000 --step 60 \
DS:power:GAUGE:120:0:10000 \
RRA:LAST:0.5:1:15811200 \
RRA:AVERAGE:0.1:1440:10980 \
RRA:AVERAGE:0.1:10080:1569 \
RRA:AVERAGE:0.1:40320:393 \
RRA:MIN:0.1:1440:10980 \
RRA:MIN:0.1:10080:1569 \
RRA:MIN:0.1:40320:393 \
RRA:MAX:0.1:1440:10980 \
RRA:MAX:0.1:10080:1569 \
RRA:MAX:0.1:40320:393

rrdtool create ccoptiwatts.rrd --start 1434700000 --step 60 \
DS:power:GAUGE:120:0:10000 \
RRA:LAST:0.5:1:15811200 \
RRA:AVERAGE:0.1:1440:10980 \
RRA:AVERAGE:0.1:10080:1569 \
RRA:AVERAGE:0.1:40320:393 \
RRA:MIN:0.1:1440:10980 \
RRA:MIN:0.1:10080:1569 \
RRA:MIN:0.1:40320:393 \
RRA:MAX:0.1:1440:10980 \
RRA:MAX:0.1:10080:1569 \
RRA:MAX:0.1:40320:393

rrdtool create ccopticount.rrd --start 1434700000 --step 60 \
DS:power:COUNTER:120:0:1000 \
RRA:LAST:0.5:1:15811200

# 20150619 
# ebusread
# filenames have to match ebusread.conf
# assuming a read every minute, which might be too often
# reading less often affects the AVERAGE/MIN/MAX step value
rrdtool create desiredtemp.rrd --start 1434700000 --step 60 \
DS:temp:GAUGE:120:-10:110 \
RRA:LAST:0.5:1:15811200

rrdtool create cylindertemp.rrd --start 1434700000 --step 60 \
DS:temp:GAUGE:120:-10:110 \
RRA:LAST:0.5:1:15811200

# daily, weekly, 4weekly average,min,max 
rrdtool create outdoortemp.rrd --start 1434700000 --step 60 \
DS:temp:GAUGE:120:-50:110 \
RRA:LAST:0.5:1:15811200 \
RRA:AVERAGE:0.1:1440:10980 \
RRA:AVERAGE:0.1:10080:1569 \
RRA:AVERAGE:0.1:40320:393 \
RRA:MIN:0.1:1440:10980 \
RRA:MIN:0.1:10080:1569 \
RRA:MIN:0.1:40320:393 \
RRA:MAX:0.1:1440:10980 \
RRA:MAX:0.1:10080:1569 \
RRA:MAX:0.1:40320:393 

# eb for ebus, we'll get a separate flow temp from 1wire
rrdtool create ebflowtemp.rrd --start 1434700000 --step 60 \
DS:temp:GAUGE:120:-50:110 \
RRA:LAST:0.5:1:15811200

rrdtool create desiredflowtemp.rrd --start 1434700000 --step 60 \
DS:temp:GAUGE:120:-50:110 \
RRA:LAST:0.5:1:15811200

# daily, weekly average,min,max
rrdtool create waterpressure.rrd --start 1434700000 --step 60 \
DS:pres:GAUGE:120:-50:110 \
RRA:LAST:0.5:1:15811200 \
RRA:AVERAGE:0.1:1440:10980 \
RRA:AVERAGE:0.1:10080:1569 \
RRA:MIN:0.1:1440:10980 \
RRA:MIN:0.1:10080:1569 \
RRA:MAX:0.1:1440:10980 \
RRA:MAX:0.1:10080:1569 

rrdtool create ionisationvolts.rrd --start 1434700000 --step 60 \
DS:volts:GAUGE:120:-2000:200 \
RRA:LAST:0.5:1:15811200

# nfi what max to use
rrdtool create prenergycounthc1.rrd --start 1434700000 --step 60 \
DS:count:COUNTER:120:0:4294967295 \
RRA:LAST:0.5:1:15811200

rrdtool create prenergycounthwc1.rrd --start 1434700000 --step 60 \
DS:count:COUNTER:120:0:4294967295 \
RRA:LAST:0.5:1:15811200

rrdtool create prenergysumhc1.rrd --start 1434700000 --step 60 \
DS:count:COUNTER:120:0:4294967295 \
RRA:LAST:0.5:1:15811200

rrdtool create prenergysumhwc1.rrd --start 1434700000 --step 60 \
DS:count:COUNTER:120:0:4294967295 \
RRA:LAST:0.5:1:15811200

rrdtool create modtempdesired.rrd --start 1434700000 --step 60 \
DS:temp:GAUGE:120:-50:200 \
RRA:LAST:0.5:1:15811200

# daily, weekly, 4weekly average,min,max
rrdtool create roomtemp.rrd --start 1434700000 --step 60 \
DS:temp:GAUGE:120:-50:110 \
RRA:LAST:0.5:1:15811200 \
RRA:AVERAGE:0.1:1440:10980 \
RRA:AVERAGE:0.1:10080:1569 \
RRA:AVERAGE:0.1:40320:393 \
RRA:MIN:0.1:1440:10980 \
RRA:MIN:0.1:10080:1569 \
RRA:MIN:0.1:40320:393 \
RRA:MAX:0.1:1440:10980 \
RRA:MAX:0.1:10080:1569 \
RRA:MAX:0.1:40320:393

# 20150722 think we might have found ebus return temp hiding under a silly name

rrdtool create ebreturntemp.rrd --start 1437500000 --step 60 \
DS:temp:GAUGE:120:-50:110 \
RRA:LAST:0.5:1:15811200

# 20150722 hourly measurement will still probably be far too often
# heartbeat 2 hours, don't know what min/max values are sensible 

rrdtool create igntimeavg.rrd --start 1437500000 --step 3600 \
DS:secs:GAUGE:7200:U:U \
RRA:LAST:0.5:1:90000

rrdtool create igntimemin.rrd --start 1437500000 --step 3600 \
DS:secs:GAUGE:7200:U:U \
RRA:LAST:0.5:1:90000

rrdtool create igntimemax.rrd --start 1437500000 --step 3600 \
DS:secs:GAUGE:7200:U:U \
RRA:LAST:0.5:1:90000


## 20150624
## one-wire devices

# sheepwalk humidity sensor, boiler room

rrdtool create boilerrmtemp.rrd --start 1435100000 --step 60 \
DS:temp:GAUGE:120:-50:110 \
RRA:LAST:0.5:1:15811200 \
RRA:AVERAGE:0.1:1440:10980 \
RRA:AVERAGE:0.1:10080:1569 \
RRA:AVERAGE:0.1:40320:393 \
RRA:MIN:0.1:1440:10980 \
RRA:MIN:0.1:10080:1569 \
RRA:MIN:0.1:40320:393 \
RRA:MAX:0.1:1440:10980 \
RRA:MAX:0.1:10080:1569 \
RRA:MAX:0.1:40320:393

rrdtool create boilerrmhum.rrd --start 1435100000 --step 60 \
DS:hum:GAUGE:120:0:100 \
RRA:LAST:0.5:1:15811200 \
RRA:AVERAGE:0.1:1440:10980 \
RRA:AVERAGE:0.1:10080:1569 \
RRA:AVERAGE:0.1:40320:393 \
RRA:MIN:0.1:1440:10980 \
RRA:MIN:0.1:10080:1569 \
RRA:MIN:0.1:40320:393 \
RRA:MAX:0.1:1440:10980 \
RRA:MAX:0.1:10080:1569 \
RRA:MAX:0.1:40320:393

# every 10 minutes is plenty often enough for this
rrdtool create boilerrmvdd.rrd --start 1435100000 --step 600 \
DS:vdd:GAUGE:120:0:10 \
RRA:LAST:0.5:1:1581120 \
RRA:AVERAGE:0.1:144:10980 \
RRA:AVERAGE:0.1:1008:1569 \
RRA:AVERAGE:0.1:4032:393 \
RRA:MIN:0.1:144:10980 \
RRA:MIN:0.1:1008:1569 \
RRA:MIN:0.1:4032:393 \
RRA:MAX:0.1:144:10980 \
RRA:MAX:0.1:1008:1569 \
RRA:MAX:0.1:40320:393

# 20150701 sheepwalk humidity sensor, main cellar

rrdtool create cellartemp.rrd --start 1435700000 --step 60 \
DS:temp:GAUGE:120:-50:110 \
RRA:LAST:0.5:1:15811200 \
RRA:AVERAGE:0.1:1440:10980 \
RRA:AVERAGE:0.1:10080:1569 \
RRA:AVERAGE:0.1:40320:393 \
RRA:MIN:0.1:1440:10980 \
RRA:MIN:0.1:10080:1569 \
RRA:MIN:0.1:40320:393 \
RRA:MAX:0.1:1440:10980 \
RRA:MAX:0.1:10080:1569 \
RRA:MAX:0.1:40320:393

rrdtool create cellarhum.rrd --start 1435700000 --step 60 \
DS:hum:GAUGE:120:0:100 \
RRA:LAST:0.5:1:15811200 \
RRA:AVERAGE:0.1:1440:10980 \
RRA:AVERAGE:0.1:10080:1569 \
RRA:AVERAGE:0.1:40320:393 \
RRA:MIN:0.1:1440:10980 \
RRA:MIN:0.1:10080:1569 \
RRA:MIN:0.1:40320:393 \
RRA:MAX:0.1:1440:10980 \
RRA:MAX:0.1:10080:1569 \
RRA:MAX:0.1:40320:393

# every 10 minutes is plenty often enough for this
rrdtool create cellarvdd.rrd --start 1435700000 --step 600 \
DS:vdd:GAUGE:120:0:10 \
RRA:LAST:0.5:1:1581120 \
RRA:AVERAGE:0.1:144:10980 \
RRA:AVERAGE:0.1:1008:1569 \
RRA:AVERAGE:0.1:4032:393 \
RRA:MIN:0.1:144:10980 \
RRA:MIN:0.1:1008:1569 \
RRA:MIN:0.1:4032:393 \
RRA:MAX:0.1:144:10980 \
RRA:MAX:0.1:1008:1569 \
RRA:MAX:0.1:40320:393


# 20150703 sheepwalk humidity sensor, office

rrdtool create officetemp.rrd --start 1435900000 --step 60 \
DS:temp:GAUGE:120:-50:110 \
RRA:LAST:0.5:1:15811200 \
RRA:AVERAGE:0.1:1440:10980 \
RRA:AVERAGE:0.1:10080:1569 \
RRA:AVERAGE:0.1:40320:393 \
RRA:MIN:0.1:1440:10980 \
RRA:MIN:0.1:10080:1569 \
RRA:MIN:0.1:40320:393 \
RRA:MAX:0.1:1440:10980 \
RRA:MAX:0.1:10080:1569 \
RRA:MAX:0.1:40320:393

rrdtool create officehum.rrd --start 1435900000 --step 60 \
DS:hum:GAUGE:120:0:100 \
RRA:LAST:0.5:1:15811200 \
RRA:AVERAGE:0.1:1440:10980 \
RRA:AVERAGE:0.1:10080:1569 \
RRA:AVERAGE:0.1:40320:393 \
RRA:MIN:0.1:1440:10980 \
RRA:MIN:0.1:10080:1569 \
RRA:MIN:0.1:40320:393 \
RRA:MAX:0.1:1440:10980 \
RRA:MAX:0.1:10080:1569 \
RRA:MAX:0.1:40320:393

rrdtool create officevdd.rrd --start 1435900000 --step 600 \
DS:vdd:GAUGE:120:0:10 \
RRA:LAST:0.5:1:1581120 \
RRA:AVERAGE:0.1:144:10980 \
RRA:AVERAGE:0.1:1008:1569 \
RRA:AVERAGE:0.1:4032:393 \
RRA:MIN:0.1:144:10980 \
RRA:MIN:0.1:1008:1569 \
RRA:MIN:0.1:4032:393 \
RRA:MAX:0.1:144:10980 \
RRA:MAX:0.1:1008:1569 \
RRA:MAX:0.1:40320:393

# 20150718 sheepwalk humidity sensor, coal cellar

rrdtool create coaltemp.rrd --start 1437100000 --step 60 \
DS:temp:GAUGE:120:-50:110 \
RRA:LAST:0.5:1:15811200 \
RRA:AVERAGE:0.1:1440:10980 \
RRA:AVERAGE:0.1:10080:1569 \
RRA:AVERAGE:0.1:40320:393 \
RRA:MIN:0.1:1440:10980 \
RRA:MIN:0.1:10080:1569 \
RRA:MIN:0.1:40320:393 \
RRA:MAX:0.1:1440:10980 \
RRA:MAX:0.1:10080:1569 \
RRA:MAX:0.1:40320:393

rrdtool create coalhum.rrd --start 1437100000 --step 60 \
DS:hum:GAUGE:120:0:100 \
RRA:LAST:0.5:1:15811200 \
RRA:AVERAGE:0.1:1440:10980 \
RRA:AVERAGE:0.1:10080:1569 \
RRA:AVERAGE:0.1:40320:393 \
RRA:MIN:0.1:1440:10980 \
RRA:MIN:0.1:10080:1569 \
RRA:MIN:0.1:40320:393 \
RRA:MAX:0.1:1440:10980 \
RRA:MAX:0.1:10080:1569 \
RRA:MAX:0.1:40320:393

rrdtool create coalvdd.rrd --start 1437100000 --step 600 \
DS:vdd:GAUGE:120:0:10 \
RRA:LAST:0.5:1:1581120 \
RRA:AVERAGE:0.1:144:10980 \
RRA:AVERAGE:0.1:1008:1569 \
RRA:AVERAGE:0.1:4032:393 \
RRA:MIN:0.1:144:10980 \
RRA:MIN:0.1:1008:1569 \
RRA:MIN:0.1:4032:393 \
RRA:MAX:0.1:144:10980 \
RRA:MAX:0.1:1008:1569 \
RRA:MAX:0.1:40320:393

# 20150702 1-wire temperature sensors on boiler flow & return

rrdtool create boilerflow.rrd --start 1434700000 --step 60 \
DS:temp:GAUGE:120:-50:110 \
RRA:LAST:0.5:1:15811200

rrdtool create boilerreturn.rrd --start 1434700000 --step 60 \
DS:temp:GAUGE:120:-50:110 \
RRA:LAST:0.5:1:15811200

# 20150703 1-wire temperature sensor under office floor

rrdtool create officeunderfloor.rrd --start 1434900000 --step 60 \
DS:temp:GAUGE:120:-50:110 \
RRA:LAST:0.5:1:15811200

# 20150717 1-wire temperature sensors just after zone valves

rrdtool create zvupstairsflow.rrd --start 1437100000 --step 60 \
DS:temp:GAUGE:120:-50:110 \
RRA:LAST:0.5:1:15811200

rrdtool create zvdownstairsflow.rrd --start 1437100000 --step 60 \
DS:temp:GAUGE:120:-50:110 \
RRA:LAST:0.5:1:15811200

rrdtool create zvhwflow.rrd --start 1437100000 --step 60 \
DS:temp:GAUGE:120:-50:110 \
RRA:LAST:0.5:1:15811200

# 20150719 1-wire temperature sensors on hw tank, and hot water flow/retrun

rrdtool create hwtank0.rrd --start 1437100000 --step 60 \
DS:temp:GAUGE:120:-50:110 \
RRA:LAST:0.5:1:15811200
rrdtool create hwtank1.rrd --start 1437100000 --step 60 \
DS:temp:GAUGE:120:-50:110 \
RRA:LAST:0.5:1:15811200
rrdtool create hwtank2.rrd --start 1437100000 --step 60 \
DS:temp:GAUGE:120:-50:110 \
RRA:LAST:0.5:1:15811200
rrdtool create hwtank3.rrd --start 1437100000 --step 60 \
DS:temp:GAUGE:120:-50:110 \
RRA:LAST:0.5:1:15811200
rrdtool create hwtank4.rrd --start 1437100000 --step 60 \
DS:temp:GAUGE:120:-50:110 \
RRA:LAST:0.5:1:15811200
rrdtool create hwtank5.rrd --start 1437100000 --step 60 \
DS:temp:GAUGE:120:-50:110 \
RRA:LAST:0.5:1:15811200

rrdtool create hwfeed0.rrd --start 1437100000 --step 60 \
DS:temp:GAUGE:120:-50:110 \
RRA:LAST:0.5:1:15811200
rrdtool create hwsec0.rrd --start 1437100000 --step 60 \
DS:temp:GAUGE:120:-50:110 \
RRA:LAST:0.5:1:15811200

# 20150729 1-wire temperature sensors on hot water return branches & upstairs
# bathroms/upstairs branch
rrdtool create hwsec1.rrd --start 1438100000 --step 60 \
DS:temp:GAUGE:120:-50:110 \
RRA:LAST:0.5:1:15811200
# kitchens branch
rrdtool create hwsec2.rrd --start 1438100000 --step 60 \
DS:temp:GAUGE:120:-50:110 \
RRA:LAST:0.5:1:15811200
# hw feed under office floor - note there are no hwfeed1/hwfeed2
rrdtool create hwfeed3.rrd --start 1438100000 --step 60 \
DS:temp:GAUGE:120:-50:110 \
RRA:LAST:0.5:1:15811200
rrdtool create hwsec3.rrd --start 1438100000 --step 60 \
DS:temp:GAUGE:120:-50:110 \
RRA:LAST:0.5:1:15811200

# 20150724 1-wire temperature sensors on the incoming water mains

rrdtool create cwsh.rrd --start 1437700000 --step 60 \
DS:temp:GAUGE:120:-50:110 \
RRA:LAST:0.5:1:15811200
rrdtool create cwsc.rrd --start 1437700000 --step 60 \
DS:temp:GAUGE:120:-50:110 \
RRA:LAST:0.5:1:15811200

# 20150701 hobby-boards counter, gas and water meters
# water meter counts in units of 10 litres
rrdtool create watermeter.rrd --start 1435700000 --step 60 \
DS:tenlitres:COUNTER:120:0:1000 \
RRA:LAST:0.5:1:15811200

# gas meter counts a pulse per dm3 of gas, which is 1/1000 of a m3; ~11Wh
rrdtool create gasmeter.rrd --start 1435700000 --step 60 \
DS:dmcubed:COUNTER:120:0:1000 \
RRA:LAST:0.5:1:15811200

# repton's counter prototype
rrdtool create reptonmeter.rrd --start 1435700000 --step 60 \
DS:counts:COUNTER:120:0:1000 \
RRA:LAST:0.5:1:15811200
