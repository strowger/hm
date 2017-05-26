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

# 20170404 the clamp meter is now on the car chaging point so we'll start
# a new RRD

rrdtool create ccclampwattscar.rrd --start 1491300000 --step 60 \
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

# 20170501 additional clamp meter on the central heating

rrdtool create ccclampwattsheating.rrd --start 1493000000 --step 60 \
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

# 20170502 clamp meter on cooker radial

rrdtool create ccclampwattscooker.rrd --start 1493700000 --step 60 \
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

# 20170526 clamp meter on towel rail

rrdtool create ccclampwattstowelrail.rrd --start 1495800000 --step 60 \
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

# 20170422 currentcost individual appliance monitors

rrdtool create cciamwasher.rrd --start 1492800000 --step 60 \
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

rrdtool create cciamdryer.rrd --start 1492800000 --step 60 \
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

rrdtool create cciamfridge.rrd --start 1492800000 --step 60 \
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

rrdtool create cciamdwasher.rrd --start 1492800000 --step 60 \
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

rrdtool create cciamupsb.rrd --start 1492800000 --step 60 \
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

rrdtool create cciamofficedesk.rrd --start 1492800000 --step 60 \
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

rrdtool create cciamupso.rrd --start 1492800000 --step 60 \
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

rrdtool create cciamtoaster.rrd --start 1492800000 --step 60 \
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

rrdtool create cciamkettle.rrd --start 1492800000 --step 60 \
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

# 20151007 been gathering these for ages but not rrd'ing
# these things all change slowly and are clearly not worth <1h resolution

rrdtool create fanhrs.rrd --start 1444200000 --step 3600 \
DS:hrs:COUNTER:7200:U:U \
RRA:LAST:0.5:1:90000

rrdtool create hwchours.rrd --start 1444200000 --step 3600 \
DS:hrs:COUNTER:7200:U:U \
RRA:LAST:0.5:1:90000

rrdtool create pumphrs.rrd --start 1444200000 --step 3600 \
DS:hrs:COUNTER:7200:U:U \
RRA:LAST:0.5:1:90000

rrdtool create pumpstarts1.rrd --start 1444200000 --step 3600 \
DS:count:COUNTER:7200:U:U \
RRA:LAST:0.5:1:90000

rrdtool create pumpstarts2.rrd --start 1444200000 --step 3600 \
DS:count:COUNTER:7200:U:U \
RRA:LAST:0.5:1:90000

# 20151007 the two different places we can read the heating curve from

rrdtool create heatcurve1.rrd --start 1444200000 --step 3600 \
DS:curve:GAUGE:7200:U:U \
RRA:LAST:0.5:1:90000

rrdtool create heatcurve2.rrd --start 1444200000 --step 3600 \
DS:curve:GAUGE:7200:U:U \
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

# 20150817 sheepwalk humidity sensor, outside coal cellar

rrdtool create os1temp.rrd --start 1439700000 --step 60 \
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

rrdtool create os1hum.rrd --start 1439700000 --step 60 \
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

rrdtool create os1vdd.rrd --start 1439700000 --step 600 \
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

# 20150816 hobby-boards 1-wire barometer
# 20151104 re-made for use with homechip/edsproducts barometer 
rrdtool create baromtemp.rrd --start 1439700000 --step 60 \
DS:temp:GAUGE:120:-50:110 \
RRA:LAST:0.5:1:15811200

rrdtool create barompressure.rrd --start 1439700000 --step 60 \
DS:pres:GAUGE:120:800:1200 \
RRA:LAST:0.5:1:15811200

# 20151012 1-wire temperature sensors in front porch and wall cavity

rrdtool create porch1temp.rrd --start 1444600000 --step 60 \
DS:temp:GAUGE:120:-50:110 \
RRA:LAST:0.5:1:15811200

rrdtool create cavity1temp.rrd --start 1444600000 --step 60 \
DS:temp:GAUGE:120:-50:110 \
RRA:LAST:0.5:1:15811200

# 20151029 1-wire sensors on downstairs bath, radiator
# count of devices on bus, hourly

rrdtool create dbathradflow.rrd --start 1446000000 --step 60 \
DS:temp:GAUGE:120:-50:110 \
RRA:LAST:0.5:1:15811200

rrdtool create dbathradrtn.rrd --start 1446000000 --step 60 \
DS:temp:GAUGE:120:-50:110 \
RRA:LAST:0.5:1:15811200

