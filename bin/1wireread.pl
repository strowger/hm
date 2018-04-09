#! /usr/bin/perl -w
#
# 1wireiread.pl - read values from 1-wire bus using owfs's owread utility and save
# to log and rrd
#
# GH 2015-06-24
# begun
#
$config="/data/hm/conf/1wireread.conf";
$rrddirectory="/data/hm/rrd";
$logdirectory="/data/hm/log";
$logfile="1wireread.log";
$errorlog="1wireread-errors.log";
$lockfile="/tmp/1wireread.lock";
$owread="/opt/owfs/bin/owread";

$influxcmd="curl -s -S -i -XPOST ";
$influxurl="http://localhost:8086/";
$influxdb="styes_1wire";

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

print LOGFILE "starting 1wireread at $timestamp\n";

open CONFIG, "<", "$config" or die $!;

$validcount = 0;
$invalidcount = 0;
$owerrorcount = 0;
@errordevices = ();

# store list of devices on each bus to use later in generating error messages

$output = `/opt/owfs/bin/owget /bus.0|grep -v alarm|grep -v simultaneous|grep -v interface|sed 's/\\/bus.0\\///'`;
@bus0members = split(' ',$output);
$output = `/opt/owfs/bin/owget /bus.1|grep -v alarm|grep -v simultaneous|grep -v interface|sed 's/\\/bus.1\\///'`;
@bus1members = split(' ',$output);
$output = `/opt/owfs/bin/owget /bus.2|grep -v alarm|grep -v simultaneous|grep -v interface|sed 's/\\/bus.2\\///'`;
@bus2members = split(' ',$output);

print LOGFILE "bus0 members: @bus0members\n";
print LOGFILE "bus1 members: @bus1members\n";
print LOGFILE "bus2 members: @bus2members\n";

# count devices on each bus and record
foreach $bus (0..2) 
{
  print LOGFILE "$timestamp: reading device count on bus $bus: ";
  $buscount = `/opt/owfs/bin/owdir /bus.$bus|grep -v alarm|grep -v simultaneous|grep -v interface|wc -l`;
  chomp $buscount;
  print LOGFILE "$buscount\n";
  open LINE, ">>", "$logdirectory/1wdevicecount$bus.log" or die $!;
  print LINE "$timestamp $buscount\n";
  close LINE;
  # if the rrd doesn't exist, don't attempt to write
  if ( -f "$rrddirectory/1wdevicecount$bus.rrd" )
  {
    $output = `rrdtool update $rrddirectory/1wdevicecount$bus.rrd $timestamp:$buscount`;
    if (length $output)
    {
      print LOGFILE "rrdtool errored $output\n";
    }
  }
  else
  {
    print LOGFILE "rrd for 1wdevicecount$bus doesn't exist, skipping update\n";
  }
  print LOGFILE "$timestamp: reading times on bus $bus: ";
  $bustime = `/opt/owfs/bin/owread /bus.$bus/interface/statistics/bus_time`;
  chomp $bustime;
  # this substitution removes leading whitespace
  $bustime =~ s/^\s+//;
  print LOGFILE "bustime $bustime,";
  $uptime = `/opt/owfs/bin/owread /bus.$bus/interface/statistics/elapsed_time`;
  chomp $uptime;
  $uptime =~ s/^\s+//;
  print LOGFILE "uptime $uptime, ";
  # crashes the script with divide-by-zero error if we didn't read the value
  $usedpercent = $bustime / $uptime * 100;
  $usedpercentrounded = sprintf "%.2f", $usedpercent;
  print LOGFILE "calculated utilisation $usedpercentrounded%\n";
  open LINE, ">>", "$logdirectory/bus${bus}utilpercent.log" or die $!;
  print LINE "$timestamp $usedpercentrounded\n";
  close LINE;
  if ( -f "$rrddirectory/bus${bus}utilpercent.rrd" )
  {
    $output = `rrdtool update $rrddirectory/bus${bus}utilpercent.rrd $timestamp:$usedpercentrounded`;
    if (length $output)
    {
      print LOGFILE "rrdtool errored $output\n";
    }
  }
  else
  {
    print LOGFILE "rrd for bus${bus}utilpercent doesn't exist, skipping update\n";
  }

  print LOGFILE "$timestamp: reading error counts on bus $bus: ";
  @errorvalues = qw(close_errors detect_errors errors locks open_errors program_errors pullup_errors read_errors reconnect_errors reconnects reset_errors resets select_errors shorts status_errors timeouts unlocks);
  foreach $errortype (@errorvalues)
  {
    $errorvalue = `/opt/owfs/bin/owread /bus.$bus/interface/statistics/$errortype`;
    chomp $errorvalue;
    # this substitution removes leading whitespace
    $errorvalue =~ s/^\s+//;
    print LOGFILE "$errortype $errorvalue ";
    open LINE, ">>", "$logdirectory/bus${bus}${errortype}.log" or die $!;
    print LINE "$timestamp $errorvalue\n";
    close LINE;
    if ( -f "$rrddirectory/bus${bus}${errortype}.rrd" )
    {
      $output = `rrdtool update $rrddirectory/bus${bus}${errortype}.rrd $timestamp:$errorvalue`;
      if (length $output)
      {
        print LOGFILE "rrdtool errored $output\n";
      }
    }
    else
    {
      print LOGFILE "rrd for bus${bus}${errortype} doesn't exist, skipping update\n";
    }

  }
  print LOGFILE "\n";
}


