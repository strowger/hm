#! /usr/bin/perl -w
#
# leaf-dailystats.pl - parse datafiles from leafspy and currentcost/rtl433
# to generate stats about each day's car use
#
# GH 2017-04-05
# begun
#

no warnings 'once';

# price of power, pence per kWh
$powerprice = 8.5;
$logdirectory="/data/hm/log";
$leafspydirectory="/data/hm/leaf";
$chargerlog="rtl433-ccclampcar.log";
# where charges away from home are recorded (manually)
$chargesdir="/data/hm/leaf/charges";

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
    # find out when driving starts on this day
    $leafspyfilename = "Log_U6003414_" . substr($year, -2) . $mon . $mday . "_e8ace.csv";
    if ( -f "$leafspydirectory/$leafspyfilename" )
    {
      # get the timestamp on the first line
      @daystartline = split(",",`head -2 $leafspydirectory/$leafspyfilename |tail -1`);
      $carstarttime = $daystartline[134];
    }

    # it's the first line of a new day, so print *yesterday's* data out
    # if we're charging on the first line of the day then we're still charging
    # from yesterday, so wait...
    if (( $power > 5) && ($lastpower > 5))
    {
      # still charging
      $carriedover = 1
    }
    else
    {
      printstats();
      if (( $odom > 0) && ( $powertotal < 0.25 ))
      {  
        print "car used but not charged?\n"; 
        $unchargedday = 1;
        $unchargedmiles = $unchargedmiles + $odom;
        $unchargedkwhcar = $unchargedkwhcar + $kwhcar;
      }
      $powertotal = 0;
      $preheatpowertotal = 0;
    }

  }

  # if we carried on charging over the midnight boundary but have now finished
  if (( $carriedover == 1 ) && ( $power < 5 ) && ( $lastpower < 5 ))
  {
    printstats();
    $carriedover = 0;
    $powertotal = 0;
    $preheatpowertotal = 0;
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

$endtime = time();
$runtime = $endtime - $starttime;
print "done $goodlines good lines and $badlines error lines in $runtime seconds with $longgaps instances of missing power log lines\n";

close CHLOG;
close LOCKFILE;
unlink $lockfile;



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
  # charging away from home - manually-added data
  $chargingfilename = $lastyear . $lastmon . $lastmday;
  $kwhaway=0;
  if ( -f "$chargesdir/$chargingfilename")
  {
    $kwhaway=`cat $chargesdir/$chargingfilename`;
    chomp $kwhaway;
    # regex: file must contain only: optional digit/s, optional dot, optional digit/s
    if ($kwhaway =~ /^\d*\.?\d*$/)
    {
      print "car was charged away from home taking $kwhaway kWh\n";
      $powerboth = $kwhaway + $powertotal;
      print "power input for day $powertotal at home, $kwhaway away, total $powerboth\n";
    }
    else { print "malformed away-from-home charging data for day\n"; }
  }
  $kwhcar = $gids * 80 / 1000;
  $kwhcar = sprintf("%.2f", $kwhcar);
  print "car logged $kwhcar kWh from battery for $odom miles";
  if (( $powertotal > 0) && ( ($powertotal - $preheatpowertotal) > 0))
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
