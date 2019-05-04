#! /usr/bin/perl -w
#
# boiler-power-bodge.pl - calculate a value for boiler gas consumption
# using the modulation percentage, and write it to influx
# reduce it to zero when the fire isn't actually lit
#
# GH 2019-05-04
# begun
#
$logdirectory="/data/hm/log";

$logfile="boiler-power-bodge.log";
$lockfile="/tmp/boiler-power-bodge-lock";
$influxcmd="curl -s -S -i -XPOST ";
$influxurl="http://localhost:8086/";
$influxdb="styes_ebus";

if ( -f $lockfile ) 
{
  die "Lockfile exists in $lockfile; exiting";
}

open LOCKFILE, ">", $lockfile or die $!;

open LOGFILE, ">>", "$logdirectory/$logfile" or die $!;

$timestamp = time();

# although named very badly, this is the boiler modulation in percent
# unfortunately it doesn't read 0 when the fire is out, it continues to
# read the previous value
$logmod="modtempdesired.log";
$timelastmod=`tail -1 $logdirectory/$logmod|awk '{print \$1}'`;
$lastlogmod=`tail -1 $logdirectory/$logmod|awk '{print \$2}'`;
chomp $timelastmod;
chomp $lastlogmod;
# flame ionisation volts is how we detect whether the fire is lit
$logion="ionisationvolts.log";
$timelastion=`tail -1 $logdirectory/$logion|awk '{print \$1}'`;
$lastlogion=`tail -1 $logdirectory/$logion|awk '{print \$2}'`;
chomp $timelastion;
chomp $lastlogion;
# when did we last run and what numbers did we get
# obviously introduces a bug that we need to manually make a log for first run
#$timelastrun=`tail -1 $logdirectory/$logfile|awk '{print \$1}'`;
$lastrun=`tail -1 $logdirectory/$logfile|awk '{print \$2}'`;
#chomp $timelastrun;
chomp $lastrun;

#$timesincelastlog = $timestamp - $timelastrun;

$timesincelastion = $timestamp - $timelastion;
$timesincelastmod = $timestamp - $timelastmod;

# if the ebusread process isn't managing to update these logfiles for
# whatever reason then we should just exit, other alerting will let
# us know it's broken, and filling our log up with stale data isn't useful

if (( $timesincelastion > 120 ) || ( $timesincelastmod > 120 ))
{
  close LOGFILE;
  close LOCKFILE;
  unlink $lockfile;
  exit 0;
}

# we arbitrarily say that ionisation volts < 65 means the fire is lit
# it's generally around 80 when the fire is out and perhaps 20-50
# depending on modulation when lit



if ( $lastlogion < 65 )
{
  # boiler is lit so calculate kWh and log it if we haven't recently
  # print "the fire is lit\n";
  $powerkw = $lastlogmod * 0.22385;
  print LOGFILE "$timestamp $powerkw\n";
  `${influxcmd} '${influxurl}write?db=${influxdb}' --data-binary 'boiler_power_bodge value=${powerkw} ${timestamp}000000000\n'` or warn "Could not run curl because $!\n";
}
else
{
  # boiler is not lit so log zero 
  print LOGFILE "$timestamp 0\n";
  `${influxcmd} '${influxurl}write?db=${influxdb}' --data-binary 'boiler_power_bodge value=0 ${timestamp}000000000\n'` or warn "Could not run curl because $!\n";
}

close LOGFILE;
close LOCKFILE;
unlink $lockfile;
