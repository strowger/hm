#! /usr/bin/perl -w
#
# hs100.pl - read values from tp-link hs100-type devices using pyhs100 and
# save to log/influxdb
# recycled from 1wireread.pl
#
# GH 2019-07-26
# begun (with james/helen/dylan here, the day after the heatwave and the flymo)
#
$config="/data/hm/conf/hs100.conf";
$logdirectory="/data/hm/log";
$logfile="hs100.log";
$errorlog="hs100-errors.log";
$lockfile="/tmp/hs100.lock";

$influxcmd="curl -s -S -i -XPOST ";
$influxurl="http://localhost:8086/";
$influxdb="styes_power";

# because we're grep'ing through the stderr+stio output together and we'll get nowt if there's an error
no warnings 'uninitialized';

open ERRORLOG, ">>", "$logdirectory/$errorlog" or die $!;

if ( -f $lockfile ) 
{
  print ERRORLOG "FATAL: lockfile exists, exiting";
  exit 2;
}

open LOCKFILE, ">", $lockfile or die $!;

$timestamp = time();
$starttime = $timestamp;

open LOGFILE, ">>", "$logdirectory/$logfile" or die $!;

print LOGFILE "starting hs100 at $timestamp\n";

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
  ($device, $name, $type, $ip) = split(',',$line);
  # starts with hash means comment, so ignore
  # ignore if there isn't a value for all vital items
  if (($device !~ /\#.*/) && (defined $device) && (defined $name) && (defined $type))
  {
    # here is stuff we just do for each *valid* config line
    chomp $ip;
    chomp $type;
    if ( defined $ip )
    {
      # an ip has been defined so we'll use it, which speeds up reads and reduces
      # errors but is not resilient to changes made by dhcp server
      $ipstring="--host $ip ";
    }
    else
    {
      $ipstring="";
    }
    print LOGFILE "$timestamp: reading $device $name $type $ip: ";
    if ( $type ne "plug" )
    {
      print LOGFILE "unknown type $type, skipping\n";
      next;
    }
    # redirect stderr
    $output = `/usr/local/bin/pyhs100 --alias $device $ipstring --$type emeter 2>&1|grep voltage`;
    # remove *leading* whitespace only - means we don't mangle the errors
    $output =~ s/^\s+//;
    chomp $output;
    print LOGFILE "$output ";

    if (($output =~ /error/ ) || ($output =~ /ERR/ ) || ($output =~ /No\ device\ with\ name/ ))
    {
      print LOGFILE "got error in pyhs100 output - not saving\n";
      $errorcount++;
      push(@errordevices, $device);
    }
    else
    {

      @outputline = split(" ", $output);

     if ( $outputline[0] =~ /voltage_mv/ )
     {
       print LOGFILE " - is hw2/fw1.5.7 or similar\n";

        $voltagemv = $outputline[1];
        $currentma = $outputline[3];
        $powermw = $outputline[5];
        $totalwh = $outputline[7];
        chop $voltagemv ; chop $currentma ; chop $powermw ; chop $totalwh;

        if (( $voltagemv !~ /^\d+$/ ) || ( $currentma !~ /^\d+$/ ) || ( $powermw !~ /^\d+$/ ) || ( $totalwh !~ /^\d+$/ ))
        {
          print LOGFILE "$timestamp got a non-numeric value (v $voltagemv a $currentma w $powermw totwh $totalwh, skipping\n";       
          print ERRORLOG "$timestamp got a non-numeric value (v $voltagemv a $currentma w $powermw totwh $totalwh, skipping\n";
          next;
        }

        $voltage = $voltagemv / 1000;
        $current = $currentma / 1000;
        $power = $powermw / 1000;
      }  
     
      if ( $outputline[0] =~ /current/ )
      {
        print LOGFILE " - is hw1/fw1.2.5 or similar\n";

        $current = $outputline[1];
        $voltage = $outputline[3];
        $power = $outputline[5];
        # this might actually be kwh not wh but we don't use it anyway
        $totalwh = $outputline[7];
        chop $voltage ; chop $current ; chop $power ; chop $totalwh;
# different regex here because these have decimal points in, ignore watts because it can be zero (not 0.0)
        if (( $voltage !~ /^\d+.\d+$/ ) || ( $current !~ /^\d+.\d+$/ ))
        {
          print LOGFILE "$timestamp got a non-numeric value (v $voltage a $current w $power totwh $totalwh, skipping\n";
          print ERRORLOG "$timestamp got a non-numeric value (v $voltage a $current w $power totwh $totalwh, skipping\n";
          next;
        }
      }

##      print "DEBUG: $voltage v $current a $power w $totalwh total wh\n";

      open LINE, ">>", "$logdirectory/hs100-$name.log" or die $!;
      print LINE "$timestamp v $voltage a $current w $power\n";
      close LINE;
      `${influxcmd} '${influxurl}write?db=${influxdb}' --data-binary 'hs100-${name}-voltage value=${voltage} ${timestamp}000000000\n hs100-${name}-current value=${current} ${timestamp}000000000\n hs100-${name}-power value=${power} ${timestamp}000000000\n'`  or warn "Could not run curl because $!\n";
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

open LINE, ">>", "$logdirectory/hs100-runtime.log" or die $!;
print LINE "$timestamp $runtime\n";
close LINE;
`${influxcmd} '${influxurl}write?db=${influxdb}' --data-binary 'hs100-runtime value=${runtime} ${timestamp}000000000\n'` or warn "Could not run curl because $!\n";

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

print LOGFILE "processed $validcount valid config items, ignored $invalidcount invalid lines, had $errorcount pyhs100 errors in $runtime seconds\n";
print LOGFILE "exiting successfully\n\n";

close LOCKFILE;
unlink $lockfile;