# five sensors on bath, numbered from bottom upwards
rrdtool create dbath1.rrd --start 1446000000 --step 60 \
DS:temp:GAUGE:120:-50:110 \
RRA:LAST:0.5:1:15811200

rrdtool create dbath2.rrd --start 1446000000 --step 60 \
DS:temp:GAUGE:120:-50:110 \
RRA:LAST:0.5:1:15811200

rrdtool create dbath3.rrd --start 1446000000 --step 60 \
DS:temp:GAUGE:120:-50:110 \
RRA:LAST:0.5:1:15811200

rrdtool create dbath4.rrd --start 1446000000 --step 60 \
DS:temp:GAUGE:120:-50:110 \
RRA:LAST:0.5:1:15811200

rrdtool create dbath5.rrd --start 1446000000 --step 60 \
DS:temp:GAUGE:120:-50:110 \
RRA:LAST:0.5:1:15811200

# these should be "devs" not "curve" but i'd already started logging and making graphs...
# if fixed, need to update graph.pl with the new DS name too
rrdtool create 1wdevicecount0.rrd --start 1446000000 --step 3600 \
DS:curve:GAUGE:7200:U:U \
RRA:LAST:0.5:1:90000

rrdtool create 1wdevicecount1.rrd --start 1446000000 --step 3600 \
DS:curve:GAUGE:7200:U:U \
RRA:LAST:0.5:1:90000

rrdtool create 1wdevicecount2.rrd --start 1448000000 --step 3600 \                                               DS:curve:GAUGE:7200:U:U \                                                                                        RRA:LAST:0.5:1:90000  

# 20151030 small hall radiator
rrdtool create hall1flow.rrd --start 1446300000 --step 60 \
DS:temp:GAUGE:120:-50:110 \
RRA:LAST:0.5:1:15811200

rrdtool create hall1rtn.rrd --start 1446300000 --step 60 \
DS:temp:GAUGE:120:-50:110 \
RRA:LAST:0.5:1:15811200

# 20151101 downstairs bathroom

rrdtool create dbathvoid1.rrd --start 1446400000 --step 60 \
DS:temp:GAUGE:120:-50:110 \
RRA:LAST:0.5:1:15811200

rrdtool create dbathfeed1.rrd --start 1446400000 --step 60 \
DS:temp:GAUGE:120:-50:110 \
RRA:LAST:0.5:1:15811200

rrdtool create dbathfeed2.rrd --start 1446400000 --step 60 \
DS:temp:GAUGE:120:-50:110 \
RRA:LAST:0.5:1:15811200

rrdtool create ensuitedrain.rrd --start 1446400000 --step 60 \
DS:temp:GAUGE:120:-50:110 \
RRA:LAST:0.5:1:15811200

# 20151102 seconds to do reads - hourly

rrdtool create runtime1w.rrd --start 1446400000 --step 3600 \
DS:secs:GAUGE:7200:U:U \
RRA:LAST:0.5:1:90000

rrdtool create runtimeeb.rrd --start 1446400000 --step 3600 \
DS:secs:GAUGE:7200:U:U \
RRA:LAST:0.5:1:90000

# 20151103 1-wire error counters - hourly

for i in 0 1 2
do
  rrdtool create bus${i}utilpercent.rrd --start 1446400000 --step 3600 \
  DS:percent:GAUGE:7200:U:U \
  RRA:LAST:0.5:1:90000 
  
  for j in close_errors detect_errors errors locks open_errors program_errors pullup_errors read_errors reconnect_errors reconnects reset_errors resets select_errors shorts status_errors timeouts unlocks 
  do
    rrdtool create bus${i}${j}.rrd --start 1446400000 --step 3600 \
    DS:count:COUNTER:7200:U:U \
    RRA:LAST:0.5:1:90000
  done   
done

# 20151108 3 more sensors in cellar

rrdtool create kitchen1flow.rrd --start 1447018650 --step 60 \
DS:temp:GAUGE:120:-50:110 \
RRA:LAST:0.5:1:15811200

rrdtool create kitchen1rtn.rrd --start 1447018650 --step 60 \
DS:temp:GAUGE:120:-50:110 \
RRA:LAST:0.5:1:15811200

rrdtool create cellarwindow1.rrd --start 1447018650 --step 60 \
DS:temp:GAUGE:120:-50:110 \
RRA:LAST:0.5:1:15811200

# 20151111 swe3 humidity sensor in kitchen

rrdtool create kitchentemp.rrd --start 1447200000 --step 60 \
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