foreach $line (<CONFIG>)
{
  $timestamp = time();
# device id, value to read, rrd filename
  ($device, $value, $filename) = split(',',$line);
  # starts with hash means comment, so ignore
  # ignore if there isn't a value for all items
  if (($device !~ /\#.*/) && (defined $device) && (defined $value) && (defined $filename))
  {
    # here is stuff we just do for each *valid* config line
    chomp $filename;
    print LOGFILE "$timestamp: reading $device $value $filename: ";
    # redirect stderr
    $output = `$owread /$device/$value 2>&1`;
    # remove *leading* whitespace only - means we don't mangle the errors
    $output =~ s/^\s+//;
    chomp $output;
    print LOGFILE "$output\n";

    if (($output =~ /error/ ) || ($output =~ /ERR/ ))
    {
      print LOGFILE "got error in owread output - not saving\n";
      $owerrorcount++;
      push(@errordevices, $device);
    }
    else
    {
      open LINE, ">>", "$logdirectory/$filename.log" or die $!;
      print LINE "$timestamp $output\n";
      close LINE;
      # if the rrd doesn't exist, don't attempt to write
      if ( -f "$rrddirectory/${filename}.rrd" )
      {
        `${influxcmd} '${influxurl}write?db=${influxdb}' --data-binary '${filename} value=${output} ${timestamp}000000000\n'`;
        $output = `rrdtool update $rrddirectory/$filename.rrd $timestamp:$output`;
        if (length $output)
        {
          print LOGFILE "rrdtool errored $output\n";
        }
      }
      else
      {
        print LOGFILE "rrd for $filename doesn't exist, skipping update\n";
      }
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

open LINE, ">>", "$logdirectory/runtime1w.log" or die $!;
print LINE "$timestamp $runtime\n";
close LINE;
if ( -f "$rrddirectory/runtime1w.rrd" )
{
  $output = `rrdtool update $rrddirectory/runtime1w.rrd $timestamp:$runtime`;
  if (length $output)
    {
      print LOGFILE "rrdtool errored $output\n";
    }
}
else
{
  print LOGFILE "rrd for runtime1w doesn't exist, skipping update\n";
}

# the hourly checklogs process will mail if it finds stuff here - we can't
# have a mail every run, it's too spammy
if ($owerrorcount > 0)
{
  print ERRORLOG "$timestamp had $owerrorcount 1-wire bus errors this run, devices: ";
  foreach $errordevice (@errordevices)
  {
    print ERRORLOG "$errordevice ";
    if (grep /$errordevice/, @bus0members)
      { print ERRORLOG "(bus 0) "; }
    if (grep /$errordevice/, @bus1members)
      { print ERRORLOG "(bus 1) "; }
    if (grep /$errordevice/, @bus2members)
      { print ERRORLOG "(bus 2) "; }
  }
  print ERRORLOG "\n";
}

print LOGFILE "processed $validcount valid config items, ignored $invalidcount invalid lines, had $owerrorcount 1w bus errors in $runtime seconds\n";
print LOGFILE "exiting successfully\n\n";

close LOCKFILE;
unlink $lockfile;
