#! /usr/bin/perl -w
#
# FIXME filename, purpose
#
# GH 2017-04-27
# begun
#

no warnings 'once';

# price of power, pence per kWh
$powerprice = 8.5;
$logdirectory="/data/hm/log";

# appliances to summarise, name of log on-disk

@appliances = ("ccclampcar", "ccclampheat", "ccclampcook", "cciamdryer", "cciamwasher", "cciamfridge", "cciamdwasher", "cciamupsb", "cciamofficedesk", "cciamupso", "cciamtoaster", "cciamkettle");

$lockfile="/tmp/power-dailystats.lock";

if ( -f $lockfile ) 
{
  print "FATAL: lockfile exists, exiting";
  exit 2;
}
open LOCKFILE, ">", $lockfile or die $!;

$timestamp = time();
$starttime = $timestamp;
$goodlines = 0;
$badlines = 0;
$longgaps = 0;

foreach $appliance (@appliances)
{
  print "working on appliance $appliance...\n";
  open APPLOG, "<", "$logdirectory/rtl433-$appliance.log" or die $!;
  $powertotal = 0;
  $daytotal = 0;
  $lastepochtime = 0;
  $badlinesappl = 0;
  $goodlinesappl = 0;
  $longgapsappl = 0;
  $starttimeappl = time();
  while (<APPLOG>)
  {
    @line = split(" ",$_);
    $lineitems = scalar (@line);
    if ( $lineitems != 2 )
    {
      print STDERR "skipped malformed line @line\n";
      $badlinesappl = $badlinesappl + 1;
      next;
    }
    $epochtime = $line[0];
    $power = $line[1];
    if (( $epochtime !~ /\d{10}/ ) || ( $power !~ /\d/ ))
    {
      print STDERR "skipped malformed line @line\n";
      $badlinesappl = $badlinesappl + 1;
      next;
    }
    $goodlinesappl = $goodlinesappl+1;
    ($sec,$min,$hour,$mday,$stupidmon,$stupidyear,$wday,$yday,$isdst) = localtime($epochtime);
    # fucking localtime idiocy, and we need a leading zero on month/day <10
    $mon = $stupidmon + 1;
    $mon = sprintf ("%02d",$mon);
    $year = $stupidyear + 1900;
    $mday = sprintf ("%02d", $mday);

    if ( $lastepochtime == 0 )
    {
      # first line of file
      $lastepochtime = $epochtime;
      $lastyear = $year;
      $lastmon = $mon;
      $lastmday = $mday;
      next;
    }

    if ( $lastmday != $mday )
    {
      # first line of new day, print stats about previous day
      $powertotal = $powertotal + $daytotal;
      $daytotal = sprintf("%.2f", $daytotal);
      print "$lastyear-$lastmon-$lastmday $appliance $daytotal kWh\n";
      $daytotal = 0;
    }

    $readinggap = $epochtime - $lastepochtime;
    if ( $readinggap > 600)
    {
#    print STDERR "WARNING: $readinggap seconds between power meter readings at $epochtime\n";
      $longgapsappl = $longgapsappl + 1;
    }

    $daytotal = $daytotal + ($readinggap * $power / 3600000);
    $lastepochtime = $epochtime;
    $lastyear = $year;
    $lastmon = $mon;
    $lastmday = $mday;

  }
  close APPLOG;
  $lastepochtime = 0;
  $endtime = time();
  $runtimeappl = $endtime - $starttimeappl;
  $powertotal = sprintf("%.2f", $powertotal);
  $goodlines = $goodlines + $goodlinesappl;
  $badlines = $badlines + $badlinesappl;
  $longgaps = $longgaps + $longgapsappl;
  print "$appliance: done $goodlinesappl good lines and $badlinesappl error lines in $runtimeappl seconds with $longgapsappl instances of missing power log lines total power $powertotal kWh\n";
}


$endtime = time();
$runtime = $endtime - $starttime;
print "done $goodlines good lines and $badlines error lines in $runtime seconds with $longgaps instances of missing power log lines\n";

close LOCKFILE;
unlink $lockfile;

exit 0;


=poo

