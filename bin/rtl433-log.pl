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

$templogdirectory="/data/hm/rtltmp";
$logdirectory="/data/hm/rtl";
$lockfile="/tmp/rtl433-log.lock";
$rtl433="/usr/local/bin/rtl_433";
# prepended to logfile names
$location="**FIXME**";
# -G: enable all protocols
# -U: use utc for all timestamps
# -T x: run for x seconds - shouldn't be too short as there's a startup delay
# ** if these options change, the rtl433-watchdog.pl script must be updated**
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
  open LOGFILE, ">", "$templogdirectory/$location-$timestamp.log" or die $!;
# there's quite a lot of debug output, which is temporarily useful if it fails
  `date > $templogdirectory/debug.log`;
  $rtloutput = `$rtl433 $rtloptions 2>>$templogdirectory/debug.log`;
  print LOGFILE "$rtloutput";
  close LOGFILE;
  `find $templogdirectory -type f -size +0c -exec mv {} $logdirectory \\;`;
}
#$endtime = time();
#$runtime = $endtime - $starttime;

close LOCKFILE;
unlink $lockfile;


