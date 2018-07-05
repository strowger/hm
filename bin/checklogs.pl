#! /usr/bin/perl -w
#
# checklogs.pl - alert on various undesirable conditions in logs
#
# designed to be run periodically from cron and only reports on stdout 
# if error conditions are noted
#
# GH 2015-10-06
# begun
#
$owconfig="/data/hm/conf/1wireread.conf";
$ebconfig="/data/hm/conf/ebusread.conf";
$rrddirectory="/data/hm/rrd";
$logdirectory="/data/hm/log";
$owerrorlog="1wireread-errors.log";
$routererrorlog="router-errors.log";
$alarmsyncerrorlog="alarmbox-rsync-errors.log";
$officesyncerrorlog="office-rsync-errors.log";
$rtlprocesserrorslog="combined-rsync-errors.log";
#$leaferrorlog="leaf-errors.log";
$lockfile="/tmp/checklogs.lock";
#$leafspylog="leafspy.log";

if ( -f $lockfile ) 
{ die "Lockfile exists in $lockfile; exiting"; }

open LOCKFILE, ">", $lockfile or die $!;

open OWCONFIG, "<", "$owconfig" or die $!;
open EBCONFIG, "<", "$ebconfig" or die $!;
$validcount = 0;
$invalidcount = 0;

# hot water cylinder, from ebus
$lastline = `tail -1 $logdirectory/cylindertemp.log`;
($lasttime, $lastval) = split(' ',$lastline);
if ($lastval < 50)
{
  # only alert if the cylinder is cold *and* not being heated up right now
  $lastline = `tail -1 $logdirectory/zvhwflow.log`; 
  ($lasttime, $lastval2) = split(' ',$lastline);
  if ($lastval2 < 50)
  {
#      print "hot water cylinder down to $lastval C and flow temp to tank is $lastval2 C\n"; 
  }
}

# pressure in heating circuit. <1 bar is bad as will draw air in
# not sure what the prv will lift at but we'll alert at 2.6bar
$lastline = `tail -1 $logdirectory/waterpressure.log`;
($lasttime, $lastval) = split(' ',$lastline);                                   
if ($lastval < 1.1)
{ print "water pressure in heating circuit down to $lastval bar\n"; }
if ($lastval > 2.8)
{ print "water pressure in heating circuit up to $lastval bar\n"; }  

# the ebus devices from the config

