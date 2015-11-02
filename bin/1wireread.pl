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
$lockfile="/tmp/1wireread.lock";
$owread="/opt/owfs/bin/owread";

if ( -f $lockfile ) 
{
  die "Lockfile exists in $lockfile; exiting";
}

open LOCKFILE, ">", $lockfile or die $!;

$timestamp = time();
$starttime = $timestamp;

open LOGFILE, ">>", "$logdirectory/$logfile" or die $!;

print LOGFILE "starting 1wireread at $timestamp\n";

open CONFIG, "<", "$config" or die $!;

$validcount = 0;
$invalidcount = 0;
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
    $output = `$owread /$device/$value|sed s/\\ //g`;
    print LOGFILE "$output\n";

    if (($output =~ /error/ ) || ($output =~ /ERR/ ))
    {
      print LOGFILE "got error in owread output - not saving\n";
    }
    else
    {
      open LINE, ">>", "$logdirectory/$filename.log" or die $!;
      print LINE "$timestamp $output\n";
      close LINE;
      # if the rrd doesn't exist, don't attempt to write
      if ( -f "$rrddirectory/${filename}.rrd" )
      {
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

# count devices on each bus and record
foreach $bus (0..1) 
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

print LOGFILE "processed $validcount valid config items, ignored $invalidcount invalid lines in $runtime seconds\n";
print LOGFILE "exiting successfully\n\n";

close LOCKFILE;
unlink $lockfile;
