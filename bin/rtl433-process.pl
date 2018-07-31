#! /usr/bin/perl -w
#
# rtl433-process.pl - parse datafiles from rtl433
#  based on leafspy-process.pl
#
# GH 2017-03-25
# begun
# GH 2018-04-08 
# influxdb added
# GH 2018-07-04
# prologue sensors added
# GH 2018-07-22
# "gs 558 smoke detector" water sensor
# GH 2018-07-31
# "nexus temperature/humidity" sensor
#
$influxcmd="curl -s -S -i -XPOST ";
$influxurl="http://localhost:8086/";
# we should rename this to styes_rtl really
$influxdb="styes_power";

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
# unknown frames/devices received
$alienlogfile="rtl433-aliens.log";

# power devices - currentcost
#$logccopti="rtl433-ccoptical.log";
$logccclampcar="rtl433-ccclampcar.log";
$logccclampheat="rtl433-ccclampheat.log";
#$logccclampheat2="rtl433-ccclampheat2.log";
#$logccclampheat3="rtl433-ccclampheat3.log";
$logccclampcook="rtl433-ccclampcook.log";
$logccclamptowelrail="rtl433-ccclamptowelrail.log";
$logcciamdryer="rtl433-cciamdryer.log";
$logccclampcar2="rtl433-cccclampcar2.log";
$logcciamcatpad="rtl433-cciamcatpad.log";
$logcciamwasher="rtl433-cciamwasher.log";
$logcciamfridge="rtl433-cciamfridge.log";
$logcciamfridge2="rtl433-cciamfridge2.log";
$logcciamdwasher="rtl433-cciamdwasher.log";
$logcciammwave="rtl433-cciammwave.log";
$logcciamupsb="rtl433-cciamupsb.log";
$logcciamofficedesk="rtl433-cciamofficedesk.log";
$logcciamupso="rtl433-cciamupso.log";
$logcciamtoaster="rtl433-cciamtoaster.log";
$logcciamkettle="rtl433-cciamkettle.log";
$logcccountoptical="rtl433-cccountoptical.log";
$logcccountgas="rtl433-cccountgas.log";
# this one is an exception - the log is a different name to the rrd
# the rrd is much older, having been previously updated by power.pl
$logccclamphouse="rtl433-ccclamphouse.log";
# non-power devices
# "prologue" cheap aliexpress temp/humidity sensors
$logproltempconservatory="rtl433-proltempconservatory.log";
$logproltempfridgeds="rtl433-proltempfridgeds.log";
$logproltempfridge="rtl433-proltempfridge.log"; 
$logproltempfreezer="rtl433-proltempfreezer.log"; 
$logprolhumconservatory="rtl433-prolhumconservatory.log";
$logprolhumfridgeds="rtl433-prolhumfridgeds.log";
$logprolhumfridge="rtl433-prolhumfridge.log";                                 
$logprolhumfreezer="rtl433-prolhumfreezer.log"; 
$lognextempbed1="rtl433-nextempbed1.log";
$lognexhumbed1="rtl433-nexhumbed1.log";

$logwaterdetcellarmain="rtl433-waterdetcellarmain.log";


$timestamp = time();                                                                                  
$starttime = $timestamp;

open LOGFILE, ">>", "$logdirectory/$logfile" or die $!;                                               
print LOGFILE "starting rtl433-process.pl at $timestamp\n";

$timelastccclampcar=`tail -1 $logdirectory/$logccclampcar|awk '{print \$1}'`;
$timelastccclampheat=`tail -1 $logdirectory/$logccclampheat|awk '{print \$1}'`;
#$timelastccclampheat2=`tail -1 $logdirectory/$logccclampheat2|awk '{print \$1}'`;
#$timelastccclampheat3=`tail -1 $logdirectory/$logccclampheat3|awk '{print \$1}'`;

