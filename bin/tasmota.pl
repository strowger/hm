#! /usr/bin/perl -w
#
# tasmota.pl - read values from tasmota devices and save to log/influxdb
# recycled from hs100.pl
#
# GH 2019-11-21
#
$config="/data/hm/conf/tasmota.conf";
$logdirectory="/data/hm/log";
$logfile="tasmota.log";
$errorlog="tasmota-errors.log";
$lockfile="/tmp/tasmota.lock";
# while we try to work out what makes it freeze
$debuglog="tasmota-debug.log";

$influxcmd="curl -s -S -i -XPOST ";
$influxurl="http://localhost:8086/";
$influxdb="styes_power";

# because we're grep'ing through the stderr+stio output together and we'll get nowt if there's an error
no warnings 'uninitialized';

open ERRORLOG, ">>", "$logdirectory/$errorlog" or die $!;

if ( -f $lockfile ) 
{
  print ERRORLOG "FATAL: lockfile exists, exiting\n";
  exit 2;
}

open LOCKFILE, ">", $lockfile or die $!;

$timestamp = time();
$starttime = $timestamp;

open LOGFILE, ">>", "$logdirectory/$logfile" or die $!;

print LOGFILE "starting tasmota at $timestamp\n";

open CONFIG, "<", "$config" or die $!;

# count of invalid config file lines
$invalidcount = 0;
# count of devices which gave errors during reading
$errorcount = 0;
# count of devices we've successfully read
$validcount = 0;
@errordevices = ();

