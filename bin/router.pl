#! /usr/bin/perl -w
#
# router.pl - read values from router/s with snmp and save
# to log and rrd
#
# GH 2016-03-10
# begun
#
$config="/data/hm/conf/router.conf";
$rrddirectory="/data/hm/rrd";
$logdirectory="/data/hm/log";
$logfile="router.log";
$errorlog="router-errors.log";
$lockfile="/tmp/router.lock";
$snmpget="/usr/bin/snmpget";

if ( -f $lockfile ) 
{
  die "Lockfile exists in $lockfile; exiting";
}

open LOCKFILE, ">", $lockfile or die $!;

$timestamp = time();
$starttime = $timestamp;

open LOGFILE, ">>", "$logdirectory/$logfile" or die $!;
open ERRORLOG, ">>", "$logdirectory/$errorlog" or die $!;

print LOGFILE "starting router.pl at $timestamp\n";

open CONFIG, "<", "$config" or die $!;

$validcount = 0;
$invalidcount = 0;
$snmperrorcount = 0;
@errordevices = ();

foreach $line (<CONFIG>)
{
  $timestamp = time();

  ($ifindex, $ip, $community, $name, $filename, $description) = split(',',$line);
  # starts with hash means comment, so ignore
  # ignore if there isn't a value for all items
  if (($ifindex !~ /\#.*/) && (defined $ip) && (defined $community) && (defined $name) && (defined $filename) && (defined $description))
  {
    # here is stuff we just do for each *valid* config line
    #
    
    chomp $description;
    print LOGFILE "$timestamp: reading $ifindex $ip $community $name $filename $description: ";
    # redirect stderr
    # use version 2c, don't retry on timeout, only output the actual value
    # output is two numbers, each followed by a linefeed
    $output = `$snmpget -c $community -v2c -r0 -Ovq $ip ifInOctets.$ifindex ifOutOctets.$ifindex 2>&1`;

    if (($output =~ /error/ ) || ($output =~ /ERR/ ) || ($output =~ /imeout/ ))
    {
      print LOGFILE "$output\n";
      print LOGFILE "got error in snmpget output - not saving\n";
      $snmperrorcount++;
      push(@errordevices, $name);
    }
    else
    {
      ($invalue, $outvalue) = split ('\n',$output);
      print LOGFILE "in $invalue out $outvalue\n";
      open LINE, ">>", "$logdirectory/$filename.log" or die $!;
      print LINE "$timestamp in $invalue out $outvalue\n";
      close LINE;
      # if the rrd doesn't exist, don't attempt to write
      if ( -f "$rrddirectory/${filename}.rrd" )
      {
        $output = `rrdtool update $rrddirectory/$filename.rrd $timestamp:$invalue:$outvalue`;
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
## seems to run in about 200msec so worry about run-time is unnecessary
$runtime = $endtime - $starttime;
#
#open LINE, ">>", "$logdirectory/runtimesnmp.log" or die $!;
#print LINE "$timestamp $runtime\n";
#close LINE;
#if ( -f "$rrddirectory/runtimesnmp.rrd" )
#{
#  $output = `rrdtool update $rrddirectory/runtimesnmsnmp.rrd $timestamp:$runtime`;
#  if (length $output)
#    {
#      print LOGFILE "rrdtool errored $output\n";
#    }
#}
#else
#{
#  print LOGFILE "rrd for runtimesnmp doesn't exist, skipping update\n";
#}

# the hourly checklogs process will mail if it finds stuff here - we can't
# have a mail every run, it's too spammy
if ($snmperrorcount > 0)
{
  print ERRORLOG "$timestamp had $snmperrorcount snmp errors this run, devices: ";
  foreach $errordevice (@errordevices)
  {
    print ERRORLOG "$errordevice ";
  }
  print ERRORLOG "\n";
}

print LOGFILE "processed $validcount valid config items, ignored $invalidcount invalid lines, had $snmperrorcount snmp errors in $runtime seconds\n";
print LOGFILE "exiting successfully\n\n";

close LOCKFILE;
unlink $lockfile;
