#! /usr/bin/perl -w
#
# allstats.pl
#
# GH 2019-11-24
# palpitations wearing off
#

# we use variables once in splits 
no warnings 'once';

# for calculations re epoch / start of day
use Time::Local;

# price of power, pence per kWh
$powerprice = 12.73; # white rose energy from sept 2019
$logdirectory="/data/hm/log";

$lockfile="/tmp/allstats.lock";

if ( -f $lockfile ) 
{
  print "FATAL: lockfile exists, exiting";
  exit 2;
}
open LOCKFILE, ">", $lockfile or die $!;

$yesterday = 0;

if ($ARGV[0] =~ /yesterday/)
{
  print "performing run for yesterday\n";
  $yesterday = 1;
}

$listing = `ls $logdirectory/hs100*|grep -v errors|grep -v runtime|grep -v hs100.log`;

$listing2 = `ls $logdirectory/tasmota*|grep -v errors|grep -v runtime|grep -v tasmota.log`;
$listing = $listing . $listing2;

$listing2 = `ls $logdirectory/rtl433-c*lamp*log`;
$listing = $listing . $listing2;

$listing2 = `ls $logdirectory/rtl433-cciam*`;
$listing = $listing . $listing2;

$timestamp = time();
$starttime = $timestamp; # for counting runtime
$endtime = $timestamp; # for reading logfiles

# this will give us the epoch at midnight (ie the start of today, in the past)
($day, $month, $year) = ( localtime() )[3 .. 5];
$midnight = timelocal( 0, 0, 0, $day, $month, $year );

if ($yesterday == 1)
{
  $endtime = $midnight;
  $midnight = $midnight - 86400;
}



# we hopefully get a log line from the charger a few times a minute, so if
# we accept rtl433 and/or the currentcost being a bit rubbish, we'll look for
# one within 100 seconds, ie using grep through the log for all but the last 
# 2 digits of the string in $midnight

$searchstring = substr($midnight, 0, 8);

@filelist = split(" ",$listing);

$badlines = 0;
$goodlines = 0;
$longgaps = 0;

foreach $filename (@filelist)
{
  print "working on $filename: ";
  # get the position in the file where that occurred
  # force ascii mode, get byte count, output first match only, search for "start of line, search string, 2 digits"

  $grepoutput = `grep -a --byte-offset -m1 \$${searchstring}[0-9][0-9] ${filename}`;

  if ( $? > 0) 
  { 
    print "grep error'red searching for midnight\n"; 
    next;
  }

  # we just want the offset, which is the first thing in the output and ends :

  # split returns an array, we only want the first value
  ($fileoffset)=split(":", $grepoutput);
  
  open CHLOG, "<", "$filename";
  seek(CHLOG, $fileoffset, 0);

  $lastline = $midnight;
  $wh = 0;

  foreach $logline (<CHLOG>)
  {
    # most files are in simple "timestamp watts" format
    ($linetime, $watts) = split(" ",$logline);
    chomp $watts;
    # hs100 is "timestamp v volts a amps w watts"
    # tasmota actually the same but with more trailing crap
    # no trailing newline on the watts value for these
    if (( $filename =~ /hs100/ ) || ( $filename =~ /tasmota/ ))
    {
      ($linetime, $crap, $crap2, $crap3, $crap4, $crap5, $watts) = split(" ",$logline);
    }
    if (( $linetime !~ /\d{10}/ ) || ( $watts !~ /\d/ ))
    {
      print "bollocks line $logline\n";
      $badlines++;
    }
    if ( $linetime > $endtime) { last; }
    $lineinterval=$linetime - $lastline;
    if ($lineinterval > 180) 
    { 
      #print "long gap between charger logs at $linetime\n";
      $longgaps++;
    }
    $wh = $wh + ($watts * $lineinterval / 3600);
    $goodlines++;
    $lastline = $linetime;
  }

  $cost = $wh / 1000 * $powerprice;

  $whpretty = sprintf("%.2f", $wh);
  $costpretty = sprintf("%.2f", $cost);

  print "$whpretty wh costing $costpretty p\n";
  close CHLOG;
}

$endtime = time();
$runtime = $endtime - $starttime;
print "done $goodlines good lines and $badlines error lines in $runtime seconds with $longgaps instances of missing power log lines\n";

close LOCKFILE;
unlink $lockfile;

