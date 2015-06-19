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

# TODO aren't these MIN/MAX all arse? 1440 = 24mins, 3650 times?

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

rrdtool create flowtemp.rrd --start 1434700000 --step 60 \
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



