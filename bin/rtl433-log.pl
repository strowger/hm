#! /usr/bin/perl -w
#
# rtl433-log.pl - parse output from rtl433 and create logs
#
# this runs rtl433 and collects the output in a logfile.
# it is intended to run on a 'remote' device, and for log parsing
# to happen elsewhere - therefore it does not attempt to do any processing
#
# GH 2017-03-25
# begun
#

$logdirectory="/data/hm/rtl";
$lockfile="/tmp/rtl433-log.lock";
$rtl433="/usr/local/bin/rtl_433";
# prepended to logfile names
$location="alarmbox";
# -G: enable all protocols
# -U: use utc for all timestamps
# -T x: run for x seconds - shouldn't be too short as there's a startup delay
$rtloptions="-G -U -T 60";


if ( -f $lockfile ) 
{
  print "FATAL: lockfile exists, exiting";
  exit 2;
}
open LOCKFILE, ">", $lockfile or die $!;

while (1)
{
  $timestamp=time();
  open LOGFILE, ">", "$logdirectory/$location-$timestamp.log" or die $!;
# there's quite a lot of debug output, which is temporarily useful if it fails
<<<<<<< HEAD
  $rtloutput = `$rtl433 $rtloptions 2>$logdirectory/$location-debug.log`;
=======
  `date > $logdirectory/debug.log`;
  $rtloutput = `$rtl433 $rtloptions 2>>$logdirectory/debug.log`;
>>>>>>> 8bab334601c2f921f5fd2b917e862e74e9832042
  print LOGFILE "$rtloutput";
  close LOGFILE;
}
#$endtime = time();
#$runtime = $endtime - $starttime;

close LOCKFILE;
unlink $lockfile;


