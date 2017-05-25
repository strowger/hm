#! /usr/bin/perl -w
#
# rtl433-watchdog.pl - check for stuck rtl433 processes and restart them
#
# rtl433 on rpi sometimes generates an error on startup and hangs forever -
# we need to catch this state and restart it.
#
# this is intended to run locally on a 'remote' device doing log collection
# with rtl433, from cron, every few minutes
#
# GH 2017-05-14
# begun
#

$templogdirectory="/data/hm/rtltmp";
$lockfile="/tmp/rtl433-watchdog.lock";
$logfile="/tmp/rtl-watchdog.log";
$watchlog="debug.log";

if ( -f $lockfile )
{
  print "FATAL: lockfile exists, exiting";
  exit 2;
}
open LOCKFILE, ">", $lockfile or die $!;

$timestamp=time();

$watchctime=(stat("$templogdirectory/$watchlog"))[9];
$watchage = $timestamp - $watchctime;

$lastlogline = `tail -1 $logfile`;

open LOGFILE, ">>", "$logfile" or die $!;

# this tests for whether the last rtl433 process, which should exit after
# 60 seconds, has failed to exit
if ( $watchage > 80 )
{
  # a temporary log file
  print LOGFILE "$timestamp found $watchlog with age $watchage...";
  # if the last log line was us killing it for failing to exit, and it's failed
  # again, it's probably stuck and we'll reboot
  if ( $lastlogline =~ /killing/ )
  {
    print LOGFILE "$timestamp found last watchdog run was a restart, rebooting...\n";
    `wall "rtl-watchdog found rtl error, rebooting in 1 minute`;
    close LOGFILE;
    sleep 90;
    close LOCKFILE;
    unlink $lockfile;
    `sudo reboot`;
  }
  # if the options used in the rtl433-log script change, have to update this
  $rtlpid = `ps x|grep "/[u]sr/local/bin/rtl_433 -G -U -T 60"|grep -v \\>\\>|awk '{print \$1}'`;
  chomp $rtlpid;
  if ( $rtlpid =~ /\d/ )
  {
    # we got the pid of the rtl433 process
    print LOGFILE "killing rtl433 pid $rtlpid\n";
    kill 'KILL', $rtlpid;
  }
  else
  {
    print LOGFILE "failed to find rtl433 pid\n";
  }
}
else { print LOGFILE "$timestamp ok\n"; }


close LOGFILE;
close LOCKFILE;
unlink $lockfile;
