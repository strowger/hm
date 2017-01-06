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
$errorlog="leaf-errors.log";
$lockfile="/tmp/leaf.lock";
$carwings="/data/hm/bin/leaf.py";

if ( -f $lockfile ) 
{
  die "Lockfile exists in $lockfile; exiting";
}

open LOCKFILE, ">", $lockfile or die $!;

$timestamp = time();
$starttime = $timestamp;

open LOGFILE, ">>", "$logdirectory/$logfile" or die $!;
open ERRORLOG, ">>", "$logdirectory/$errorlog" or die $!;

print LOGFILE "starting leaf.pl at $timestamp\n";

$carwingsoutput = `${carwings}`;

print LOGFILE "$carwingsoutput";
# splitting on space splits on any kind of whitespace incl newline
@cwoutputlines = split(" ",$carwingsoutput);


###if ( $routeroutputlines[0] ne "Inter-|   Receive                                                |  Transmit" )
###  { die "wrong output format in router output"; }
###
foreach $line (@cwoutputlines)
{
  print "$line \n";
}
# there are 3 different things called 'capacity', one presumably is the
# capacity bars which are lost as the battery ages...
$batterycapacity1 = @cwoutputlines[13];
$batterycapacity2 = @cwoutputlines[9];
$batterycapacity3 = @cwoutputlines[7];
$batterybars = @cwoutputlines[15];
$batterypercent = @cwoutputlines[29];
print "battery percentage: $batterypercent, bars: $batterybars, 3 capacity measures: $batterycapacity1 $batterycapacity2 $batterycapacity3\n";


$endtime = time();
# pycarwings / leaf.py calls the nissan api which has to wait for the car
# to wake up etc - so it polls every 10sec for an answer from the api

$runtime = $endtime - $starttime;

#
#open LINE, ">>", "$logdirectory/runtimeleaf.log" or die $!;
#print LINE "$timestamp $runtime\n";
#close LINE;
#if ( -f "$rrddirectory/runtimeleaf.rrd" )
#{
#  $output = `rrdtool update $rrddirectory/runtimeleaf.rrd $timestamp:$runtime`;
#  if (length $output)
#    {
#      print LOGFILE "rrdtool errored $output\n";
#    }
#}
#else
#{
#  print LOGFILE "rrd for runtimeleaf doesn't exist, skipping update\n";
#}

print LOGFILE "leaf.pl ran for $runtime seconds\n";
print LOGFILE "exiting successfully\n\n";

close LOCKFILE;
unlink $lockfile;
