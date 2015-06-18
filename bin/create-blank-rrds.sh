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

#in ds:
#start time when the s/w was first used
#step time in seconds
#counter/gauge type
#time without a value before entering "nothing" in rrd
#min value
#max value
#
#in rra:
#0.5 - can't remember
#next - how many seconds between records
#how many records to keep

# TODO aren't these MIN/MAX all arse? 1440 = 24mins, 3650 times?

rrdtool create 

