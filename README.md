# hm
home monitoring stuff

This is a set of scripts and configs I use for monitoring various aspects of my home and car.

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

router.pl
Reads data from asus home router and logs to lgofiles and RRDs.
Not useful as the router does not expose most needed values over snmp - instead an alternative method using ssh is necessary and not implemented.

air.pl
Reads data expressed as bluetooth low energy broadcasts from a popular air quality measurement device. Logs to logfiles and RRDs.

beacon.pl
Reads data expressed as bluetooth low energy broadcasts from ankhmaway bluetooth sensor beacon. Abandoned before logging etc was properly implemented out of frustration with the impossiblity of extracting useful information from the beacon's accelerometer outputs.

rtl433 scripts:

rtl433 uses an rtl-sdr to receive 433mhz broadcasts. initially this receives broadcasts from our currentcost devices, with a view to replacing the currentcost base station eventually. 

rtl433-log.pl
Runs rtl433 and collects its output in a series of logfiles for later parsing. Intended to be run on a separate box in a remote location, and logs copied back for parsing.

rtl433-logsync.sh
Copies logs from the above script on a separate box, onto a server for processing. Uses rsync. Intended to be run on the server from cron at frequent intervals.

rtl433-logimport.pl
Works on the directory used by the above script to indentify new logs which have not yet been parsed, and pass them to the script below for parsing.

rtl433-process.pl
Called by the above script to parse rtl433 logs and generate condensed logfiles locally which are suitable for long-term storage, and update rrds. Can also be used to simply print information about rtl433 logs for manual inspection.


Nissan Leaf stuff
-----------------

leaf.py
Python script from the 'pycarwings2' project which does the hard work of interacting with Nissan. using the leaf.py script from pycarwings2.

leaf.pl
Queries the Nissan Carwings (aka NissanConnect) API to gather data from a Nissan Leaf electric vehicle using the leaf.py script (above) from pycarwings2, and logs to logfiles and RRDs.

leafspy.pl
Checks a dropbox location on local disk for newly-arrived leafspy data files and sends any new ones for processing.

leafspy-process.pl
Parses log lines from the Android/IOS Leafspy app, which logs data from a Nissan Leaf using the obd2 interface. Displays information about the log lines on standard out, or logs it to RRDs.

leafspy-findjourneys.pl
Parses log files from the Leafspy app to find the start and end times of journeys.

leaf-dailystats.pl
Unfinished. Parses logs from currentcost clamp meter in car charger, and leafspy, to generate a line for each day showing power used and miles covered, and economy.

to-do
-----

we are not graphing the sensor in the void by the downstairs toilet cistern

the water meter data is not being collected until we get another counter board, and even then the graphing is unhelpful and needs updating (like for the gas?)

