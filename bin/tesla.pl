#! /usr/bin/perl -w
#
# tesla.pl - run teslacmd from teslams (https://github.com/hjespers/teslams)
# to retrieve data from tesla and add to log/rrd
#
# designed to be run from cron
#
# GH 2018-01-15
# begun (heavily derived from leaf.pl)
#
$rrddirectory="/data/hm/rrd";
$logdirectory="/data/hm/log";
$logfile="tesla.log";
#$errorlog="tesla-errors.log";
$teslacmd="/usr/bin/teslacmd";
$config="/data/hm/conf/tesla.conf";
# where the shit that comes out of the teslacmd program goes, will probably end up
# erasing this quite frequently
$templogfile="teslatemp.log";
$lockfile="/tmp/tesla.lock";


$influxcmd="curl -s -S -i -XPOST ";
$influxurl="http://localhost:8086/";
$influxdb="tesla_api";

if ( -f $lockfile )
{
  die "Lockfile exists in $lockfile; exiting";
}

open LOCKFILE, ">", $lockfile or die $!;

$timestamp = time();
$starttime = $timestamp;

open LOGFILE, ">>", "$logdirectory/$logfile" or die $!;
#open ERRORLOG, ">>", "$logdirectory/$errorlog" or die $!;
open TEMPLOGFILE, ">>", "$logdirectory/$templogfile" or die $!;
open CONFIG, "<", "$config" or die $!;

print LOGFILE "starting tesla.pl at $timestamp\n";
print TEMPLOGFILE "starting tesla.pl at $timestamp\n";