$unchargedday = 0;
$unchargedmiles = 0;
$unchargedkwhcar = 0;
$odom = 0;
$lastpower = 0;
$carriedover = 0;
$goodlines = 0;
$badlines = 0;
$preheatpowertotal = 0;
$powertotal = 0;
$longgaps = 0;
$lastsec = 0;
$lastmin = 0;
$lasthour = 0;
$lastmday = 0;
$lastmon = 0;
$lastyear = 0;
$lastwday = 0;
$lastyday = 0;
$lastisdst = 0;
$lastpowertotal = 0;
$lastodom = 0;

  if ( ! defined $lastepochtime ) 
  { 
    # first line of file
    $lastepochtime = $epochtime;
    next;
  } 


  $readinggap = $epochtime - $lastepochtime;
    if ( $readinggap > 600)
    {
#      print STDERR "WARNING: $readinggap seconds between power meter readings at $epochtime\n";
      $longgaps = $longgaps + 1;
    }

  $powertotal = $powertotal + ($readinggap * $power / 3600000);
  # if the car hasn't been used yet then there won't be any leafspy logs 
  # so it's likely that power use before this time is for pre-heat
  if ( $epochtime < $carstarttime )
    { $preheatpowertotal = $preheatpowertotal + ($readinggap * $power / 3600000); }

  $lastepochtime = $epochtime;
  $lastsec = $sec;
  $lastmin = $min;
  $lastmday = $mday;
  $lastmon = $mon;
  $lastyear  = $year;
  $lastwday = $wday;
  $lastyday = $yday;
  $lastisdst = $isdst;
  $lastpower = $power;
  $lastpowertotal = $powertotal;
  $lastpreheatpowertotal = $preheatpowertotal;
  $lastodom = $odom;

}

# the last day we consider, we never get an output from the loop above,
# as the output happens when we see a new day for the first time
printstats();
print "\n**INCOMPLETE DAY**\n";




sub printstats {
# years before i got the car are bogus lines in log 
if ( $lastyear < 2016 ) { return; }
$powertotal = sprintf("%.2f", $powertotal);
$preheatpowertotal = sprintf("%.2f", $preheatpowertotal); 
$powertobattery = $powertotal - $preheatpowertotal;
$powertobattery = sprintf("%.2f", $powertobattery); 
print "\n$lastyear-$lastmon-$lastmday kWh: $powertotal to car of which $preheatpowertotal pre-heat; $powertobattery for charging\n";
$leafspyfilename = "Log_U6003414_" . substr($lastyear, -2) . $lastmon . $lastmday . "_e8ace.csv";
if ( ! -f "$leafspydirectory/$leafspyfilename" )
{
  print "couldn't find a corresponding leafspy log";
  $odom = 0;
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
  print "car logged $kwhcar kWh from battery for $odom miles";
  if ( $powertotal > 0)
  {
    $mpkwh = $odom / $powertotal;
    $mpkwh = sprintf("%.2f", $mpkwh);
    $ppm = $powerprice / $mpkwh;
    $ppm = sprintf("%.1f", $ppm);
    $chargingefficiency = $kwhcar / ( $powertotal - $preheatpowertotal) * 100;
    $chargingefficiency = sprintf("%.1f", $chargingefficiency);
    print "\n$mpkwh miles/input kWh: ${ppm}p/mile. charge efficiency $chargingefficiency%";
  }
  if ( $kwhcar > 0)
  {
    $mpkwhcar = $odom / $kwhcar;
    $mpkwhcar = sprintf("%.2f", $mpkwhcar);
    print ", $mpkwhcar miles per car kWh";
  }
}
if (( $unchargedday == 1) && ( $powertotal > 0.25))
{
  print "\nadding previous uncharged day/s totals to today:\n";
  $odom = $odom + $unchargedmiles;
  $kwhcar = $kwhcar + $unchargedkwhcar;
  print "total from last charge until today's: car logged $kwhcar kWh from battery for $odom miles";
  
  $mpkwh = $odom / $powertotal;
  $mpkwh = sprintf("%.2f", $mpkwh);
  $ppm = $powerprice / $mpkwh;
  $ppm = sprintf("%.1f", $ppm);
  $chargingefficiency = $kwhcar / ( $powertotal - $preheatpowertotal) * 100;
  $chargingefficiency = sprintf("%.1f", $chargingefficiency);
  print "\n$mpkwh miles/input kWh: ${ppm}p/mile. charge efficiency $chargingefficiency%";
  
  $mpkwhcar = $odom / $kwhcar;
  $mpkwhcar = sprintf("%.2f", $mpkwhcar);
  print ", $mpkwhcar miles per car kWh";
  $unchargedday = 0;
  $unchargedmiles = 0;
  $unchargedkwhcar = 0;
}

if ( $carriedover == 1) 
  { print "\ncharged over midnight boundary - check\n"; }
  print "\n";

} # end of sub
=cut
