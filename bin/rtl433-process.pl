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

#$logccopti="rtl433-ccoptical.log";
$logccclampcar="rtl433-ccclampcar.log";
$logccclampheat="rtl433-ccclampheat.log";
$logccclampcook="rtl433-ccclampcook.log";
$logcciamdryer="rtl433-cciamdryer.log";
$logcciamwasher="rtl433-cciamwasher.log";
$logcciamfridge="rtl433-cciamfridge.log";
$logcciamdwasher="rtl433-cciamdwasher.log";
$logcciamupsb="rtl433-cciamupsb.log";
$logcciamofficedesk="rtl433-cciamofficedesk.log";
$logcciamupso="rtl433-cciamupso.log";
$logcciamtoaster="rtl433-cciamtoaster.log";
$logcciamkettle="rtl433-cciamkettle.log";

$timestamp = time();                                                                                  
$starttime = $timestamp;

open LOGFILE, ">>", "$logdirectory/$logfile" or die $!;                                               
print LOGFILE "starting rtl433-process.pl at $timestamp\n";

$timelastccclampcar=`tail -1 $logdirectory/$logccclampcar|awk '{print \$1}'`;
$timelastccclampheat=`tail -1 $logdirectory/$logccclampheat|awk '{print \$1}'`;
$timelastccclampcook=`tail -1 $logdirectory/$logccclampcook|awk '{print \$1}'`;
$timelastcciamdryer=`tail -1 $logdirectory/$logcciamdryer|awk '{print \$1}'`;
$timelastcciamwasher=`tail -1 $logdirectory/$logcciamwasher|awk '{print \$1}'`;
$timelastcciamfridge=`tail -1 $logdirectory/$logcciamfridge|awk '{print \$1}'`;
$timelastcciamdwasher=`tail -1 $logdirectory/$logcciamdwasher|awk '{print \$1}'`;
$timelastcciamupsb=`tail -1 $logdirectory/$logcciamupsb|awk '{print \$1}'`;
$timelastcciamofficedesk=`tail -1 $logdirectory/$logcciamofficedesk|awk '{print \$1}'`;
$timelastcciamupso=`tail -1 $logdirectory/$logcciamupso|awk '{print \$1}'`;
$timelastcciamtoaster=`tail -1 $logdirectory/$logcciamtoaster|awk '{print \$1}'`;
$timelastcciamkettle=`tail -1 $logdirectory/$logcciamkettle|awk '{print \$1}'`;

