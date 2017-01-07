#! /usr/bin/perl -w
#
# leaf.pl - run pycarwings2 (see https://github.com/jdhorne/pycarwings2)
# to retrieve data from nissan leaf/carwings and add to log/rrd
#
# should be run from cron - am unsure how long the carwings service caches
# data for, and how often it can be run before impacting vehicle 12v battery
# life and/or pissing nissan off.
#
# GH 2017-01-06
# begun
#
$rrddirectory="/data/hm/rrd";
$logdirectory="/data/hm/log";
$logfile="leaf.log";
#$errorlog="leaf-errors.log";
$lockfile="/tmp/leaf.lock";
$carwings="/data/hm/bin/leaf.py";
# where the shit that comes out of the python program goes, will probably end up
# erasing this quite frequently
$templogfile="leaftemp.log";

if ( -f $lockfile ) 
{
  die "Lockfile exists in $lockfile; exiting";
}

open LOCKFILE, ">", $lockfile or die $!;

$timestamp = time();
$starttime = $timestamp;

open LOGFILE, ">>", "$logdirectory/$logfile" or die $!;
#open ERRORLOG, ">>", "$logdirectory/$errorlog" or die $!;
open TEMPLOGFILE, ">>", "$logdirectory/$templogfile" or die $!;

print LOGFILE "starting leaf.pl at $timestamp\n";

$carwingsoutput = `${carwings}`;

print TEMPLOGFILE "$carwingsoutput";
# splitting on space splits on any kind of whitespace incl newline
@cwoutputlines = split(" ",$carwingsoutput);

# FIXME once we've seen some errors we should trap them here - the expected
# content of a successful run has 'date' in the first field so that's a good
# start
#  if this errors often then the mails from cron will get annoying - in which 
#  case, like the 1wire script, write to teh errorlog and have that parsed
if ( $cwoutputlines[0] ne "date" )
{ die "wrong output format in carwings output from $carwings"; }

# this was just for dev/debug
#foreach $line (@cwoutputlines)
#{
#  print "$line \n";
#}

# there are 2 times, one appears to be localtime (in GMT) and the other an
# hour ahead (CET?), one is possibly api-call time and the other possibly
# last-retrieval-from-car time. date formats are different too...cba to
# correct them here
$date1 = $cwoutputlines[1];
$date2 = $cwoutputlines[4];
$time1 = $cwoutputlines[2];
$time2 = $cwoutputlines[5];
# FIXME a useful thing to do would be check if these dates are after the
# previous date in the log and do something if not

# there are 2 different things called charging status, a state for each
# kind of charging, one for "plugin_state" and 1 each for "is_connected"
# to 2 kinds of charger (chademo/ac)
$chstate1 = $cwoutputlines[11];
$chstate2 = $cwoutputlines[17];
$ischargingnorm = $cwoutputlines[19];
$ischargingquick = $cwoutputlines[21];
$pluginstate = $cwoutputlines[23];
$isconnectednorm = $cwoutputlines[25];
$isconnectedquick = $cwoutputlines[27];

# there are 3 different things called 'capacity', one presumably is the
# capacity bars which are lost as the battery ages...
$batterycapacity1 = $cwoutputlines[13];
$batterycapacity2 = $cwoutputlines[9];
$batterycapacity3 = $cwoutputlines[7];
$batterybars = $cwoutputlines[15];
$batterypercent = $cwoutputlines[29];

print LOGFILE "battery percentage: $batterypercent, bars: $batterybars, 3 capacity measures: $batterycapacity1 $batterycapacity2 $batterycapacity3\n";
print LOGFILE "dates 1: $date1 2: $date2. times 1: $time1 2: $time2\n";
print LOGFILE "charging statuses 1: $chstate1 2: $chstate2 norm: $ischargingnorm quick: $ischargingquick\n";
print LOGFILE "connection status pluggedin: $pluginstate norm: $isconnectednorm quick: $isconnectedquick\n";

# we rrd battery percent, battery bars (and below, time taken to run)
# also the 3 capacity measures, although the rrd for them probably only
# needs to save them once a day

open LINE, ">>", "$logdirectory/leafbattpc.log" or die $!;
print LINE "$timestamp $batterypercent\n";
close LINE;
if ( -f "$rrddirectory/leafbattpc.rrd" )
{
  $output = `rrdtool update $rrddirectory/leafbattpc.rrd $timestamp:$batterypercent`;
  if (length $output)
    { print LOGFILE "rrdtool errored $output\n"; }
}
else
  { print LOGFILE "rrd for leafbattpc doesn't exist, skipping update\n"; }


open LINE, ">>", "$logdirectory/leafbattbars.log" or die $!;
print LINE "$timestamp $batterybars\n";
close LINE;
if ( -f "$rrddirectory/leafbattbars.rrd" )
{
  $output = `rrdtool update $rrddirectory/leafbattbars.rrd $timestamp:$batterybars`;
  if (length $output)
    { print LOGFILE "rrdtool errored $output\n"; }
}
else
  { print LOGFILE "rrd for leafbattbars doesn't exist, skipping update\n"; }


open LINE, ">>", "$logdirectory/leafbattcap1.log" or die $!;
print LINE "$timestamp $batterycapacity1\n";
close LINE;
if ( -f "$rrddirectory/leafbattcap1.rrd" )
{
  $output = `rrdtool update $rrddirectory/leafbattcap1.rrd $timestamp:$batterycapacity1`;
  if (length $output)
    { print LOGFILE "rrdtool errored $output\n"; }
}
else
  { print LOGFILE "rrd for leafbattcap1 doesn't exist, skipping update\n"; }

open LINE, ">>", "$logdirectory/leafbattcap2.log" or die $!;
print LINE "$timestamp $batterycapacity2\n";
close LINE;
if ( -f "$rrddirectory/leafbattcap2.rrd" )
{
  $output = `rrdtool update $rrddirectory/leafbattcap2.rrd $timestamp:$batterycapacity2`;
  if (length $output)
    { print LOGFILE "rrdtool errored $output\n"; }
}
else
  { print LOGFILE "rrd for leafbattcap2 doesn't exist, skipping update\n"; }

open LINE, ">>", "$logdirectory/leafbattcap3.log" or die $!;
print LINE "$timestamp $batterycapacity3\n";
close LINE;
if ( -f "$rrddirectory/leafbattcap3.rrd" )
{
  $output = `rrdtool update $rrddirectory/leafbattcap3.rrd $timestamp:$batterycapacity3`;
  if (length $output)
    { print LOGFILE "rrdtool errored $output\n"; }
}
else
  { print LOGFILE "rrd for leafbattcap3 doesn't exist, skipping update\n"; }


$endtime = time();
# pycarwings / leaf.py calls the nissan api which has to wait for the car
# to wake up etc - so it polls every 10sec for an answer from the api

$runtime = $endtime - $starttime;

open LINE, ">>", "$logdirectory/runtimeleaf.log" or die $!;
print LINE "$timestamp $runtime\n";
close LINE;
if ( -f "$rrddirectory/runtimeleaf.rrd" )
{
  $output = `rrdtool update $rrddirectory/runtimeleaf.rrd $timestamp:$runtime`;
  if (length $output)
    { print LOGFILE "rrdtool errored $output\n"; }
}
else
  { print LOGFILE "rrd for runtimeleaf doesn't exist, skipping update\n"; }

print LOGFILE "leaf.pl ran for $runtime seconds\n";
print LOGFILE "exiting successfully\n\n";

close LOCKFILE;
unlink $lockfile;