foreach $line (<CONFIG>)
{
  $timestamp = time();
# device id, name for log/influx, type
  ($device, $name, $type, $ip, $mac) = split(',',$line);
  # starts with hash means comment, so ignore
  # ignore if there isn't a value for all vital items
  if (($device !~ /\#.*/) && (defined $device) && (defined $name) && (defined $type) && (defined $ip) && (defined $mac))
  {
    # here is stuff we just do for each *valid* config line
    chomp $mac;
    print LOGFILE "$timestamp: reading $device $name $type $ip: ";
    if ( $type ne "plug" )
    {
      print LOGFILE "unknown type $type, skipping\n";
      next;
    }
    # if we've never spoken to the device before, it won't be in the arp table and so this check fails
##    $timestamp = time();
##    `echo "$timestamp about to ping ${ip}" >> ${logdirectory}/${debuglog}`;
##    `/usr/bin/ping -c1 -w 1 -W 1 ${ip} >> ${logdirectory}/${debuglog} 2>> ${logdirectory}/${debuglog}`;
    `/usr/bin/ping -c1 -w 1 -W 1 ${ip} > /dev/null 2>/dev/null`;
##    $timestamp = time();
##    `echo "$timestamp about to check arp cache for ${ip}" >> ${logdirectory}/${debuglog}`;
##    $output = `/usr/sbin/arp -n|grep ${mac}|tee -a ${logdirectory}/${debuglog}`;
    $output = `/usr/sbin/arp -n|grep ${mac}`;
    if ( $output !~ /${ip}/ )
    {
      print LOGFILE "couldn't find ip $ip with mac $mac in arp table, skipping\n";
      $errorcount++;
      push(@errordevices, $device);
      next;
    }
    $timestamp = time();
##    `echo "${timestamp} about to curl to ${ip}" >> ${logdirectory}/${debuglog}`;
##    $output = `curl -m2 --connect-timeout 2 -s -S http://${ip}/cm?cmnd=status%208 |tee -a ${logdirectory}/${debuglog} 2>&1`;
    $output = `curl -m2 --connect-timeout 2 -s -S http://${ip}/cm?cmnd=status%208 2>&1`;
##    `echo >> ${logdirectory}/${debuglog}`;
##    $timestamp = time();
##    `echo "${timestamp} done curl to ${ip}" >> ${logdirectory}/${debuglog}`;
    # test curl return code
    if ( $? > 0 ) 
    { 
      `echo "trapped a curl error on ${ip}" >> ${logdirectory}/${debuglog}.log`;
      print LOGFILE "got error from curl - not saving\n";
      $errorcount++;
      push(@errordevices, $device); 
    }
    else
    {
      $timestamp = time();
##      `echo "${timestamp} starting normal curl output processing on ${ip}" >> ${logdirectory}/${debuglog}`;
      # continue processing curl output
      @outputline = split(":", $output);
      # the split returns an array, we only want the first value hence brackets
      ($kwhtotal)=split(",", $outputline[9]);
      ($kwhyest)=split(",", $outputline[10]);
      ($kwhtoday)=split(",", $outputline[11]);
      # in watts
      ($power)=split(",",$outputline[12]);
      # in va
      ($apparentpower)=split(",",$outputline[13]);
      # in var
      ($reactivepower)=split(",",$outputline[14]);
      ($powerfactor)=split(",",$outputline[15]);
      ($volts)=split(",",$outputline[16]);
      # amps is the last item on the line and has 3 brackets after it
      ($ampstemp)=split(",",$outputline[17]);
      ($amps)=split("}",$ampstemp);
      print LOGFILE "kwh - total $kwhtotal yesterday $kwhyest today $kwhtoday powers w $power apparent $apparentpower reactive $reactivepower factor $powerfactor volts $volts amps $amps\n";
   
      # /\d+\.?\d*/ - 1 or more digits, optional dot, zero or more digits

      if (($kwhtotal !~ /\d+\.?\d*/) || ($kwhyest !~ /\d+\.?\d*/) || ($kwhtoday !~ /\d+\.?\d*/) || ($power !~ /\d+\.?\d*/) || ($apparentpower !~ /\d+\.?\d*/) || ($reactivepower !~ /\d+\.?\d*/) || ($powerfactor !~ /\d+\.?\d*/) || ($volts !~ /\d+\.?\d*/) || ($amps !~ /\d+\.?\d*/))
      {
        print LOGFILE "$timestamp got a non-numeric value, skipping\n";
        print ERRORLOG "$timestamp got a non-numeric value, skipping\n";
        next;
      }

      open LINE, ">>", "$logdirectory/tasmota-$name.log" or die $!;
      print LINE "$timestamp v $volts a $amps w $power va $apparentpower var $reactivepower pf $powerfactor kwhtotal $kwhtotal kwhtoday $kwhtoday\n";
      close LINE;
      `${influxcmd} '${influxurl}write?db=${influxdb}' --data-binary 'tasmota-${name}-voltage value=${volts} ${timestamp}000000000\n tasmota-${name}-current value=${amps} ${timestamp}000000000\n tasmota-${name}-power value=${power} ${timestamp}000000000\n tasmota-${name}-apparentpower value=${apparentpower} ${timestamp}000000000\n tasmota-${name}-reactivepower value=${reactivepower} ${timestamp}000000000\n tasmota-${name}-powerfactor value=${powerfactor} ${timestamp}000000000\n'` or warn "Could not run curl because $!\n";
    }

    $validcount++;
  }
  else 
  {
    # here is stuff we just do for each *invalid* config line
    $truncline = substr($line, 0, 26);
    chomp $truncline;
    print LOGFILE "ignored invalid config line: ${truncline}[...]\n";
    $invalidcount++;
  }
  # stuff here happens each line even if the line was invalid
}

$endtime = time();
$runtime = $endtime - $starttime;

open LINE, ">>", "$logdirectory/tasmota-runtime.log" or die $!;
print LINE "$timestamp $runtime\n";
close LINE;
`${influxcmd} '${influxurl}write?db=${influxdb}' --data-binary 'tasmota-runtime value=${runtime} ${timestamp}000000000\n'` or warn "Could not run curl because $!\n";

# the hourly checklogs process will mail if it finds stuff here - we can't
# have a mail every run, it's too spammy
if ($errorcount > 0)
{
  print ERRORLOG "$timestamp had $errorcount device errors this run, devices: ";
  foreach $errordevice (@errordevices)
  {
    print ERRORLOG "$errordevice ";
  }
  print ERRORLOG "\n";
}
`echo "all good, exiting happily" >> ${logdirectory}/${debuglog}`;
print LOGFILE "processed $validcount valid config items, ignored $invalidcount invalid lines, had $errorcount errors in $runtime seconds\n";
print LOGFILE "exiting successfully\n\n";

close LOCKFILE;
unlink $lockfile;