rrdtool create kitchenhum.rrd --start 1447200000 --step 60 \
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
rrdtool create kitchenvdd.rrd --start 1447200000 --step 600 \
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

# 20151118 stove thermocouple
rrdtool create stovetemp1.rrd --start 1447800000 --step 60 \
DS:temp:GAUGE:120:-50:600 \
RRA:LAST:0.5:1:15811200

# 20151120 swe3 humidity sensor on landing

rrdtool create landingtemp.rrd --start 1448000000 --step 60 \
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

rrdtool create landinghum.rrd --start 1448000000 --step 60 \
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
rrdtool create landingvdd.rrd --start 1448000000 --step 600 \
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

# 20151121 temp sensors on big rads in kitchen and hall
rrdtool create kitchen2flow.rrd --start 1448000000 --step 60 \
DS:temp:GAUGE:120:-50:110 \
RRA:LAST:0.5:1:15811200

rrdtool create kitchen2rtn.rrd --start 1448000000 --step 60 \
DS:temp:GAUGE:120:-50:110 \
RRA:LAST:0.5:1:15811200

rrdtool create hall2flow.rrd --start 1448000000 --step 60 \
DS:temp:GAUGE:120:-50:110 \
RRA:LAST:0.5:1:15811200

rrdtool create hall2rtn.rrd --start 1448000000 --step 60 \
DS:temp:GAUGE:120:-50:110 \
RRA:LAST:0.5:1:15811200

# 20151125 a quick hack, a barometer on the internet in hx to compare
# 10-minute'ly only
rrdtool create barompressure2.rrd --start 1448000000 --step 600 \
DS:pres:GAUGE:600:800:1200 \
RRA:LAST:0.5:1:1581120

# 20151205 second taaralabs thermocouple on stove
rrdtool create stovetemp2.rrd --start 1449300000 --step 60 \
DS:temp:GAUGE:120:-50:600 \
RRA:LAST:0.5:1:15811200

# 20160307 adsl link speeds from the vdsl cpe - 10 minute'ly only
# unsure what maximums could be, just know minimum is zero
rrdtool create wan0down.rrd --start 1457300000 --step 600 \
DS:kbit:GAUGE:600:0:U \
RRA:LAST:0.5:1:1581120
rrdtool create wan0up.rrd --start 1457300000 --step 600 \
DS:kbit:GAUGE:600:0:U \
RRA:LAST:0.5:1:1581120
# 20160308 nat table entries (i think)
rrdtool create wan0nat.rrd --start 1457300000 --step 600 \
DS:nats:GAUGE:600:0:U \
RRA:LAST:0.5:1:1581120

# 20160311 router.pl polls the house router
# for each interface we record in & out octets
for i in asus-wan0 asus-wifi24 asus-wifi5 asus-lan asus-bridge asus-wifi24-guest asus-wifi5-guest asus-wan1 
do
  rrdtool create ${i}.rrd --start 1457600000 --step 60 \
  DS:in:COUNTER:120:0:U \
  DS:out:COUNTER:120:0:U \
  RRA:LAST:0.5:1:15811200  
done

# 20160313 air.pl records air quality data
for i in airkitchen-co2 airkitchen-tvoc airkitchen-iaq airkitchen-pm25 airkitchen-pm10
do
  rrdtool create ${i}.rrd --start 1457800000 --step 60 \
  DS:val:GAUGE:120:0:U \
  RRA:LAST:0.5:1:15811200
done

# 20170113 air.pl rssi data
# no idea what the limits should be, rssi is arbitrary
# name 'kitchen' is from the air.conf file
rrdtool create rssi-kitchen.rrd --start 1484300000 --step 60 \
DS:rssi:GAUGE:120:U:U \
RRA:LAST:0.5:1:15811200

# 20170107 nissan leaf stuff
# assuming an absolute maximum imaginable lifetime of 15 years,
# so *just for car stuff* will have half the number of datapoints

# let's allow for some negative percentages, and for it to exceed 100
rrdtool create leafbattpc.rrd --start 1483700000 --step 60 \
DS:pc:GAUGE:3600:-50:150 \
RRA:LAST:0.5:1:7905600
# battery bars - min 0 max 12
rrdtool create leafbattbars.rrd --start 1483700000 --step 60 \
DS:bars:GAUGE:3600:-1:13 \
RRA:LAST:0.5:1:7905600

# battery capacity measures only change every few months so once per day is ample
# max is 12, min is 0

