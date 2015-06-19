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

## 20150619 styes
## 20101009 original
# currentcost
# outputs a value in watts and a temperature (of the receiver) every 6 seconds
# we'll capture them all but only save one per minute 
# we have two different data sources - the clamp meter and the pulse counter
# the clamp meter is less accurate and gives a number of watts
# the pulse counter gives a number of pulses as well as a calculated number of watts
rrdtool create cctemp.rrd --start 1434700000 --step 60 \
DS:temp:GAUGE:120:-10:110 \
RRA:LAST:0.5:1:15811200

rrdtool create ccclampwatts.rrd --start 1434700000 --step 60 \
DS:power:GAUGE:120:0:10000 \
RRA:LAST:0.5:1:15811200

rrdtool create ccoptiwatts.rrd --start 1434700000 --step 60 \
DS:power:GAUGE:120:0:10000 \
RRA:LAST:0.5:1:15811200

rrdtool create ccopticount.rrd --start 1434700000 --step 60 \
DS:power:COUNTER:120:0:1000 \
RRA:LAST:0.5:1:15811200

