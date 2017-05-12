#! /usr/bin/perl -w
#
# rtl433-logimport.pl - import rtl433 logfiles generated on remote system
#  based on leafspy.pl
# intended to be run from cron at short intervals as checking for
# new or updated files is cheap/quick, or called directly by the logsync
# script
#
# GH 2017-03-25
# begun
#

$logdirectory="/data/hm/log";
$logfile="rtl433-logimport.log";
$lockfile="/tmp/rtl433-logimport.lock";
# directories where logs arrive, and are kept
$in="/data/hm/rtl-in";
$out="/data/hm/rtl-out";
## prepended to logfile names, indicates source
##$location="alarmbox";
# program which parses the logfiles
$processor="/data/hm/bin/rtl433-process.pl -process";
#$processor="/bin/cat";

if ( -f $lockfile ) { die "Lockfile exists in $lockfile; exiting"; }

open LOCKFILE, ">", $lockfile or die $!;

$timestamp = time();                                                                                  

open LOGFILE, ">>", "$logdirectory/$logfile" or die $!;                                               

print LOGFILE "starting rtl433-logimport.pl at $timestamp\n";

opendir(IN, "$in") or die $!;

while ($file = readdir(IN))
  { push (@rawfiles, $file); }

# we need the files in order otherwise we try to update the RRDs out-of-order

@files = sort (@rawfiles);

foreach $file (@files)
{
  $starttime = time();
  $linecount = 0;
  # if it's "." or ".." skip it silently
  if (($file eq ".") || ($file eq "..")) { next; }
  # we don't parse the debug log, it's just for fault-finding
  if ($file =~ /debug.log$/) { next; }
  # only files ending .log are interesting
  if ($file !~ /\.log$/) 
  {
    print LOGFILE "ignoring non-log file $file\n"; 
    next; 
  }
  # if it doesn't exist in the out directory, create it 0 length
  if ( ! -f "${out}/${file}" ) { `touch $out/$file`; }
  $insize = (stat "${in}/${file}")[7];
  $outsize = (stat "${out}/${file}")[7]; 
  if ( $insize == $outsize ) 
  { 
    # this is very spammy
    # print LOGFILE "ignoring unchanged file $file\n";
    next; 
  }
  # we'll now only get $file if it's not the same in both in & out directories
  # copy the file to a temporary one in case it changes while we're working on it
  `cp $in/$file /tmp/$file`;
  # at the end, move temporary file to out with the right name
  print LOGFILE "working on file $file\n";
  # diff them, lose the first line and the "< " from the start of each diff'ed line
  @diff = `diff /tmp/$file $out/$file|sed "1 d"|sed "s/^\< //"`;
  # having done the diff, move the file 
  `mv -f /tmp/$file $out/$file`;
  open PROCESSOR, "|$processor";
  foreach $diffline (@diff)
  {
    $linecount = $linecount + 1;
    print PROCESSOR "$diffline";
  }
  close (PROCESSOR);
  
  $endtime = time();
  $filetime = $endtime - $starttime;
  print LOGFILE "finished with file $file in $filetime seconds for $linecount lines\n";
}

$timestamp = time();

print LOGFILE "exiting at $timestamp\n\n";
close LOCKFILE;
unlink $lockfile;
