#! /usr/bin/perl -w
#
# leaf-dailystats.pl - parse datafiles from leafspy and currentcost/rtl433
# to generate stats about each day's car use
#
# GH 2017-04-05
# begun
#

no warnings 'once';

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
$lastsec = 0;
$lastmin = 0;
$lasthour = 0;
$lastmday = 0;
$lastmon = 0;
$lastyear = 0;
$lastwday = 0;
$lastyday = 0;
$lastisdst = 0;
while (<CHLOG>)
{
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

  if ( $mday != $lastmday )
  {
    # it's the first line of a new day, so print *yesterday's* data out
    $powertotal = sprintf("%.2f", $powertotal);
    print "$lastyear-$lastmon-$lastmday input power total $powertotal kWh";
    $leafspyfilename = "Log_U6003414_" . substr($lastyear, -2) . $lastmon . $lastmday . "_e8ace.csv";
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
    $gidsstart = $daystartline[5];
    $odokmend = $dayendline[123];
    $gidsend = $dayendline[5];
    $odokmday = $odokmend - $odokmstart;
    $odom = $odokmday * 0.621371;
    $odom = sprintf("%.2f", $odom);
    $gids = $gidsstart - $gidsend;
    $kwhcar = $gids * 80 / 1000;
    $kwhcar = sprintf("%.2f", $kwhcar);
    print " - car power $kwhcar kWh - $odom miles covered";
    if ( $powertotal > 0)
    {
      $mpkwh = $odom / $powertotal;
      $mpkwh = sprintf("%.2f", $mpkwh);
      print " - $mpkwh miles per input kWh";
    }
    if ( $kwhcar > 0)
    {
      $mpkwhcar = $odom / $kwhcar;
      $mpkwhcar = sprintf("%.2f", $mpkwhcar);
      print " - $mpkwhcar miles per car kWh";
    }
    print "\n";
    }
    $powertotal = 0;
  }
  
  if ( ! defined $lastepochtime ) 
  { 
    # first line of file
    $lastepochtime = $epochtime;
    next;
  } 


  $readinggap = $epochtime - $lastepochtime;
    if ( $readinggap > 600)
    {
      print STDERR "WARNING: $readinggap seconds between power meter readings at $epochtime\n";
    }
  $lastepochtime = $epochtime;
  $lastsec = $sec;
  $lastmin = $min;
  $lastmday = $mday;
  $lastmon = $mon;
  $lastyear  = $year;
  $lastwday = $wday;
  $lastyday = $yday;
  $lastisdst = $isdst;

  $powertotal = $powertotal + ($readinggap * $power / 3600000);

}

# the last day we consider, we never get an output from the loop above,
# as the output happens when we see a new day for the first time
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
  $odom = sprintf("%.2f", $odom);
  print " - $odom miles covered";
  if ( $powertotal > 0)
  {
    $mpkwh = $odom / $powertotal;
    $mpkwh = sprintf("%.2f", $mpkwh);
    print " - $mpkwh miles per kWh";
  }
  print " *INCOMPLETE DAY*\n";
}


$endtime = time();
$runtime = $endtime - $starttime;
print "done $goodlines good lines and $badlines error lines in $runtime seconds\n";

close CHLOG;
close LOCKFILE;
unlink $lockfile;