#open CCOPTI, ">>", "$logdirectory/$logccopti" or die $!;
open CCCLAMPHEAT, ">>", "$logdirectory/$logccclampheat" or die $!;
open CCCLAMPCAR, ">>", "$logdirectory/$logccclampcar" or die $!;
open CCCLAMPCOOK, ">>", "$logdirectory/$logccclampcook" or die $!;
open CCIAMDRYER, ">>", "$logdirectory/$logcciamdryer" or die $!;
open CCIAMWASHER, ">>", "$logdirectory/$logcciamwasher" or die $!;
open CCIAMFRIDGE, ">>", "$logdirectory/$logcciamfridge" or die $!;
open CCIAMDWASHER, ">>", "$logdirectory/$logcciamdwasher" or die $!;
open CCIAMUPSB, ">>", "$logdirectory/$logcciamupsb" or die $!;
open CCIAMOFFICEDESK, ">>", "$logdirectory/$logcciamofficedesk" or die $!;
open CCIAMUPSO, ">>", "$logdirectory/$logcciamupso" or die $!;
open CCIAMTOASTER, ">>", "$logdirectory/$logcciamtoaster" or die $!;
open CCIAMKETTLE, ">>", "$logdirectory/$logcciamkettle" or die $!;

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
  if (( ! defined $line[0] ) || ( ! defined $line[2])) { next; }
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
      print LOGFILE "$linetime got alien device $line[3]\n"; 
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
# $ccdevid is the "Device Id" output by the currentcost transmitter
# they seem set randomly 
# 0    = optical transmitter on whole house
# 77   = clamp transmitter on car charger
# 996  = clamp transmitter on heating - needs correction factor applied
# 2267 = clamp - went to euan
# 1090 = clamp transmitter on cooker
# 1048 = clamp on ch/SPARE
# 2232 = clamp - went to euan
# 921  = iam washing machine
# 1971 = iam dryer
# 3037 = iam fridge
# 3214 = iam dishwasher
# 1314 = iam basement ups
# 2829 = iam office desk 10bar
# 3879 = iam office ups
# 2071 = iam toaster
# 4023 = iam kettle
      if ( defined $ccdevid )
      {
        $ccpower = $line[2];
        if ( $ccdevid == 0 )
        {
#          if (($modeswitch eq "process") && ($linetime > $timelastccopti))
#          {
#            $timelastccopti = $linetime;
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
            #   { #   print CCOPTI "$linetime $ccpower\n"; # }
#          }
          if ($modeswitch eq "dump")
            { print "$linetime optical sensor power $ccpower watts\n"; }
        }

        if ( $ccdevid == 77 )
        {
          if (($modeswitch eq "process") && ($linetime > $timelastccclampcar))
          {
            $timelastccclampcar = $linetime;
            $output = `rrdtool update $rrddirectory/ccclampwattscar.rrd $linetime:$ccpower`;
            if (length $output)
              { chomp $output; print LOGFILE "got error $output..."; }
            else
              { print CCCLAMPCAR "$linetime $ccpower\n"; }
          }
          if ($modeswitch eq "dump")
            { print "$linetime clamp sensor car power $ccpower watts\n"; }
        }

        if ( $ccdevid == 996 )
        {
          if (($modeswitch eq "process") && ($linetime > $timelastccclampheat))
          {
            $timelastccclampheat = $linetime;
            # this is very inaccurate - rough correction is * 1.3
            $ccpower = $ccpower * 1.3;
            $output = `rrdtool update $rrddirectory/ccclampwattsheating.rrd $linetime:$ccpower`;
            if (length $output)
              { chomp $output; print LOGFILE "got error $output..."; }
            else
              { print CCCLAMPHEAT "$linetime $ccpower\n"; }
          }
          if ($modeswitch eq "dump")
            { print "$linetime clamp sensor heating power $ccpower ADJUSTED watts\n"; }
        }

        if ( $ccdevid == 1090 )
        {
          if (($modeswitch eq "process") && ($linetime > $timelastccclampcook))
          {
            $timelastccclampcook = $linetime;
            $output = `rrdtool update $rrddirectory/ccclampwattscooker.rrd $linetime:$ccpower`;
            if (length $output)
             { chomp $output; print LOGFILE "got error $output..."; }
            else
              { print CCCLAMPCOOK "$linetime $ccpower\n"; }
          }
          if ($modeswitch eq "dump")
            { print "$linetime clamp sensor cooker power $ccpower watts\n"; }
        }


        if ( $ccdevid == 921 )
        {
          if (($modeswitch eq "process") && ($linetime > $timelastcciamwasher))
          {
            $timelastcciamwasher = $linetime;
            $output = `rrdtool update $rrddirectory/cciamwasher.rrd $linetime:$ccpower`;
            if (length $output)
              { chomp $output; print LOGFILE "got error $output..."; }
            else
              { print CCIAMWASHER "$linetime $ccpower\n"; }
          }
          if ($modeswitch eq "dump")
            { print "$linetime iam washer sensor power $ccpower watts\n"; }
        }

        if ( $ccdevid == 1971 )
        {
          if (($modeswitch eq "process") && ($linetime > $timelastcciamdryer))
          {
            $timelastcciamdryer = $linetime;
            $output = `rrdtool update $rrddirectory/cciamdryer.rrd $linetime:$ccpower`;
            if (length $output)
              { chomp $output; print LOGFILE "got error $output..."; }
            else
              { print CCIAMDRYER "$linetime $ccpower\n"; }
          }
          if ($modeswitch eq "dump")
            { print "$linetime iam dryer sensor power $ccpower watts\n"; }
        }

        if ( $ccdevid == 3037 )
        {
          if (($modeswitch eq "process") && ($linetime > $timelastcciamfridge))
          {
            $timelastcciamfridge = $linetime;
            $output = `rrdtool update $rrddirectory/cciamfridge.rrd $linetime:$ccpower`;
            if (length $output)
              { chomp $output; print LOGFILE "got error $output..."; }
            else
              { print CCIAMFRIDGE "$linetime $ccpower\n"; }
          }
          if ($modeswitch eq "dump")
            { print "$linetime iam fridge sensor power $ccpower watts\n"; }
        }

        if ( $ccdevid == 3214 )
        {
          if (($modeswitch eq "process") && ($linetime > $timelastcciamdwasher))
          {
            $timelastcciamdwasher = $linetime;
            $output = `rrdtool update $rrddirectory/cciamdwasher.rrd $linetime:$ccpower`;
            if (length $output)
              { chomp $output; print LOGFILE "got error $output..."; }
            else
              { print CCIAMDWASHER "$linetime $ccpower\n"; }
          }
          if ($modeswitch eq "dump")
            { print "$linetime iam dishwasher sensor power $ccpower watts\n"; }
        }

        if ( $ccdevid == 1314 )
        {
          if (($modeswitch eq "process") && ($linetime > $timelastcciamupsb))
          {
            $timelastcciamupsb = $linetime;
            $output = `rrdtool update $rrddirectory/cciamupsb.rrd $linetime:$ccpower`;
            if (length $output)
              { chomp $output; print LOGFILE "got error $output..."; }
            else
              { print CCIAMUPSB "$linetime $ccpower\n"; }
          }
          if ($modeswitch eq "dump")
            { print "$linetime iam basement ups sensor power $ccpower watts\n"; }
        }

        if ( $ccdevid == 2829 )
        {
          if (($modeswitch eq "process") && ($linetime > $timelastcciamofficedesk))
          {
            $timelastcciamofficedesk = $linetime;
            $output = `rrdtool update $rrddirectory/cciamofficedesk.rrd $linetime:$ccpower`;
            if (length $output)
              { chomp $output; print LOGFILE "got error $output..."; }
            else
              { print CCIAMOFFICEDESK "$linetime $ccpower\n"; }
          }
          if ($modeswitch eq "dump")
            { print "$linetime iam office desk sensor power $ccpower watts\n"; }
        }

        if ( $ccdevid == 3879 )
        {
          if (($modeswitch eq "process") && ($linetime > $timelastcciamupso))
          {
            $timelastcciamupso = $linetime;
            $output = `rrdtool update $rrddirectory/cciamupso.rrd $linetime:$ccpower`;
            if (length $output)
              { chomp $output; print LOGFILE "got error $output..."; }
            else
              { print CCIAMUPSO "$linetime $ccpower\n"; }
          }
          if ($modeswitch eq "dump")
            { print "$linetime iam office ups sensor power $ccpower watts\n"; }
        }

        if ( $ccdevid == 2071 )
        {
          if (($modeswitch eq "process") && ($linetime > $timelastcciamtoaster))
          {
            $timelastcciamtoaster = $linetime;
            $output = `rrdtool update $rrddirectory/cciamtoaster.rrd $linetime:$ccpower`;
            if (length $output)
              { chomp $output; print LOGFILE "got error $output..."; }
            else
              { print CCIAMTOASTER "$linetime $ccpower\n"; }
          }
          if ($modeswitch eq "dump")
            { print "$linetime iam toaster sensor power $ccpower watts\n"; }
        }

        if ( $ccdevid == 4023 )
        {
          if (($modeswitch eq "process") && ($linetime > $timelastcciamkettle))
          {
            $timelastcciamkettle = $linetime;
            $output = `rrdtool update $rrddirectory/cciamkettle.rrd $linetime:$ccpower`;
            if (length $output)
              { chomp $output; print LOGFILE "got error $output..."; }
            else
              { print CCIAMKETTLE "$linetime $ccpower\n"; }
          }
          if ($modeswitch eq "dump")
            { print "$linetime iam kettle sensor power $ccpower watts\n"; }
        }

        # we don't care about subsequent "Power x:" lines as they're all zero
        $midtx = 0;
      }
      else { print STDERR "$linetime got a currentcost power line without a preceding deviceid\n"; }
    }
    if ( $alien eq "1" ) { print LOGFILE "@line\n"; }
  # 
  # end of "non-tx-start line" processing
  }


}

$endtime = time();
$runtime = $endtime - $starttime;

print LOGFILE "exiting successfully after $linecount lines in $runtime seconds \n\n";

close LOGFILE;