rrdtool create leafbattcap1.rrd --start 1483700000 --step 86400 \
DS:bars:GAUGE:86400:-1:13 \
RRA:LAST:0.5:1:5490

rrdtool create leafbattcap2.rrd --start 1483700000 --step 86400 \
DS:bars:GAUGE:86400:-1:13 \
RRA:LAST:0.5:1:5490

rrdtool create leafbattcap3.rrd --start 1483700000 --step 86400 \
DS:bars:GAUGE:86400:-1:13 \
RRA:LAST:0.5:1:5490

# how long script takes to run - will allow for it to be every min one day

rrdtool create runtimeleaf.rrd --start 1483700000 --step 60 \
DS:secs:GAUGE:3600:U:U \
RRA:LAST:0.5:1:7905600

# 20170129 leafspy stuff
# we only have data for these while the vehicle is powered-up to use

# these are things which change rapidly enough that a sub-minute resolution 
# is not a complete waste. we keep:
# 2 weeks of every 5 seconds (5 secs is 12 times/min: 12*60*24*14=241920)
# 15 years of daily min/max/average 
#  (there are 12*60*24 = 17280 5sec values in a day)
#  (and 366*15 = 5500 days in 15 years)
#DS - name, counter/gauge type, time without a value before entering "nothing" in rrd, min value, max value                                                                                                 
#RRA - name, type (GAUGE/COUNTER), xff, step, rows
#  xff is proportion (0 to 1) of values which can be unknown before the rra just holds 'unknown
#    - we might not drive much but we still want to record something!
#  step is number of 'DS' values to run the 'type' over (eg take average of 'step' steps)
#  rows is number of those to keep                                                                                                     
#next - how many seconds between records                                                              
#how many records to keep  

for i in speed packamps drivemotor auxpower acpower acpres acpower2 heatpower chargepower elevation regenwatts
do
rrdtool create ls-${i}.rrd --start 1485400000 --step 5 \
DS:${i}:GAUGE:60:U:U \
RRA:LAST:0.001:1:241920 \
RRA:AVERAGE:0.001:17280:5500 \
RRA:MAX:0.001:17280:5500 \
RRA:MIN:0.001:17280:5500
done

# 20170424 new leafspy version gave a new piece of information - motor temp

for i in motortemp
do
rrdtool create ls-${i}.rrd --start 1493000000 --step 5 \
DS:${i}:GAUGE:60:U:U \
RRA:LAST:0.001:1:241920 \
RRA:AVERAGE:0.001:17280:5500 \
RRA:MAX:0.001:17280:5500 \
RRA:MIN:0.001:17280:5500
done

# for these, which change more slowly, we just need once a minute, then the same 
# 15 years daily min/max/avg
# once a minute is 1440 times/day, 20160 times in 2 weeks
for i in gids soc amphr packvolts packvolts2 packvolts3 maxcpmv mincpmv avgcpmv cpmvdiff judgementval packtemp1 packtemp2 packtemp4 voltsla packhealth packhealth2 ambienttemp phonebatt
do
rrdtool create ls-${i}.rrd --start 1485400000 --step 60 \
DS:${i}:GAUGE:120:U:U \
RRA:LAST:0.001:1:20160 \
RRA:AVERAGE:0.001:1440:5500 \
RRA:MAX:0.001:1440:5500 \
RRA:MIN:0.001:1440:5500
done

# 96 cell pairs, same intervals as above
for i in `seq 1 96`
do
rrdtool create ls-cp${i}.rrd --start 1485400000 --step 60 \
DS:v:GAUGE:120:U:U \
RRA:LAST:0.001:1:20160 \
RRA:AVERAGE:0.001:1440:5500 \
RRA:MAX:0.001:1440:5500 \
RRA:MIN:0.001:1440:5500 
done

# these ones are counters not gauges, otherwise same rules as above

for i in regenwh odom
do                                                                                                    
rrdtool create ls-${i}.rrd --start 1485400000 --step 60 \
DS:${i}:COUNTER:120:U:U \
RRA:LAST:0.001:1:20160 \
RRA:AVERAGE:0.001:1440:5500 \
RRA:MAX:0.001:1440:5500 \
RRA:MIN:0.001:1440:5500
done 

# daily values for 15 years only - counters not gauges
for i in quickcharges slowcharges
do
rrdtool create ls-${i}.rrd --start 1485400000 --step 86400 \
DS:${i}:COUNTER:86400:U:U \
RRA:LAST:0.001:1:5500
done