foreach $line (<EBCONFIG>)
{
  $timestamp = time();                                                          
  # value read from ebus, field, circuit, filename
  ($value, $field, $circuit, $filename) = split(',',$line);
  # starts with hash means comment, so ignore
  if (($value !~ /\#.*/) && (defined $field) && (defined $circuit) && (defined $filename))
  {
    # stuff we just do for each valid config line
    $validcount++;
    chomp $filename;
    if ( ! -f "$rrddirectory/${filename}.rrd" )                                 
    { print "$filename is in $ebconfig but has no RRD file\n"; }                
    if ( ! -f "$logdirectory/${filename}.log" )                                 
    { print "$filename is in $ebconfig but has no logfile\n"; }                 
    # get last line of file - should use File::ReadBackwards really             
    $lastline = `tail -1 $logdirectory/$filename.log`;                          
    ($lasttime, $lastval) = split(' ',$lastline);                               
    chomp $lastval;                                                             
    $lastvalage = $timestamp-$lasttime;                                         
    if ($lastvalage > 600)                                                      
    { print "$filename hasn't updated for $lastvalage seconds\n"; }             
    if ($lastval eq "")                                                         
    { print "$filename has updated with null value\n"; } 
    if ($lastval =~ /error/)
    { print "$filename has an error value\n"; }
  }
  else
  {
    # stuff we just do for each *invalid* config line
    # if the line is invalid and doesn't start with hash, something's wrong     
    if ($value !~ /\#.*/)                                                      
    { $invalidcount++; }  
  }
  # stuff here happens each time regardless
}

if ($invalidcount > 0)                                                          
{ print "$invalidcount invalid un-commented lines in $ebconfig\n"; }  

# the one-wire devices from the config

$validcount = 0;                                                                
$invalidcount = 0;

foreach $line (<OWCONFIG>)
{
  $timestamp = time();
  # device id, value to read, rrd filename
  ($device, $value, $filename) = split(',',$line);
  # starts with hash means comment, so ignore
  if (($device !~ /\#.*/) && (defined $device) && (defined $value) && (defined $filename))
  {
    # here is stuff we just do for each *valid* config line
    $validcount++;
    chomp $filename;
    if ( ! -f "$rrddirectory/${filename}.rrd" )
    { print "$filename is in $owconfig but has no RRD file\n"; }
    if ( ! -f "$logdirectory/${filename}.log" )                                 
    { print "$filename is in $owconfig but has no logfile\n"; }
    # get last line of file - should use File::ReadBackwards really 
    $lastline = `tail -1 $logdirectory/$filename.log`;
    ($lasttime, $lastval) = split(' ',$lastline);
    chomp $lastval;
    $lastvalage = $timestamp-$lasttime;
    if ($lastvalage > 600)
    { print "$filename hasn't updated for $lastvalage seconds\n"; }
    if ($lastval eq "")
    { print "$filename has updated with null value\n"; }
    # humidity sensors have a failure mode where they return values >100
    # but they read up to 100.9999 when it's very damp
#    if (($filename =~ /hum$/) && ($lastval > 101))
#    { print "$filename has invalid humidity value $lastval\n"; }
    # out-of-spec vdd shows a bus problem
#    if (($filename =~ /vdd$/) && ($lastval < 4.7))
#    { print "$filename has low vdd $lastval\n"; }
    # taaralabs thermocouples read this value if they are open-circuit
    if ($lastval == 2047.75)
    { print "$filename has suspicious last value 2047.75 - thermocouple fault?"; }
  }
  else 
  {
    # here is stuff we just do for each *invalid* config line
    # if the line is invalid and doesn't start with hash, something's wrong
    if ($device !~ /\#.*/)
    { $invalidcount++; }
  }
  # stuff here happens each line regardless
}

if ($invalidcount > 0)                                                      
{ print "$invalidcount invalid un-commented lines in $owconfig\n"; } 

# for debug - i don't think we want to actually print unless something is wrong
##print "processed $validcount valid config items, ignored $invalidcount invalid lines\n";

# the currentcost
$timestamp = time();                                                          

# get last line of file - should use File::ReadBackwards really             
$lastline = `tail -1 $logdirectory/power.log`;                          
($lasttime) = split(' ',$lastline);                       
$lastvalage = $timestamp-$lasttime;                                         
if ($lastvalage > 600)                                                       
  { print "currentcost hasn't output for $lastvalage seconds\n"; }                                                                           
# check for 0W values which indicate a currentcost sensor fail of some sort
$cclastzero = `grep \\ 0W $logdirectory/power.log|tail -1`;
($lasttime) = split(' ',$cclastzero);
$lastvalage = $timestamp-$lasttime;                   
##print "currentcost last read zero $lastvalage secs ago\n";                          
if ($lastvalage < 3700)
  { print "currentcost has read zero watts within last hour\n"; }

# whinge if one of the sensors hasn't read for an hour

$cclastopti = `grep opti $logdirectory/power.log|tail -1`;
($lasttime) = split(' ',$cclastopti);
$lastvalage = $timestamp-$lasttime;
##print "currentcost optical sensor last read $lastvalage secs ago\n";
if ($lastvalage > 3700)                                                         
  { print "currentcost optical sensor hasn't read for an hour\n"; } 

# check the kitchen air sensor is logging
$lastline = `tail -1 $logdirectory/airkitchen-co2.log`;
($lasttime) = split(' ',$lastline);
$lastvalage = $timestamp-$lasttime;
if ($lastvalage > 600)
  { print "kitchen air sensor hasn't output for $lastvalage seconds\n"; }

# if there are no owfs errors then that's all good, no need to warn 
# that the file isn't there
if (-f "$logdirectory/$owerrorlog" )
{
  $errorlinecount = 0;
  @errorlines = ();
  open OWERRLOG, "<", "$logdirectory/$owerrorlog" or die $!;
# there are too many errors to print them all every time; print only if there are lots
  foreach $errorline (<OWERRLOG>)
  { 
    $errorlinecount++; 
    push(@errorlines, $errorline);
  }  
  close OWERRLOG;
  if ($errorlinecount > 15)
  {
    print "More than 15 owread runs with errors in last hour:\n";
    print "@errorlines";
  }
  # this might be race-y if the script is running?
  unlink "$logdirectory/$owerrorlog";
}

# same as above but for router errors not owfs errors
if (-f "$logdirectory/$routererrorlog" )
{
  $errorlinecount = 0;
  @errorlines = ();
  open ROUTERERRLOG, "<", "$logdirectory/$routererrorlog" or die $!;
  foreach $errorline (<ROUTERERRLOG>)
  {
    $errorlinecount++;
    push(@errorlines, $errorline);
  }
  close ROUTERERRLOG;
  if ($errorlinecount > 2)
  {
    print "More than 2 snmpget runs with errors in last hour:\n";
    print "@errorlines";
  }
  unlink "$logdirectory/$routererrorlog";
}

# as above for rsync errors with the odroid box in the alarm panel box
# one failure generates 3 error lines
if (-f "$logdirectory/$alarmsyncerrorlog" )
{
  $errorlinecount = 0;
  @errorlines = ();
  open AWRSLOG, "<", "$logdirectory/$alarmsyncerrorlog" or die $!;
  foreach $errorline (<AWRSLOG>)
  {
    $errorlinecount++;
    push(@errorlines, $errorline);
  }
  close AWRSLOG;
  if ($errorlinecount > 5)
  {
    print "More than 5 log lines from alarmpanel rsync cron job:\n";
    print "@errorlines";
  }
  unlink "$logdirectory/$alarmsyncerrorlog";
}


# as above for rsync errors with the office rpi3 box 
# one failure generates 3 error lines
if (-f "$logdirectory/$officesyncerrorlog" )
{
  $errorlinecount = 0;
  @errorlines = ();
  open AWRSLOG, "<", "$logdirectory/$officesyncerrorlog" or die $!;
  foreach $errorline (<AWRSLOG>)
  {
    $errorlinecount++;
    push(@errorlines, $errorline);
  }
  close AWRSLOG;
  if ($errorlinecount > 5)
  {
    print "More than 5 log lines from office rsync cron job:\n";
    print "@errorlines";
  }
  unlink "$logdirectory/$officesyncerrorlog";
}

# these are errors from the script which processes the above rpi rtl433 logs
# $rtlprocesserrorslog

if (-f "$logdirectory/$rtlprocesserrorslog" )
{
  $errorlinecount = 0;
  @errorlines = ();
  open AWRSLOG, "<", "$logdirectory/$rtlprocesserrorslog" or die $!;
  foreach $errorline (<AWRSLOG>)
  {
    $errorlinecount++;
    push(@errorlines, $errorline);
  }
  close AWRSLOG;
  if ($errorlinecount > 5)
  {
    print "More than 5 log lines from rtl433 processing log:\n";
    print "@errorlines";
  }
  unlink "$logdirectory/$rtlprocesserrorslog";
}



# the barompressure2 script which just fetches a url
if (-f "$logdirectory/barompressure2-errors.log" )
{
  $errorlinecount = 0;
  open BAROMLOG, "<", "$logdirectory/barompressure2-errors.log" or die $!;
  foreach $errorline (<BAROMLOG>) { $errorlinecount++; }
  close BAROMLOG;
  if ($errorlinecount > 5)
  {
    print "More than 5 log lines from barompressure2 cron job: ${errorlinecount}\n";
  }
  unlink "$logdirectory/barompressure2-errors.log";
}

@rtlcollectors = ("alarmbox", "office");
foreach $collector (@rtlcollectors)
{
  $timestamp = time();
  $collectorlast = `ls -tr /data/hm/rtl-out/${collector}*log|tail -1`;
  chomp $collectorlast;
  # nb - this is giving us the time created *here* not on the collector box
  $collectortime = (stat("$collectorlast"))[9];
#  print "collector $collector file $collectorlast ctime $collectortime\n";
  $collectorage = $timestamp - $collectortime;
  if ( $collectorage > 600 )
  { 
    print "rtl433 collector $collector last file is $collectorage secs old\n"; 
  }
}

@cciamdevices = ("upsb", "upso", "officedesk", "fridge", "fridge2", "washer", "dryer", "dwasher", "kettle", "toaster", "car2");
foreach $pdev (@cciamdevices)
{
  if (-f "$logdirectory/rtl433-cciam$pdev.log" )
  {
    $timestamp = time();
    $lastline = `tail -1 $logdirectory/rtl433-cciam$pdev.log`;
    ($lasttime) = split(' ',$lastline);
    $lastvalage = $timestamp-$lasttime;
#### this is too spammy for now
####    if ( $lastvalage > 900)
####      { print "power device $pdev last read $lastvalage seconds ago\n"; }
#    # they tx every 6 seconds so this should catch a minimum of an hour
#    $fileend = `tail -600 $logdirectory/rtl433-cciam$pdev.log`;
#    @fileendar = split ('\n',$fileend);
#    $longgaps = 0;
#    $lasttime = 0;
#    foreach (@fileendar)
#    {
#      ($linetime, $lineval)  = split (' ',$_);
#      # first line of file
#      if ( $lasttime == 0 ) { $lasttime = $linetime; }
#      $interval = $linetime - $lasttime;
#      if ( $interval > 600 ) { $longgaps = $longgaps + 1; }
#      $lasttime = $linetime;
#    }
#    if ( $longgaps > 1 )
#      { print "power device $pdev had $longgaps long gaps between reads\n"; }
  }
  else { print "log for power device $pdev missing\n"; }
}

@ccclampdevices = ("car", "heat", "cook", "towelrail");
foreach $pdev (@ccclampdevices)
{
  if (-f "$logdirectory/rtl433-ccclamp$pdev.log" )
  {
    $timestamp = time();
    $lastline = `tail -1 $logdirectory/rtl433-ccclamp$pdev.log`;
    ($lasttime) = split(' ',$lastline);
    $lastvalage = $timestamp-$lasttime;
    if ( $lastvalage > 900)
      { print "power device $pdev last read $lastvalage seconds ago\n"; }
#    # they tx every 6 seconds so this should catch a minimum of an hour
#    $fileend = `tail -600 $logdirectory/rtl433-ccclamp$pdev.log`;
#    @fileendar = split ('\n',$fileend);
#    $longgaps = 0;
#    $lasttime = 0;
#    foreach (@fileendar)
#    {
#      ($linetime, $lineval)  = split (' ',$_);
#      # first line of file
#      if ( $lasttime == 0 ) { $lasttime = $linetime; }
#      $interval = $linetime - $lasttime;
#      if ( $interval > 600 ) { $longgaps = $longgaps + 1; }
#      $lasttime = $linetime;
#    }
#    if ( $longgaps > 1 )
#      { print "power device $pdev had $longgaps long gaps between reads\n"; }
  }
  else { print "log for power device $pdev missing\n"; }
}

# 20181021 leaf is gone
## same as above but for nissan leaf monitoring errors - we only poll 4 times
## per hour so for now we care if we get even a single one - later we'll care 
## less and probably reduce this
#
#if (-f "$logdirectory/$leaferrorlog" )
#{
#  $errorlinecount = 0;
#  @errorlines = ();
#  open LEAFERRLOG, "<", "$logdirectory/$leaferrorlog" or die $!;
#  foreach $errorline (<LEAFERRLOG>)
#  {
#    $errorlinecount++;
#    push(@errorlines, $errorline);
#  }
#  close LEAFERRLOG;
#  if ($errorlinecount > 2)
#  {
#    print "More than 2 leaf.pl runs with errors in last hour:\n";
#    print "@errorlines";
#  }
#  unlink "$logdirectory/$leaferrorlog";
#}
#
## the leafspy log import script runs every minute and exits silently if a
##  lockfile exists - we just alert here if it hasn't run successfully recently
#
#$timestamp = time();
#$leaflast = `grep exiting $logdirectory/$leafspylog|tail -1|awk '{print \$3}'`;
#$lastvalage = $timestamp-$leaflast;
#if ($lastvalage > 1200)
#{
#  print "leafspy import script hasn't run successfully for 20 minutes";
#}

# disk space - assumes we're just using /root
# from df loses a space
$diskpercentused = `df -Ph|grep root|cut -d " " -f 10 |sed "s/\%//"`;
chomp $diskpercentused;
if ($diskpercentused > 85)
  { print "Disk utilisation ${diskpercentused}%"; }


# 20180429 
# check/correct date/time in central heating
# this used to maintain itself, perhaps a backup battery failed?
$vfulldate = `/usr/bin/ebusctl read -f -c 470 date`;
# it's got 2 carriage returns after it
chomp $vfulldate; chomp $vfulldate;
if (($vfulldate =~ /error/ ) || ($vfulldate =~ /ERR/ ))
  { print "got error trying to read date from central heating\n"; }
else
{
  ($vday,$vmonth,$vyear) = split(/\./, $vfulldate);
#  print "vaillant year $vyear month $vmonth day $vday\n";
  $year = `/usr/bin/date +%Y`;
  chomp $year;
  $month = `/usr/bin/date +%m`;
  chomp $month;
  $day = `/usr/bin/date +%d`;
  chomp $day;
 
#  print "system year $year month $month day $day\n";
 
  if (($year eq $vyear) && ($month eq $vmonth) && ($day eq $vday))
  { 
#    print "date is good!\n"
  }
  else
  {
    # we could be racing ebusread so go slow
    sleep 1;
    print "central heating date wrong - setting to $day $month $year\n";
    $output = `/usr/bin/ebusctl write -c 470 date $day.$month.$year`;
    if (($output =~ /error/ ) || ($output =~ /ERR/ ))
      { print "got error trying to write date to central heating\n"; }
  }
}
# again we could be racing so go slow
sleep 1;
$vfulltime = `/usr/bin/ebusctl read -f -c 470 time`;
# it's got 2 carriage returns after it
chomp $vfulltime; chomp $vfulltime;
if (($vfulltime =~ /error/ ) || ($vfulltime =~ /ERR/ ))
  { print "got error trying to read time from central heating\n"; }
else
{
#  print "full $vfulltime\n";
  ($vhour,$vmin,$vsec) = split(/:/, $vfulltime);
# just avoid the 'only used once'
  chomp $vsec;
#  print "vaillant hour $vhour minute $vmin second $vsec\n";
  $hour = `/usr/bin/date +%H`;
  chomp $hour;
  $min = `/usr/bin/date +%M`;
  chomp $min;

#  print "system hour $hour minute $min\n";
  if (($min eq $vmin) && ($hour eq $vhour))
  {
#    print "time is good!\n";
  }
  else
  {
    sleep 1;
    # we didn't obtain this earlier for comparison
    $sec = `/usr/bin/date +%S`;
    chomp $sec;
    print "central heating time wrong - setting to $hour $min $sec\n";
    $output = `/usr/bin/ebusctl write -c 470 time $hour:$min:$sec`;
    if (($output =~ /error/ ) || ($output =~ /ERR/ ))
      { print "got error trying to write time to central heating\n"; }
  }
}


close LOCKFILE;
unlink $lockfile;


