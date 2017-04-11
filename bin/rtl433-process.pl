#! /usr/bin/perl -w
#
# rtl433-process.pl - parse datafiles from rtl433
#  based on leafspy-process.pl
# this writes to rrds but not to any new logfiles, and is therefore
# safe to repeatedly re-run over the same data.
#
# GH 2017-03-25
# begun
#

if ($ARGV[0] eq "-process")  { $modeswitch = "process"; }
if ($ARGV[0] eq "-dump")  { $modeswitch = "dump"; }
if (($ARGV[0] ne "-process") && ($ARGV[0] ne "-dump"))
{
  print "usage: [cat logfile.csv|]rtl433-process.pl -process (to add log values to rrds) or -dump (to print to stdout)\n";
  exit 1;
}

# for calculating epoch from logfile values
use Time::Local;

$rrddirectory="/data/hm/rrd";
$logdirectory="/data/hm/log";
$logfile="rtl433-process.log";

$logccopti="rtl433-ccoptical.log";
$logccclamp="rtl433-ccclamp.log";

$timestamp = time();                                                                                  
$starttime = $timestamp;


open LOGFILE, ">>", "$logdirectory/$logfile" or die $!;                                               

print LOGFILE "starting rtl433-process.pl at $timestamp\n";

open CCOPTI, ">>", "$logdirectory/$logccopti" or die $!;
open CCCLAMP, ">>", "$logdirectory/$logccclamp" or die $!;

# each received transmission occupies multiple lines in the output, so we have to be stateful
$midtx = 0;
## we're not dealing with a device we didn't expect
$alien = 0;
$linecount = 0;
# this will read from either stdin or a file specified on the commandline
while (<STDIN>)
{
  $linecount = $linecount+1;
  @line = split(" ",$_);
#  $lineitems = scalar (@line); 
  # seem to get some blank lines which result in emailed errors
  #  also some lines which don't have a third item - which for all our devices
  #  are bogus - these could just be a check for $line[2] really
  if (( ! defined $line[0] || ( ! defined $line[2])) { next; }
  # match on xxxx-xx-xx xx:xx:xx :
  if (( $line[0] =~ /^\d{4}-\d{2}-\d{2}$/) && ($line[1] =~ /^\d{2}:\d{2}:\d{2}$/) && ($line[2] =~ /^:$/))
  {
    # this is the start of a new transmission log from rtl433 - a line with date & time
    ($year,$month,$day) = split("-",$line[0]);
    ($hour,$minute,$second) = split(":",$line[1]); 
    # need to form epoch from these to update rrds with
    # timegm requires months in range 0-11 (!)
    $stupidmonth = $month -1;
    $linetime = timegm($second, $minute, $hour, $day, $stupidmonth, $year);
    $alien = 0;
    # we are part-way through parsing a transmission now
    if ($midtx == 1) 
    { 
      print STDERR "\n$linetime started new transmission without proper end to previous\n"; 
    }
    $midtx = 1;

    if ( $line[3] eq "CurrentCost" )
    # there isn't necessarily going to be a line[4] if it's not currentcost
    {
      if ($line[4] eq "TX")
      {
        $txtype = "currentcost";
      }   
    }
    else 
    { 
      print STDERR "$linetime got alien device $line[3]\n"; 
      # we don't know what to do with this so we ignore the next lines
      $midtx = 0;
      $alien = 1;
    }
  }

  # any other kind of line than the start of a new tx
  else
  {
    # currentcost tx details
    if (($line[0] eq "Device") && ($line[1] eq "Id:"))
    {
      if (($midtx == 1) && ($txtype eq "currentcost"))
      {
        $ccdevid = $line[2];
      }
    }
    
    if (($line[0] eq "Power") && ($line[1] eq "0:"))
    {
      if ( defined $ccdevid )
      {
        $ccpower = $line[2];
        if ( $ccdevid == 0 )
        {
          if ($modeswitch eq "process")
          {
            ## for now we're not rrd updating based on the optical sensor, but
            ## instead letting the cc base unit continue to do it
            # $output = `rrdtool update $rrddirectory/ccoptiwatts.rrd $linetime:$ccpower`;
            # if we got some output then it fucked up so don't log, otherwise...
            # if (length $output)
            # {
            #   chomp $output;
            #   print LOGFILE "got error $output...";
            # }
            # ...log to a sensible logfile so we can bin off the rtl433 logs
            # else
            # {
            #   print CCOPTI "$linetime $ccpower\n";
            # }
          }
          if ($modeswitch eq "dump")
          {
            print "$linetime optical sensor power $ccpower watts\n";
          }
        }

        if ( $ccdevid == 77 )
        {
          if ($modeswitch eq "process")
          {
            $output = `rrdtool update $rrddirectory/ccclampwattscar.rrd $linetime:$ccpower`;
            if (length $output)
            {
              chomp $output;
              print LOGFILE "got error $output...";
            }
            else
            {
              print CCCLAMP "$linetime $ccpower\n";
            }
          }
          if ($modeswitch eq "dump")
          {
            print "$linetime clamp sensor power $ccpower watts\n";
          }
        }

        # we don't care about subsequent "Power x:" lines as they're all zero
        $midtx = 0;
      }
      else { print STDERR "$linetime got a currentcost power line without a preceding deviceid\n"; }
    }
    if ( $alien eq "1" ) { print STDERR "@line\n"; }
  # 
  # end of "non-tx-start line" processing
  }


}

$endtime = time();
$runtime = $endtime - $starttime;

print LOGFILE "exiting successfully after $linecount lines in $runtime seconds \n\n";

close LOGFILE;
close CCOPTI;
close CCCLAMP;