$timelastccclampcook=`tail -1 $logdirectory/$logccclampcook|awk '{print \$1}'`;
$timelastccclamptowelrail=`tail -1 $logdirectory/$logccclamptowelrail|awk '{print \$1}'`;
$timelastcciamdryer=`tail -1 $logdirectory/$logcciamdryer|awk '{print \$1}'`;
$timelastccclampcar2=`tail -1 $logdirectory/$logccclampcar2|awk '{print \$1}'`;
$timelastcciamcatpad=`tail -1 $logdirectory/$logcciamcatpad|awk '{print \$1}'`;
$timelastcciamwasher=`tail -1 $logdirectory/$logcciamwasher|awk '{print \$1}'`;
$timelastcciamfridge=`tail -1 $logdirectory/$logcciamfridge|awk '{print \$1}'`;
$timelastcciamfridge2=`tail -1 $logdirectory/$logcciamfridge2|awk '{print \$1}'`;
$timelastcciamdwasher=`tail -1 $logdirectory/$logcciamdwasher|awk '{print \$1}'`;
$timelastcciammwave=`tail -1 $logdirectory/$logcciammwave|awk '{print \$1}'`;
$timelastcciamupsb=`tail -1 $logdirectory/$logcciamupsb|awk '{print \$1}'`;
$timelastcciamofficedesk=`tail -1 $logdirectory/$logcciamofficedesk|awk '{print \$1}'`;
$timelastcciamupso=`tail -1 $logdirectory/$logcciamupso|awk '{print \$1}'`;
$timelastcciamtoaster=`tail -1 $logdirectory/$logcciamtoaster|awk '{print \$1}'`;
$timelastcciamkettle=`tail -1 $logdirectory/$logcciamkettle|awk '{print \$1}'`;
$timelastccclamphouse=`tail -1 $logdirectory/$logccclamphouse|awk '{print \$1}'`;
$timelastcccountoptical=`tail -1 $logdirectory/$logcccountoptical|awk '{print \$1}'`;
$timelastcccountgas=`tail -1 $logdirectory/$logcccountgas|awk '{print \$1}'`;
$timelastproltempconservatory=`tail -1 $logdirectory/$logproltempconservatory|awk '{print \$1}'`;
$timelastproltempfridgeds=`tail -1 $logdirectory/$logproltempfridgeds|awk '{print \$1}'`;
$timelastproltempfridge=`tail -1 $logdirectory/$logproltempfridge|awk '{print\$1}'`;
$timelastproltempfreezer=`tail -1 $logdirectory/$logproltempfreezer|awk '{print\$1}'`; 
$timelastprolhumconservatory=`tail -1 $logdirectory/$logprolhumconservatory|awk '{print \$1}'`;
$timelastprolhumfridgeds=`tail -1 $logdirectory/$logprolhumfridgeds|awk '{print \$1}'`;
$timelastprolhumfridge=`tail -1 $logdirectory/$logprolhumfridge|awk '{print\$1}'`;                 
$timelastprolhumfreezer=`tail -1 $logdirectory/$logprolhumfreezer|awk '{print\$1}'`; 
$timelastnextempbed1=`tail -1 $logdirectory/$lognextempbed1|awk '{print\$1}'`;
$timelastnexhumbed1=`tail -1 $logdirectory/$lognexhumbed1|awk '{print\$1}'`;

$timelastwaterdetcellarmain=`tail -1 $logdirectory/$logwaterdetcellarmain|awk '{print\$1}'`;

# we need previous values from all these so we can de-spike them
$lastproltempconservatory=`tail -1 $logdirectory/$logproltempconservatory|awk '{print \$2}'`;
$lastproltempfridgeds=`tail -1 $logdirectory/$logproltempfridgeds|awk '{print \$2}'`;
$lastproltempfridge=`tail -1 $logdirectory/$logproltempfridge|awk '{print\$2}'`;
$lastproltempfreezer=`tail -1 $logdirectory/$logproltempfreezer|awk '{print\$2}'`; 
$lastprolhumconservatory=`tail -1 $logdirectory/$logprolhumconservatory|awk '{print \$2}'`;
$lastprolhumfridgeds=`tail -1 $logdirectory/$logprolhumfridgeds|awk '{print \$2}'`;
$lastprolhumfridge=`tail -1 $logdirectory/$logprolhumfridge|awk '{print\$2}'`;                 
$lastprolhumfreezer=`tail -1 $logdirectory/$logprolhumfreezer|awk '{print\$2}'`; 
$lastnextempbed1=`tail -1 $logdirectory/$lognextempbed1|awk '{print\$2}'`;
$lastnexhumbed1=`tail -1 $logdirectory/$lognexhumbed1|awk '{print\$2}'`;



open ALIENS, ">>", "$logdirectory/$alienlogfile" or die $!;
#open CCOPTI, ">>", "$logdirectory/$logccopti" or die $!;
open CCCLAMPHEAT, ">>", "$logdirectory/$logccclampheat" or die $!;
#open CCCLAMPHEAT2, ">>", "$logdirectory/$logccclampheat2" or die $!;
#open CCCLAMPHEAT3, ">>", "$logdirectory/$logccclampheat3" or die $!;
open CCCLAMPCAR, ">>", "$logdirectory/$logccclampcar" or die $!;
open CCCLAMPCOOK, ">>", "$logdirectory/$logccclampcook" or die $!;
open CCCLAMPTOWELRAIL, ">>", "$logdirectory/$logccclamptowelrail" or die $!;
open CCIAMDRYER, ">>", "$logdirectory/$logcciamdryer" or die $!;
open CCCLAMPCAR2, ">>", "$logdirectory/$logccclampcar2" or die $!;
open CCIAMCATPAD, ">>", "$logdirectory/$logcciamcatpad" or die $!;
open CCIAMWASHER, ">>", "$logdirectory/$logcciamwasher" or die $!;
open CCIAMFRIDGE, ">>", "$logdirectory/$logcciamfridge" or die $!;
open CCIAMFRIDGE2, ">>", "$logdirectory/$logcciamfridge2" or die $!;
open CCIAMDWASHER, ">>", "$logdirectory/$logcciamdwasher" or die $!;
open CCIAMMWAVE, ">>", "$logdirectory/$logcciammwave" or die $!;
open CCIAMUPSB, ">>", "$logdirectory/$logcciamupsb" or die $!;
open CCIAMOFFICEDESK, ">>", "$logdirectory/$logcciamofficedesk" or die $!;
open CCIAMUPSO, ">>", "$logdirectory/$logcciamupso" or die $!;
open CCIAMTOASTER, ">>", "$logdirectory/$logcciamtoaster" or die $!;
open CCIAMKETTLE, ">>", "$logdirectory/$logcciamkettle" or die $!;
open CCCLAMPHOUSE, ">>", "$logdirectory/$logccclamphouse" or die $!;
open CCCOUNTOPTICAL, ">>", "$logdirectory/$logcccountoptical" or die $!;
open CCCOUNTGAS, ">>", "$logdirectory/$logcccountgas" or die $!;
open PROLTEMPCONSERVATORY, ">>", "$logdirectory/$logproltempconservatory" or die $!;
open PROLTEMPFRIDGEDS, ">>", "$logdirectory/$logproltempfridgeds" or die $!; 
open PROLTEMPFRIDGE, ">>", "$logdirectory/$logproltempfridge" or die $!;
open PROLTEMPFREEZER, ">>", "$logdirectory/$logproltempfreezer" or die $!;
open PROLHUMCONSERVATORY, ">>", "$logdirectory/$logprolhumconservatory" or die $!;
open PROLHUMFRIDGEDS, ">>", "$logdirectory/$logprolhumfridgeds" or die $!;
open PROLHUMFRIDGE, ">>", "$logdirectory/$logprolhumfridge" or die $!;                             
open PROLHUMFREEZER, ">>", "$logdirectory/$logprolhumfreezer" or die $!; 
open NEXTEMPBED1, ">>", "$logdirectory/$lognextempbed1" or die $!;
open NEXHUMBED1, ">>", "$logdirectory/$lognexhumbed1" or die $!;