foreach $configline (<CONFIG>)
{
  # this is really just to keep the credentials out of git
  ($username,$password,$cammac) = split(',',$configline);
  if (($username !~ /\#.*/) && (defined $password) && (defined $cammac))
  {
    chomp $password;
    print LOGFILE "$timestamp: read username, password, and mac from config\n";
  }
}

close CONFIG;

# find out if the car was home last time we polled
$lasthomeline = `tail -1 $logdirectory/teslahome.log`;
($lasthometime, $lasthome) = split(" ",$lasthomeline);
undef $lasthometime;
open LINE, ">>", "$logdirectory/teslahome.log" or die $!;
# check for the presence of the car (or rather, the mac of the front dashcam)
$camcheck = `ssh office /sbin/iwlist wlan1 scan |grep ${cammac}`;
# if we successfully ssh'd and found the cam we'll have its mac in the grep
# output, otherwise we'll get nothing (or an error)
if ( $camcheck =~ /$cammac/ )
{
  print LOGFILE "$timestamp: dashcam present\n";
  print LINE "$timestamp home\n";
}
else
{
  print LOGFILE "$timestamp: dashcam absent\n";
  print LINE "$timestamp away\n";
}
close LINE;

# when did we last get data and what was the state?
# 'Charging' 'Disconnected' 'Complete' 'Stopped' 'Starting' 'NoPower'
# if we weren't "Charging" or "Starting" then we're wasting battery polling if
# the car isn't being used, so we need to let it sleep
$laststateline = `tail -1 $logdirectory/teslastate.log`;
($laststatetime, $laststate) = split(" ",$laststateline);
#print "DEBUG: last state time $laststatetime last state $laststate\n";
undef $laststatetime;
# first check: is the car in a non-charging state?
if (( $laststate =~ /Disconnected/) || ($laststate =~ /Stopped/) || ($laststate =~ /Complete/))
{
##  print "DEBUG: first check - in a non-charging state\n";
  # second check: has the car just arrived or departed home?
  # ie, has the camera's mac address appeared or disappeared?
##  print "DEBUG: pre second check - camcheck $camcheck lasthome $lasthome\n";
  if ( ( $camcheck =~ /$cammac/ and  $lasthome eq "home")
     or ( ! $camcheck =~ /$cammac/ and $lasthome eq "away"))
  {
##    print "DEBUG: second check - cam consistently present or away\n";
    # third check: is the battery (dis)charging?
    $last3batterystates = `tail -3 $logdirectory/teslabatterylevel.log`;
    ($time1, $state1, $time2, $state2, $time3, $state3) = split(" ",$last3batterystates);
##    print "DEBUG: pre third check: battery levels $state1 $state2 $state3\n";
    # supress run-time warnings about variables only used once
    undef $time1;
    undef $time2;
    if (($state1 == $state2) && ($state2 == $state3))
    {
##      print "DEBUG: third check - last 3 battery charge percentages all same\n";
      # battery status was the same for the last 3 polls
      $interval = $timestamp - $time3;
      # fourth check: is it <40min since last poll?
      if ($interval < 2400)
      {
##        print "DEBUG: fourth check - last poll <40min ago\n";
        print LOGFILE "car seems idle and last poll <40min ago, quitting to permit sleep\n";
        close LOGFILE;
        close LOCKFILE;
        unlink $lockfile;
        exit 0;
      }
    }
  }
}

# -Z 1: error if car is asleep and don't continue
# -c: display charge state
$teslacmdoutput = `$teslacmd -u ${username} -p ${password} -Z 1 -c >&1`;
print TEMPLOGFILE "$teslacmdoutput\n";
# splitting on space splits on any kind of whitespace incl newline
@tc = split(" ",$teslacmdoutput);

if (( $tc[0] =~ /Error/ ) || ( $tc[1] =~ /Error/ ))
{ 
  print LOGFILE "Got error from tesla api, aborting";
  if ( $tc[5] =~ /asleep/ )
  { print LOGFILE " - car asleep"; }
  print LOGFILE "\n\n";
  close LOCKFILE;
  unlink $lockfile;
  exit 1;
}

# api for v8
if ( $tc[1] =~ /charging_state/ )
{
  $api_version = "v8";
  # these values are all followed by a comma
  # "disconnected" etc
  chop $tc[2]; $chargingstate = $tc[2];
  # what max percent to charge to is
  chop $tc[8]; $chargelimit = $tc[8];
  # number of times charged to max?
  chop $tc[18]; $maxrangecharges = $tc[18];
  # "battery range", "est battery range", "ideal battery range" 
  chop $tc[22]; $batteryrange = $tc[22];
  chop $tc[24]; $estbatteryrange = $tc[24];
  chop $tc[26]; $idealbatteryrange = $tc[26];
  # soc!
  chop $tc[28]; $batterylevel = $tc[28];
  chop $tc[30]; $batterylevelusable = $tc[30];
  chop $tc[32]; $chargenergyadded = $tc[32];
  chop $tc[38]; $chargervoltage = $tc[38];
  if ( $chargervoltage eq "null" ) { $chargervoltage = 0; }
  chop $tc[40]; $chargercurrentpilot = $tc[40];
  if ( $chargercurrentpilot eq "null" ) { $chargercurrentpilot = 0; }
  chop $tc[42]; $chargercurrentactual = $tc[42];
  if ( $chargercurrentactual eq "null" ) { $chargercurrentactual = 0; }
  chop $tc[44]; $chargerpower = $tc[44];
  chop $tc[50]; $chargerate = $tc[50];
}

# api for v9
if ( $tc[1] =~ /battery_heater_on/ )
{
  $api_version = "v9";
  chop $tc[46]; $chargingstate = $tc[46];
  # what max percent to charge to is
  chop $tc[16]; $chargelimit = $tc[16];
  # number of times charged to max?
  chop $tc[66]; $maxrangecharges = $tc[66];
  # "battery range", "est battery range", "ideal battery range" 
  chop $tc[6]; $batteryrange = $tc[6];
  chop $tc[50]; $estbatteryrange = $tc[50];
  chop $tc[58]; $idealbatteryrange = $tc[58];
  # soc!
  chop $tc[4]; $batterylevel = $tc[4];
  chop $tc[80]; $batterylevelusable = $tc[80];
  chop $tc[14]; $chargenergyadded = $tc[14];
  chop $tc[44]; $chargervoltage = $tc[44];
  if ( $chargervoltage eq "null" ) { $chargervoltage = 0; }
  chop $tc[40]; $chargercurrentpilot = $tc[40];
  if ( $chargercurrentpilot eq "null" ) { $chargercurrentpilot = 0; }
  chop $tc[36]; $chargercurrentactual = $tc[36];
  if ( $chargercurrentactual eq "null" ) { $chargercurrentactual = 0; }
  chop $tc[42]; $chargerpower = $tc[42];
  chop $tc[32]; $chargerate = $tc[32];
}

if ( $api_version eq "" ) { die "unknown api version\n"; }

print LOGFILE "charging state $chargingstate, max charge percent $chargelimit, max range charges count $maxrangecharges\n";
print LOGFILE "battery range/est/ideal $batteryrange $estbatteryrange $idealbatteryrange battery level/usable $batterylevel $batterylevelusable\n";
print LOGFILE "charge energy added $chargenergyadded voltage $chargervoltage current pilot/actual $chargercurrentpilot $chargercurrentactual\n";
print LOGFILE "charger power $chargerpower rate $chargerate\n";

# we can use this to work out whether to keep polling or let the car sleep
open LINE, ">>", "$logdirectory/teslastate.log" or die $!;
print LINE "$timestamp $chargingstate\n";
close LINE;

open LINE, ">>", "$logdirectory/teslachargelimit.log" or die $!;
print LINE "$timestamp $chargelimit\n";
close LINE;
`${influxcmd} '${influxurl}write?db=${influxdb}' --data-binary 'chargelimit value=${chargelimit} ${timestamp}000000000\n'` or warn "Could not run curl because $!\n";
if ( -f "$rrddirectory/teslachargelimit.rrd" )
{
  $output = `rrdtool update $rrddirectory/teslachargelimit.rrd $timestamp:$chargelimit`;
  if (length $output) { print LOGFILE "rrdtool errored $output\n"; }
}
else
  { print LOGFILE "rrd for teslachargelimit doesn't exist, skipping update\n"; }

open LINE, ">>", "$logdirectory/teslabatterylevel.log" or die $!;
print LINE "$timestamp $batterylevel\n";
close LINE;
`${influxcmd} '${influxurl}write?db=${influxdb}' --data-binary 'batterylevel value=${batterylevel} ${timestamp}000000000\n'` or warn "Could not run curl because $!\n";
if ( -f "$rrddirectory/teslabatterylevel.rrd" )
{
  $output = `rrdtool update $rrddirectory/teslabatterylevel.rrd $timestamp:$batterylevel`;
  if (length $output) { print LOGFILE "rrdtool errored $output\n"; }
}
else
  { print LOGFILE "rrd for teslabatterylevel doesn't exist, skipping update\n"; }

open LINE, ">>", "$logdirectory/teslabatterylevelusable.log" or die $!;
print LINE "$timestamp $batterylevelusable\n";
close LINE;
`${influxcmd} '${influxurl}write?db=${influxdb}' --data-binary 'batterylevel_usable value=${batterylevelusable} ${timestamp}000000000\n'` or warn "Could not run curl because $!\n";
if ( -f "$rrddirectory/teslabatterylevelusable.rrd" )
{
  $output = `rrdtool update $rrddirectory/teslabatterylevelusable.rrd $timestamp:$batterylevelusable`;
  if (length $output) { print LOGFILE "rrdtool errored $output\n"; }
}
else
  { print LOGFILE "rrd for teslabatterylevelusable doesn't exist, skipping update\n"; }

open LINE, ">>", "$logdirectory/teslachargevolts.log" or die $!;         
print LINE "$timestamp $chargervoltage\n";                                  
close LINE;
`${influxcmd} '${influxurl}write?db=${influxdb}' --data-binary 'charging_volts value=${chargervoltage} ${timestamp}000000000\n'` or warn "Could not run curl because $!\n";                                                                     
if ( -f "$rrddirectory/teslachargevolts.rrd" )                           
{                                                                               
  $output = `rrdtool update $rrddirectory/teslachargevolts.rrd $timestamp:$chargervoltage`;                                                       
  if (length $output) { print LOGFILE "rrdtool errored $output\n"; }            
}                                                                               
else                                                                            
  { print LOGFILE "rrd for teslachargevolts doesn't exist, skipping update\n"; }

open LINE, ">>", "$logdirectory/teslachargeamps.log" or die $!;
print LINE "$timestamp $chargercurrentactual\n";
close LINE;
`${influxcmd} '${influxurl}write?db=${influxdb}' --data-binary 'charging_amps_actual value=${chargercurrentactual} ${timestamp}000000000\n'` or warn "Could not run curl because $!\n";
if ( -f "$rrddirectory/teslachargeamps.rrd" )
{ 
  $output = `rrdtool update $rrddirectory/teslachargeamps.rrd $timestamp:$chargercurrentactual`;
  if (length $output) { print LOGFILE "rrdtool errored $output\n"; }
}
else 
{ print LOGFILE "rrd for teslachargeamps doesn't exist, skipping update\n"; }

$endtime = time();

$runtime = $endtime - $starttime;

print LOGFILE "tesla.pl ran for $runtime seconds\n";
print LOGFILE "exiting successfully\n\n";

close LOCKFILE;
unlink $lockfile;
