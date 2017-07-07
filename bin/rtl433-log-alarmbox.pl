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
$location="alarmbox";
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

# sometimes rtl433 goes wrong (hw problem with rtl stick) and exits after a
# few sessions. we catch those, and count them, with a view to rebooting if
# it recurrs
$shortsessions = 0;

while (1)
{
  $timestamp=time();
  $starttime=$timestamp;
  open LOGFILE, ">", "$templogdirectory/$location-$timestamp.log" or die $!;
# there's quite a lot of debug output, which is temporarily useful if it fails
  `date > $templogdirectory/debug.log`;
  $rtloutput = `$rtl433 $rtloptions 2>>$templogdirectory/debug.log`;
  print LOGFILE "$rtloutput";
  $endtime=time();
  $runtime = $endtime - $starttime;
  if ( $runtime < 20 ) # short session, they should last ~60sec
  {
    $shortsessions = $shortsessions + 1;
    print LOGFILE "\nERROR: SHORT SESSION\n";  
  }
  print LOGFILE "short (error) sessions since last restart: $shortsessions\n";
  close LOGFILE;
  `find $templogdirectory -type f -size +0c -exec mv {} $logdirectory \\;`;
}
#$endtime = time();
#$runtime = $endtime - $starttime;

close LOCKFILE;
unlink $lockfile;


