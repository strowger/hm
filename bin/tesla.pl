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
  ($username,$password) = split(',',$configline);
  if (($username !~ /\#.*/) && (defined $password))
  {
    chomp $password;
    print LOGFILE "$timestamp: read username and password from config\n";
  }
}

close CONFIG;
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
  print LOGFILE "\n";
  close LOCKFILE;
  unlink $lockfile;
  exit 1;
}

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

print LOGFILE "charging state $chargingstate, max charge percent $chargelimit, max range charges count $maxrangecharges\n";
print LOGFILE "battery range/est/ideal $batteryrange $estbatteryrange $idealbatteryrange battery level/usable $batterylevel $batterylevelusable\n";
print LOGFILE "charge energy added $chargenergyadded voltage $chargervoltage current pilot/actual $chargercurrentpilot $chargercurrentactual\n";
print LOGFILE "charger power $chargerpower rate $chargerate\n";

open LINE, ">>", "$logdirectory/teslachargelimit.log" or die $!;
print LINE "$timestamp $chargelimit\n";
close LINE;
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
