#! /usr/bin/perl -w
#
# leafspy.pl - gather datafiles dropped in dropbox by leafspy,
#  send them for processing if there are new ones, store them.
#
# intended to be run from cron at short intervals as checking for
#   new or updated files is cheap/quick.
#
# GH 2017-01-28
# begun
#

$logdirectory="/data/hm/log";
$logfile="leafspy.log";
$lockfile="/tmp/leafspy.lock";
# directories where logs arrive, and are kept
$in="/home/leaf/logs";
$out="/data/hm/leaf";

$processor="/data/hm/bin/leafspy-process.pl -process";

# if the lock exists, just quit - checklogs will alert if we don't get run
if ( -f $lockfile ) { exit 0; }

open LOCKFILE, ">", $lockfile or die $!;

$timestamp = time();                                                                                  

open LOGFILE, ">>", "$logdirectory/$logfile" or die $!;                                               

print LOGFILE "starting leafspy.pl at $timestamp\n";

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
  # only files ending .csv are interesting
  if ($file !~ /\.csv$/) 
  {
    print LOGFILE "ignoring non-csv file $file\n"; 
    next; 
  }
  # if it doesn't exist in the out directory, create it 0 length
  if ( ! -f "${out}/${file}" ) { `touch $out/$file`; }
  $insize = (stat "${in}/${file}")[7];
  $outsize = (stat "${out}/${file}")[7]; 
  if ( $insize == $outsize ) 
  { 
    print LOGFILE "ignoring unchanged file $file\n";
    next; 
  }
  # we'll now only get $file if it's not the same in both in & out directories
  # copy the file to a temporary one in case it changes while we're working on it
  `cp $in/$file /tmp/$file`;
  # at the end, move temporary file to out with the right name
  print LOGFILE "working on file $file\n";
  # diff them, lose the first line and the "< " from the start of each diff'ed line
  @diff = `diff /tmp/$file $out/$file|sed "1 d"|sed "s/^\< //"`;
  # having done the diff, copy the file 
  `cp /tmp/$file $out/$file`;
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
