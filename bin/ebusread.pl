#! /usr/bin/perl -w
#
# ebusread.pl - read values from ebus using ebusd's ebusctl utility and save
# to log and rrd
#
# GH 2015-06-18
# begun
#
$config="/data/hm/conf/ebusread.conf";
$rrddirectory="/data/hm/rrd";
$logdirectory="/data/hm/log";
$logfile="ebusread.log";
$lockfile="/tmp/ebusread.lock";

$influxcmd="curl -s -S -i -XPOST ";
$influxurl="http://localhost:8086/";
$influxdb="styes_ebus";

if ( -f $lockfile ) 
{
  die "Lockfile exists in $lockfile; exiting";
}

open LOCKFILE, ">", $lockfile or die $!;

$timestamp = time();
$starttime = $timestamp;

open LOGFILE, ">>", "$logdirectory/$logfile" or die $!;

print LOGFILE "starting ebusread at $timestamp\n";

open CONFIG, "<", "$config" or die $!;

$validcount = 0;
$invalidcount = 0;
foreach $line (<CONFIG>)
{
  $timestamp = time();
  ($value, $field, $circuit, $localname) = split(',',$line);
  # starts with hash means comment, so ignore
  # ignore if there isn't a value for all items
  if (($value !~ /\#.*/) && (defined $value) && (defined $field) && (defined $circuit) && (defined $localname))
  {
    # here is stuff we just do for each *valid* config line
    chomp $localname;
    print LOGFILE "$timestamp: reading $value $field $circuit $localname: ";
    # where there's a fieldname for the value
    if ($field !~ "NULL")
    {
      $output = `ebusctl read -f -c $circuit $value $field`;
    }
    # where the value only has one field 
    if ($field =~ "NULL")
    {
      $output = `ebusctl read -f -c $circuit $value`;
    }
    # there's a blank line on each ebusctl read, so we need to chomp twice
    chomp $output;
    chomp $output;
    print LOGFILE "$localname $output\n";

    if (($output =~ /error/ ) || ($output =~ /ERR/ ))
    {
      print LOGFILE "got error in ebusctl output - not saving\n";
    }
    else
    {
      open LINE, ">>", "$logdirectory/$localname.log" or die $!;
      print LINE "$timestamp $output\n";
      close LINE;
      `${influxcmd} '${influxurl}write?db=${influxdb}' --data-binary '${localname} value=${output} ${timestamp}000000000\n'` or warn "Could not run curl because $!\n";
      # if the rrd doesn't exist, don't attempt to write
      if ( -f "$rrddirectory/${localname}.rrd" )
      {
        $output = `rrdtool update $rrddirectory/$localname.rrd $timestamp:$output`;
        if (length $output)
        {
          print LOGFILE "rrdtool errored $output\n";
        }
      }
      else
      {
        print LOGFILE "rrd for $localname doesn't exist, skipping update\n";
      }
    }
    # reduced the sleep again when we added influxdb as the fork and request are more delay?
    # sleep 0.1sec - if we read ebus too fast, it fucks up
    # 0.1 sec sleep consistently generates errors from ebusd
    select(undef, undef, undef, 0.1);
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

open LINE, ">>", "$logdirectory/runtimeeb.log" or die $!;
print LINE "$timestamp $runtime\n";
close LINE;
`${influxcmd} '${influxurl}write?db=${influxdb}' --data-binary 'runtimeeb value=${runtime} ${timestamp}000000000\n'` or warn "Could not run curl because $!\n";
if ( -f "$rrddirectory/runtimeeb.rrd" )
{
  $output = `rrdtool update $rrddirectory/runtimeeb.rrd $timestamp:$runtime`;
  if (length $output)
    {
      print LOGFILE "rrdtool errored $output\n";
    }
}
else
{
  print LOGFILE "rrd for runtimeeb doesn't exist, skipping update\n";
}

print LOGFILE "processed $validcount valid config items, ignored $invalidcount invalid lines in $runtime seconds\n";
print LOGFILE "exiting successfully\n\n";

close LOCKFILE;
unlink $lockfile;