open WATERDETCELLARMAIN, ">>", "$logdirectory/$logwaterdetcellarmain" or die $!;

# each received transmission occupies multiple lines in the output, so we have to be stateful
$midtx = 0;
# we're not dealing with a device we didn't expect
$alien = 0;
$aliencount = 0;
$txtype = "";
# this is the type of packet/frame/transmission we're dealing with
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
  if (( ! defined $line[0] ) || ( ! defined $line[2])) 
  { 
    if ( $midtx == 0) { next; } 
  }
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
    $txtype = "";
    $alien = 0;
    # we are part-way through parsing a transmission now
    if ($midtx == 1) 
    { 
      print STDERR "\n$linetime started new transmission without proper end to previous at line $linecount: @line\n"; 
    }
    $midtx = 1;

    if ( $line[3] eq "CurrentCost" )
    # there isn't necessarily going to be a line[4] if it's not currentcost
    {
      if ( $line[4] eq "TX" ) { $txtype = "currentcost-tx"; }
      if ( $line[4] eq "Counter" ) { $txtype = "currentcost-counter"; }
    }
   
    if ( $line[3] eq "Prologue" )
    # there isn't necessarily going to be a line[4] if it's not prologue
    {
      if ( $line[4] eq "sensor" ) 
      { 
        $txtype = "prologue-sensor"; 
        # the device id, which changes when the batteries are changed, also
        # appears on this line and must be captured
        $prologuedevid = $line[8];
      }
    }

   if ( $line[3] eq "Smoke" )
   # the full line is "Smoke detector GS 558" then some values
   {
     if (( $line[4] eq "detector") && ( $line[6] eq "558"))
     {
       $txtype = "gs558";
       # don't know what these are but hopefully they can distinguish individual units
       $gs558id1 = $line[8];
       $gs558id2 = $line[10];
       $gs558id3 = $line[12];
     }
   }

   if ( $line[3] eq "Nexus" ) 
   # the full line is "Nexus Temperature/Humidity" then 5 lines of values
   {
     if ( $line[4] eq "Temperature/Humidity" ) 
     { 
        $txtype = "nexus"; 
        # zero the values of all the things we hope to find in the tx
        $nexushousecode = "";
        $nexusbat = "";
        $nexuschan = "";
        $nexustemp = "";
        $nexushum = "";
     }
   } 
   
  
    if ( $txtype eq "" )  
    { 
      print LOGFILE "$linetime got alien device $line[3]\n"; 
      # we don't know what to do with this so we ignore the next lines
      $midtx = 0;
      $alien = 1;
      $aliencount = $aliencount + 1;
    }
  }

  # any other kind of line than the start of a new tx
  else
  {

# nexus temperature/humidity sensors, like 
# https://www.aliexpress.com/item/Digoo-DG-R8B-433MHz-Wireless-Digital-Hygrometer-Thermometer-Weather-Station-Sensor-for-DG-TH3330/32866929093.html
# don't seem any more accurate than the prologue ones but case is smaller and takes AAs not AAAs

   if ( $txtype eq "nexus" )
   {
     # this will emit 5 lines after the date/time/label one, the 5th of which is
     # humidity, and the last line, so means we can do the processing
     if (( $line[0] eq "House") && ( $line[1] eq "Code:" ))
     {
       # "house code" is basically device id, changes on battery swap
       $nexushousecode = $line[2];
     }
     if ( $line[0] eq "Battery:" )
     {
       # battery status, only seen "OK" so far
       $nexusbat = $line[1];
       if ( ! $nexusbat eq "OK" ) { print "$linetime nexus device $nexushousecode battery low\n"; }
     }
     if ( $line[0] eq "Channel:" )
     {
       # "channel" selectable 1-3 using switch on device
       $nexuschan = $line[1];
     }
     if ( $line[0] eq "Temperature:" )
     {
       $nexustemp = $line[1];
     }
     if ( $line[0] eq "Humidity:" )
     {
       $nexushum = $line[1];
       if (( ! $nexushousecode eq "") && ( ! $nexusbat eq "" ) && ( ! $nexuschan eq "" ) && ( ! $nexustemp eq ""))
       # we're on the last line and we got a value for all the other lines; winning!
       {
#         print LOGFILE "DEBUG: nexus got all values so gonna look at writing\n";
         # 121: main bedroom in fritzl3: "bed1"
         if (( $nexushousecode eq "121" ) && ( $linetime > $timelastnextempbed1 ))
         {
           $timelastnextempbed1 = $linetime;
           $tempdiff = abs ($lastnextempbed1 - $nexustemp);
           $humdiff = abs ($lastnexhumbed1 - $nexushum);
#           print LOGFILE "DEBUG: nexus bed1 tempdiff $tempdiff humdiff $humdiff\n";
           if (( $nexustemp > -20 ) && ( $nexustemp < 60 ) && ( $tempdiff < 5 ))
           {
             $output2 = `${influxcmd} '${influxurl}write?db=${influxdb}' --data-binary 'temp_bed1 value=${nexustemp} ${linetime}000000000\n'`;
             print NEXTEMPBED1 "$linetime $nexustemp\n";
           }
           else { print LOGFILE "$linetime not writing nexus temp $nexustemp where diff is $tempdiff last $lastnextempbed1\n"; }
           if (( $nexushum > 0 ) && ( $nexushum < 101 ) && ( $humdiff < 5 ))
           {
             $output2 = `${influxcmd} '${influxurl}write?db=${influxdb}' --data-binary 'hum_bed1 value=${nexushum} ${linetime}000000000\n'`;
             print NEXHUMBED1 "$linetime $nexushum\n";
           }
           else { print LOGFILE "$linetime not writing nexus hum $nexushum where diff is $humdiff last $lastnexhumbed1\n"; }
         }

       }
       else { print STDERR "$linetime got an incomplete or mangled nexus tx\n"; }
       $midtx = 0;
     }
   }

# gs558 "smoke detectors", in this case water detector like 
# https://www.aliexpress.com/item/433-868-Wireless-water-leakage-sensor-water-flood-self-inspection-report-detector-sensor-high-sensitivity-water/32847269385.html

    if ( $txtype eq "gs558" )
    {
      if ( $line[0] eq "Raw" )
      {
        $gs558raw = $line[2];
        if (( $gs558id1 eq "274" ) && ( $gs558id2 eq "11" ) && ( $gs558id3 eq "0" ) && ( $linetime > $timelastwaterdetcellarmain ))
        {
          $timelastwaterdetcellarmain = $linetime;
          print WATERDETCELLARMAIN "$linetime $gs558raw\n";
          # perhaps we should alarm more stridently here esp if it's an actual smoke alarm
          print STDERR "$linetime water detected in main cellar\n";
        }
        else { print STDERR "$linetime got a gs558 tx with unknown ids $gs558id1 $gs558id2 $gs558id3: $gs558raw\n"; }
      }
      else { print STDERR "$linetime got a gs558 tx without a raw code line\n"; }
    $midtx = 0;
    }

    # prologue temperature/humidity sensors, from aliexpress
    # like https://www.aliexpress.com/item/433MHz-Wireless-Weather-Station-with-Forecast-Temperature-Digital-Thermometer-Hygrometer-Humidity-Sensor/32862342455.html
    # also https://www.aliexpress.com/item/Digoo-DG-R8S-R8S-Wireless-Sensor-433MHz-Wireless-Digital-Hygrometer-Thermometer-Weather-Station-Sensor-for-DG/32845808693.html
    # ids (remember they change on power-cycle/battery-change)
    # 172: conservatory
    # 25: downstairs fridge
    # 27: fridge; 
    # 209: freezer (if it survives)
    # 242: black car (maybe?)
    if (( $txtype eq "prologue-sensor" ) && ( $line[0] eq "Temperature:" ))
    {
      $prologuetemp = $line[1];

      if ( $prologuedevid == 172 )
      {
        if (($modeswitch eq "process") && ($linetime > $timelastproltempconservatory))
        {
          $timelastproltempconservatory = $linetime;
          $tempdiff = abs ($lastproltempconservatory - $prologuetemp);
          if (( $prologuetemp > -40) && ( $prologuetemp < 80) && ($tempdiff < 5))
          {
            $output2 = `${influxcmd} '${influxurl}write?db=${influxdb}' --data-binary 'temp_conservatory value=${prologuetemp} ${linetime}000000000\n'`;
            print PROLTEMPCONSERVATORY "$linetime $prologuetemp\n";
          }
        }
        if ($modeswitch eq "dump")
          { print "$linetime prologue sensor conservatory temperature $prologuetemp c\n"; }
      }

      if ( $prologuedevid == 25 )
      {
        if (($modeswitch eq "process") && ($linetime > $timelastproltempfridgeds))
        {
          $timelastproltempfridgeds = $linetime;
          $tempdiff = abs ($lastproltempfridgeds - $prologuetemp);
          if (( $prologuetemp > -20) && ( $prologuetemp < 70) && ($tempdiff < 5)) 
          {
            $output2 = `${influxcmd} '${influxurl}write?db=${influxdb}' --data-binary 'temp_fridge_ds value=${prologuetemp} ${linetime}000000000\n'`;
            print PROLTEMPFRIDGEDS "$linetime $prologuetemp\n";
          }
        }
        if ($modeswitch eq "dump")
          { print "$linetime prologue sensor fridge_ds temperature $prologuetemp c\n"; }
      }      

      if ( $prologuedevid == 27 )                                                                    
      {                                                                                              
        if (($modeswitch eq "process") && ($linetime > $timelastproltempfridge))                   
        {                                                                                            
          $timelastproltempfridge = $linetime;
          $tempdiff = abs ($lastproltempfridge - $prologuetemp);
          if (( $prologuetemp > -20) && ( $prologuetemp < 70) && ($tempdiff < 5))
          {
            $output2 = `${influxcmd} '${influxurl}write?db=${influxdb}' --data-binary 'temp_fridge value=${prologuetemp} ${linetime}000000000\n'`;                                                       
            print PROLTEMPFRIDGE "$linetime $prologuetemp\n";                                        
          }
        }                                                                                            
        if ($modeswitch eq "dump")                                                                   
          { print "$linetime prologue sensor fridge temperature $prologuetemp c\n"; } 
      }

      if ( $prologuedevid == 209 )                                                                    
      {                                                                                              
        if (($modeswitch eq "process") && ($linetime > $timelastproltempfreezer))                
        {                                                                                            
          $timelastproltempfreezer = $linetime;
          $tempdiff = abs ($lastproltempfreezer - $prologuetemp);
          if (( $prologuetemp > -40) && ( $prologuetemp < 30) && ($tempdiff < 5)) 
          {
            $output2 = `${influxcmd} '${influxurl}write?db=${influxdb}' --data-binary 'temp_freezer value=${prologuetemp} ${linetime}000000000\n'`;
            print PROLTEMPFREEZER "$linetime $prologuetemp\n";                                                 }
        }
        if ($modeswitch eq "dump")                                                                   
          { print "$linetime prologue sensor freezer temperature $prologuetemp c\n"; } 
       }


    }

    if (( $txtype eq "prologue-sensor" ) && ( $line[0] eq "Humidity:" ))
    {
      $prologuehum = $line[1];

      if ( $prologuedevid == 172 )
      {
        if (($modeswitch eq "process") && ($linetime > $timelastprolhumconservatory))
        {
          $timelastprolhumconservatory = $linetime;
          $humdiff = abs ($lastprolhumconservatory - $prologuehum);
          if (( $prologuehum > 0) && ($prologuehum < 101) && ($humdiff < 5))
          {
            $output2 = `${influxcmd} '${influxurl}write?db=${influxdb}' --data-binary 'hum_conservatory value=${prologuehum} ${linetime}000000000\n'`;
            print PROLHUMCONSERVATORY "$linetime $prologuehum\n";
          }
        }
        if ($modeswitch eq "dump")
          { print "$linetime prologue sensor conservatory humidity $prologuehum %\n"; }
      }

      if ( $prologuedevid == 25 )
      {
        if (($modeswitch eq "process") && ($linetime > $timelastprolhumfridgeds))
        {
          $timelastprolhumfridgeds = $linetime;
          $humdiff = abs ($lastprolhumfridgeds - $prologuehum);
          if (( $prologuehum > 0) && ($prologuehum < 101) && ($humdiff < 5))
          {
            $output2 = `${influxcmd} '${influxurl}write?db=${influxdb}' --data-binary 'hum_fridge_ds value=${prologuehum} ${linetime}000000000\n'`;
            print PROLHUMFRIDGEDS "$linetime $prologuehum\n";
          }
        }
        if ($modeswitch eq "dump")
          { print "$linetime prologue sensor fridge_ds humidity $prologuehum %\n"; }
      }

      if ( $prologuedevid == 27 )                                                                    
      {                                                                                              
        if (($modeswitch eq "process") && ($linetime > $timelastprolhumfridge))                   
        {                                                                                            
          $timelastprolhumfridge = $linetime;                                                     
          $humdiff = abs ($lastprolhumfridge - $prologuehum);
          if (( $prologuehum > 0) && ($prologuehum < 101) && ($humdiff < 5))
          {
            $output2 = `${influxcmd} '${influxurl}write?db=${influxdb}' --data-binary 'hum_fridge value=${prologuehum} ${linetime}000000000\n'`;                                                       
            print PROLHUMFRIDGE "$linetime $prologuehum\n";                                        
          }
        }                                                                                            
        if ($modeswitch eq "dump")                                                                   
          { print "$linetime prologue sensor fridge humidity $prologuehum c\n"; } 
      }

      if ( $prologuedevid == 209 )                                                                    
      {                                                                                              
        if (($modeswitch eq "process") && ($linetime > $timelastprolhumfreezer))                
        {                                                                                            
          $timelastprolhumfreezer = $linetime;                                                     
          $humdiff = abs ($lastprolhumfreezer - $prologuehum); 
          if (( $prologuehum > 0) && ($prologuehum < 101) && ($humdiff < 5))
          {
            $output2 = `${influxcmd} '${influxurl}write?db=${influxdb}' --data-binary 'hum_freezer value=${prologuehum} ${linetime}000000000\n'`;                                                       
            print PROLHUMFREEZER "$linetime $prologuehum\n";                                        
          }
        }                                                                                            
        if ($modeswitch eq "dump")                                                                   
          { print "$linetime prologue sensor freezer humidity $prologuehum c\n"; } 
       }



    # humidity is the last thing in a prologue temp/humidity sensor tx
    $midtx = 0;

    }


    # currentcost tx details
    if (($line[0] eq "Device") && ($line[1] eq "Id:"))
    {
      # for now, we handle both of these cases the same way 
      # we're capturing the device id
      # $ccdevid is the "Device Id" output by the currentcost transmitter
      # they seem set randomly 
      # 0    = optical transmitter on whole house
      # 77   = clamp transmitter on car charger, still in place but unused as comms unreliable
      # 910  = clamp on ch
      # 996  = clamp transmitter SPARE - inaccurate, under-reads
      # 2178 - clamp tx on second car charger
      # 2267 = clamp - went to euan
      # 1090 = clamp transmitter on cooker
      # 1048 = clamp on whole house
      # 2232 = clamp - went to euan
      # 3107 = clamp transmitter on car charger line in fusebox 20180524
      # 3957 - clamp - master bedroom ensuite towel rail
      # 272  = iam catpad (was granny cable for imiev)
      # 921  = iam washing machine
      # 1971 = iam dryer
      # 3037 = iam fridge
      # 1130 - iam fridge2 (basement)
      # 3214 = iam dishwasher
      # 1314 = iam basement ups
      # 1430 = iam microwave
      # 2829 = iam office desk 10bar
      # 3879 = iam office ups
      # 2071 = iam toaster
      # 4023 = iam kettle
      # 1039 = counter - gasmart on gas meter
      # 2977 = counter - pulse counter on electricity meter led - same physical device as id 0
      #  but outputting a different frame type with the count in it
      # 3083 = unknown/lost device - seems to be outputting zero - could be gasmart unit?
      #
      if (($midtx == 1) && ($txtype eq "currentcost-tx")) { $ccdevid = $line[2]; }
      if (($midtx == 1) && ($txtype eq "currentcost-counter")) { $ccdevid = $line[2]; }
    }

# this giant "if" statement handles "power" ie "-tx" devices, another below does counters    
    if (($line[0] eq "Power") && ($line[1] eq "0:"))
    {
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

        if ( $ccdevid == 1048 )
        {
          if (($modeswitch eq "process") && ($linetime > $timelastccclamphouse))
          {
            $timelastccclamphouse = $linetime;
            # non-standard filename
            $output = `rrdtool update $rrddirectory/ccclampwatts.rrd $linetime:$ccpower`;
            $output2 = `${influxcmd} '${influxurl}write?db=${influxdb}' --data-binary 'wholehouse_clamp value=${ccpower} ${linetime}000000000\n'`;
            #print LOGFILE "influxdb said $output2\n";
            if (length $output)
              { chomp $output; print LOGFILE "got error $output..."; }
            else
              { print CCCLAMPHOUSE "$linetime $ccpower\n"; }
          }
          if ($modeswitch eq "dump")
            { print "$linetime clamp sensor whole-house power $ccpower watts\n"; }
        }

#        if ( $ccdevid == 77 )
#        {
#          if (($modeswitch eq "process") && ($linetime > $timelastccclampcar))
#          {
#            $timelastccclampcar = $linetime;
#            $output = `rrdtool update $rrddirectory/ccclampwattscar.rrd $linetime:$ccpower`;
#            $output2 = `${influxcmd} '${influxurl}write?db=${influxdb}' --data-binary 'car_charger value=${ccpower} ${linetime}000000000\n'`;
#            if (length $output)
#              { chomp $output; print LOGFILE "got error $output..."; }
#            else
#              { print CCCLAMPCAR "$linetime $ccpower\n"; }
#          }
#          if ($modeswitch eq "dump")
#            { print "$linetime clamp sensor car power $ccpower watts\n"; }
#        }

        if ( $ccdevid == 2178 )
        {
          if (($modeswitch eq "process") && ($linetime > $timelastccclampcar2))
          {
            $timelastccclampcar2 = $linetime;
#            $output = `rrdtool update $rrddirectory/ccclampwattscar2.rrd $linetime:$ccpower`;
            $output2 = `${influxcmd} '${influxurl}write?db=${influxdb}' --data-binary 'car_charger2 value=${ccpower} ${linetime}000000000\n'`;
            if (length $output)
              { chomp $output; print LOGFILE "got error $output..."; }
            else
              { print CCCLAMPCAR2 "$linetime $ccpower\n"; }
            print CCCLAMPCAR2 "$linetime $ccpower\n";
          }
          if ($modeswitch eq "dump")
            { print "$linetime clamp sensor car2 power $ccpower watts\n"; }
        }

        if ( $ccdevid == 3107 )
        {
          if (($modeswitch eq "process") && ($linetime > $timelastccclampcar))
          {
            $timelastccclampcar = $linetime;
            $output = `rrdtool update $rrddirectory/ccclampwattscar.rrd $linetime:$ccpower`;
            $output2 = `${influxcmd} '${influxurl}write?db=${influxdb}' --data-binary 'car_charger value=${ccpower} ${linetime}000000000\n'`;
            if (length $output)
              { chomp $output; print LOGFILE "got error $output..."; }
            else
              { print CCCLAMPCAR "$linetime $ccpower\n"; }
          }
          if ($modeswitch eq "dump")
            { print "$linetime clamp sensor car power $ccpower watts\n"; }
        }



        if ( $ccdevid == 910 )
        {
          if (($modeswitch eq "process") && ($linetime > $timelastccclampheat))
          {
            $timelastccclampheat = $linetime;
            $output = `rrdtool update $rrddirectory/ccclampwattsheating.rrd $linetime:$ccpower`;
            $output2 = `${influxcmd} '${influxurl}write?db=${influxdb}' --data-binary 'central_heating value=${ccpower} ${linetime}000000000\n'`;
            if (length $output)
              { chomp $output; print LOGFILE "got error $output..."; }
            else
              { print CCCLAMPHEAT "$linetime $ccpower\n"; }
          }
          if ($modeswitch eq "dump")
            { print "$linetime clamp sensor heating power $ccpower watts\n"; }
        }

        if ( $ccdevid == 1090 )
        {
          if (($modeswitch eq "process") && ($linetime > $timelastccclampcook))
          {
            $timelastccclampcook = $linetime;
            $output = `rrdtool update $rrddirectory/ccclampwattscooker.rrd $linetime:$ccpower`;
            $output2 = `${influxcmd} '${influxurl}write?db=${influxdb}' --data-binary 'cooker value=${ccpower} ${linetime}000000000\n'`;
            if (length $output)
             { chomp $output; print LOGFILE "got error $output..."; }
            else
              { print CCCLAMPCOOK "$linetime $ccpower\n"; }
          }
          if ($modeswitch eq "dump")
            { print "$linetime clamp sensor cooker power $ccpower watts\n"; }
        }

        if ( $ccdevid == 272 )
        {
          if (($modeswitch eq "process") && ($linetime > $timelastcciamcatpad))
          {
            $timelastcciamcatpad = $linetime;
            $output2 = `${influxcmd} '${influxurl}write?db=${influxdb}' --data-binary 'catpad value=${ccpower} ${linetime}000000000\n'`;
            print CCIAMCATPAD "$linetime $ccpower\n"; 
          }
          if ($modeswitch eq "dump")
            { print "$linetime iam catpad sensor power $ccpower watts\n"; }
        }


        if ( $ccdevid == 921 )
        {
          if (($modeswitch eq "process") && ($linetime > $timelastcciamwasher))
          {
            $timelastcciamwasher = $linetime;
            $output = `rrdtool update $rrddirectory/cciamwasher.rrd $linetime:$ccpower`;
            $output2 = `${influxcmd} '${influxurl}write?db=${influxdb}' --data-binary 'washing_machine value=${ccpower} ${linetime}000000000\n'`;
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
            $output2 = `${influxcmd} '${influxurl}write?db=${influxdb}' --data-binary 'dryer value=${ccpower} ${linetime}000000000\n'`;
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
            $output2 = `${influxcmd} '${influxurl}write?db=${influxdb}' --data-binary 'fridge value=${ccpower} ${linetime}000000000\n'`;
            if (length $output)
              { chomp $output; print LOGFILE "got error $output..."; }
            else
              { print CCIAMFRIDGE "$linetime $ccpower\n"; }
          }
          if ($modeswitch eq "dump")
            { print "$linetime iam fridge sensor power $ccpower watts\n"; }
        }

        if ( $ccdevid == 1130 )
        {
          if (($modeswitch eq "process") && ($linetime > $timelastcciamfridge2))
          {
            $timelastcciamfridge2 = $linetime;
            $output2 = `${influxcmd} '${influxurl}write?db=${influxdb}' --data-binary 'fridge2 value=${ccpower} ${linetime}000000000\n'`;
            print CCIAMFRIDGE2 "$linetime $ccpower\n"; 
          }
          if ($modeswitch eq "dump")
            { print "$linetime iam fridge2 sensor power $ccpower watts\n"; }
        }

        if ( $ccdevid == 1430 )
        {
          if (($modeswitch eq "process") && ($linetime > $timelastcciammwave))
          {
            $timelastcciammwave = $linetime;
            $output2 = `${influxcmd} '${influxurl}write?db=${influxdb}' --data-binary 'mwave value=${ccpower} ${linetime}000000000\n'`;
            print CCIAMMWAVE "$linetime $ccpower\n"; 
          }
          if ($modeswitch eq "dump")
            { print "$linetime iam mwave sensor power $ccpower watts\n"; }
        }


        if ( $ccdevid == 3214 )
        {
          if (($modeswitch eq "process") && ($linetime > $timelastcciamdwasher))
          {
            $timelastcciamdwasher = $linetime;
            $output = `rrdtool update $rrddirectory/cciamdwasher.rrd $linetime:$ccpower`;
            $output2 = `${influxcmd} '${influxurl}write?db=${influxdb}' --data-binary 'dishwasher value=${ccpower} ${linetime}000000000\n'`;
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
            $output2 = `${influxcmd} '${influxurl}write?db=${influxdb}' --data-binary 'ups_basement value=${ccpower} ${linetime}000000000\n'`;
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
            $output2 = `${influxcmd} '${influxurl}write?db=${influxdb}' --data-binary 'office_desk value=${ccpower} ${linetime}000000000\n'`;
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
            $output2 = `${influxcmd} '${influxurl}write?db=${influxdb}' --data-binary 'ups_office value=${ccpower} ${linetime}000000000\n'`;
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
            $output2 = `${influxcmd} '${influxurl}write?db=${influxdb}' --data-binary 'toaster value=${ccpower} ${linetime}000000000\n'`;
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
            $output2 = `${influxcmd} '${influxurl}write?db=${influxdb}' --data-binary 'kettle value=${ccpower} ${linetime}000000000\n'`;
            if (length $output)
              { chomp $output; print LOGFILE "got error $output..."; }
            else
              { print CCIAMKETTLE "$linetime $ccpower\n"; }
          }
          if ($modeswitch eq "dump")
            { print "$linetime iam kettle sensor power $ccpower watts\n"; }
        }

        if ( $ccdevid == 3957 )
        {
          if (($modeswitch eq "process") && ($linetime > $timelastccclamptowelrail))
          {
            $timelastccclamptowelrail = $linetime;
            $output = `rrdtool update $rrddirectory/ccclampwattstowelrail.rrd $linetime:$ccpower`;
            $output2 = `${influxcmd} '${influxurl}write?db=${influxdb}' --data-binary 'towelrail value=${ccpower} ${linetime}000000000\n'`;
            if (length $output)
              { chomp $output; print LOGFILE "got error $output..."; }
            else
              { print CCCLAMPTOWELRAIL "$linetime $ccpower\n"; }
          }
          if ($modeswitch eq "dump")
            { print "$linetime clamp towelrail sensor power $ccpower watts\n"; }
        }

        # we don't care about subsequent "Power x:" lines as they're all zero
        $midtx = 0;
      }
      else { print STDERR "$linetime got a currentcost power line without a preceding deviceid at line $linecount: @line\n"; }
    }

    # FIXME why does this never trigger??
    if ( $line[0] eq "Counter:" ) 
    {
      # we need to handle these as in the giant "if" statement for power devices above
      if ( defined $ccdevid )
      {
        $cccount = $line[1];
        
        if ( $ccdevid == 2977 )
        {
          if (($modeswitch eq "process") && ($linetime > $timelastcccountoptical)) 
          {
            $timelastcccountoptical = $linetime;
            $output = `rrdtool update $rrddirectory/cccountoptical.rrd $linetime:$cccount`;
            if (length $output) { chomp $output; print LOGFILE "got error $output..."; }
            else { print CCCOUNTOPTICAL "$linetime $cccount\n"; }
          }
          if ($modeswitch eq "dump")
            { print "$linetime optical sensor count $cccount\n"; }
        }

        if ( $ccdevid == 1039 )
        {
          if (($modeswitch eq "process") && ($linetime > $timelastcccountgas)) 
          {
            $timelastcccountgas = $linetime;
            $output = `rrdtool update $rrddirectory/cccountgas.rrd $linetime:$cccount`;
            if (length $output) { chomp $output; print LOGFILE "got error $output..."; }
            else { print CCCOUNTGAS "$linetime $cccount\n"; }
          }
          if ($modeswitch eq "dump")
            { print "$linetime gas meter sensor count $cccount\n"; }
        }
        $midtx = 0;
      }
      else { print STDERR "$linetime got a currentcost count line without a preceding deviceid at line $linecount: @line\n"; }
    }

    if ( $alien eq "1" ) { print LOGFILE "@line\n"; }
  # 
  # end of "non-tx-start line" processing
  }


}

# bad/error/corrupt files might not have any broadcasts in so linetime is undefined
if (defined $linetime)
{
  $output2 = `${influxcmd} '${influxurl}write?db=${influxdb}' --data-binary 'rtl_aliens value=${aliencount} ${linetime}000000000\n'`;
  print ALIENS "$starttime $aliencount\n";
}
else { print "ERROR bad file at $starttime\n"; }

$endtime = time();
$runtime = $endtime - $starttime;



print LOGFILE "exiting successfully after $linecount lines with $aliencount unknown tx in $runtime seconds \n\n";

close LOGFILE;
