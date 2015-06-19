#! /usr/bin/perl -w
#
# ebusread.pl - read values from ebus using ebusd's ebusctl utility and save
# to log and rrd
#
# GH 2015-06-18
# begun
#
$config="/data/hm/conf/ebusread.conf";
# $rrddirectory="/data/hm/rrd";
$logdirectory="/data/hm/log";
$logfile="ebusread.log";

$timestamp = time();

open LOGFILE, ">>", "$logdirectory/$logfile" or die $!;

print LOGFILE "starting ebusread at $timestamp\n";

open CONFIG, "<", "$config" or die $!;

$count = 0;
foreach $line (<CONFIG>)
{
  ($value, $field, $circuit, $localname) = split(',',$line);
  # starts with hash means comment, so ignore
  # ignore if there isn't a value for all items
  if (($value !~ /\#.*/) && (defined $value) && (defined $field) && (defined $circuit) && (defined $localname))
  {
    # here is stuff we just do for each *valid* config line
    chomp $localname;
    print LOGFILE "reading $value $field $circuit $localname: ";
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
    print LOGFILE "$localname $output";

    open LINE, ">>", "$logdirectory/$localname.log" or die $!;
    print LINE "$timestamp $output\n";
    close LINE;

    # sleep 0.25sec - if we read ebus too fast, it fucks up
    select(undef, undef, undef, 0.25);
    $count++;

  }
  else 
  {
    # here is stuff we just do for each *invalid* config line
    print LOGFILE "ignored invalid config line: $line";
  }
  # stuff here happens each line even if the line was invalid
}

print LOGFILE "processed $count valid config items\n";


