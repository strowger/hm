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
Designed to be run on system boot by init.

ebusread.pl
Gathers data from a running ebusd instance and logs to logfiles and RRDs.
Designed to be run from cron - relies on the ebusd instance having been started.

