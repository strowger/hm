# hm
home monitoring stuff

This is a set of scripts and configs I use for monitoring various aspects of my home.

It's here so that I can work on it. Don't go thinking it will be useful for anyone else.

create-blank-rrds.sh
Contains the rrdtool commands used to generate the various RRDs used by other programs in this repository.
Probably each command will only be needed once ever.
Not designed to be run at all - as it would wipe out all the data in the RRDs.

power.pl 
Gathers data from a Currentcost EnviR device's serial output.
Writes to a logfile and to RRDs.
Designed to be run on system boot by init. In practice it appears to stop reading at some point between a few minutes and a few hours after being started. I've failed to understand why this is and resorted to restarting it every 5 minutes:

getpower.sh
Restarts power.pl. Designed to be run from cron every few minutes.

ebusread.pl
Gathers data from a running ebusd instance and logs to logfiles and RRDs.
Designed to be run from cron - relies on the ebusd instance having been started.

1wireread.pl
Gathers data from 1-wire devices using owfs and logs to logfiles and RRDs.
Designed to be run from cron - relies on the owfs owserver instance having been started.

graph.pl
Create graphs using the data stored in RRDs.
Should be driven by a config file, but isn't.

checklogs.pl
Check log files for various errors and invalid values.
Heavily hard-coded to my own house's setup.
Terrible code with lots of lazy backticks.

to-do

we are gathering data from downstairs bathroom radiator flow/return but not graphing it

we are not graphing the sensor in the void by the downstairs toilet cistern

the water meter data is not being collected until we get another counter board, and even then the graphing is unhelpful and needs updating (like for the gas?)

we started to instrument the smaller kitchen radiator but the sensors are not yet connected
