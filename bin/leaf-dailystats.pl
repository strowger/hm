#! /usr/bin/perl -w
#
# leaf-dailystats.pl - parse datafiles from leafspy and currentcost/rtl433
# to generate stats about each day's car use
#
# GH 2017-04-05
# begun
#

no warnings 'once';

## for calculating epoch from logfile values
#use Time::Local;

$logdirectory="/data/hm/log";
$leafspydirectory="/data/hm/leaf";
$chargerlog="rtl433-ccclamp.log";

$lockfile="/tmp/leaf-dailystats.lock";

if ( -f $lockfile ) 
{
  print "FATAL: lockfile exists, exiting";
  exit 2;
}
open LOCKFILE, ">", $lockfile or die $!;

open CHLOG, "<", "$logdirectory/$chargerlog";

$timestamp = time();
$starttime = $timestamp;

$goodlines = 0;
$badlines = 0;
$powertotal = 0;
$lastlineday = 0;
while (<CHLOG>)
{
# get date and time
# get value
# time between readings
# is it new day? if so print somethign

  @line = split(" ",$_);
  $lineitems = scalar (@line);
  if ( $lineitems != 2 )
  {
    print STDERR "skipped malformed line @line\n";
    $badlines = $badlines + 1;
    next;
  }
  $epochtime = $line[0];
  $power = $line[1];
  if (( $epochtime !~ /\d{10}/ ) || ( $power !~ /\d/ ))
  {
    print STDERR "skipped malformed line @line\n";
    $badlines = $badlines + 1;
    next;
  }
  $goodlines = $goodlines+1;
  ($sec,$min,$hour,$mday,$stupidmon,$stupidyear,$wday,$yday,$isdst) = localtime($epochtime);
  # fucking localtime idiocy, and we need a leading zero on month/day <10
  $mon = $stupidmon + 1;
  $mon = sprintf ("%02d",$mon);
  $year = $stupidyear + 1900;
  $mday = sprintf ("%02d", $mday);

  if ( $mday != $lastlineday )
  {
    # it's the first line of a new day
    $powertotal = sprintf("%.2f", $powertotal);
    print "$year-$mon-$mday power total $powertotal kWh";
    $leafspyfilename = "Log_U6003414_" . substr($year, -2) . $mon . $mday . "_e8ace.csv";
    if ( ! -f "$leafspydirectory/$leafspyfilename" )
    {
      print " - couldn't find a corresponding leafspy log\n";
    }
    else
    {
    # get the odometer value from first and last lines
    @daystartline = split(",",`head -2 $leafspydirectory/$leafspyfilename |tail -1`);
    @dayendline = split(",",`tail -1 $leafspydirectory/$leafspyfilename`);
    $odokmstart = $daystartline[123];
    $odokmend = $dayendline[123];
    $odokmday = $odokmend - $odokmstart;
    $odom = $odokmday * 0.621371;
    print " - $odom miles covered";
    if ( $powertotal > 0)
    {
      $mpkwh = $odom / $powertotal;
      print " - $mpkwh miles per kWh";
    }
    print "\n";
    }
    $powertotal = 0;
  }
  $lastlineday = $mday;
  
  if ( ! defined $lastepochtime ) 
  { 
    # first line of file
    $lastepochtime = $epochtime;
    next;
  } 
 
  $readinggap = $epochtime - $lastepochtime;
  $lastepochtime = $epochtime;

  $powertotal = $powertotal + ($readinggap * $power / 3600000);

}

# the last day we consider, we never get an output from the loop above,
# as the output happens when we see a new day for the first time
$powertotal = sprintf("%.2f", $powertotal);
print "$year-$mon-$mday power total $powertotal kWh *incomplete day*\n";

$endtime = time();
$runtime = $endtime - $starttime;
print "done $goodlines good lines and $badlines error lines in $runtime seconds\n";
close LOCKFILE;
unlink $lockfile;


