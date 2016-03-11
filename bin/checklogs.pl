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
$lockfile="/tmp/checklogs.lock";

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
{ print "hot water cylinder down to $lastval C\n"; }

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

$cclastclamp = `grep clamp $logdirectory/power.log|tail -1`;                    
($lasttime) = split(' ',$cclastclamp);                                          
$lastvalage = $timestamp-$lasttime;                                             
##print "currentcost clamp sensor last read $lastvalage secs ago\n";  
if ($lastvalage > 3700)                                                         
{ print "currentcost clamp sensor hasn't read for an hour\n"; }

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
  if ($errorlinecount > 9)
  {
    print "More than 9 owread runs with errors in last hour:\n";
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
    print "More than 2 owread runs with errors in last hour:\n";
    print "@errorlines";
  }
  unlink "$logdirectory/$routererrorlog";
}

close LOCKFILE;
unlink $lockfile;


