#! /usr/bin/perl -w
#
# leafspy-process.pl - parse datafiles from leafspy
#
# this writes to rrds but not to any new logfiles, and is therefore
# safe to repeatedly re-run over the same data, as when leafspy appends
# new lines to an existing file
#
# it's called by leafspy.pl when new data arrives but can be used manually
#
# GH 2017-01-28
# begun
#

if ($ARGV[0] eq "-process")  { $modeswitch = "process"; }
if ($ARGV[0] eq "-dump")  { $modeswitch = "dump"; }
if (($ARGV[0] ne "-process") && ($ARGV[0] ne "-dump"))
{
  print "usage: [cat logfile.csv|]leafspy-process.pl -process (to add log values to rrds) or -dump (to print to stdout)\n";
  exit 1;
}

# for calculating epoch from logfile values
use Time::Local;

# symbolic references don't 'count' so we get a load of 'only used once' warnings
no warnings 'once';

$rrddirectory="/data/hm/rrd";
$logdirectory="/data/hm/log";
$logfile="leafspy-process.log";
#$lockfile="/tmp/leafspy-process.lock";

#open ERRORLOG, ">>", "$logdirectory/$errorlog" or die $!;                                             

#if ( -f $lockfile ) 
#{
#  print "FATAL: lockfile exists, exiting";
#  exit 2;
#}
#open LOCKFILE, ">", $lockfile or die $!;

$timestamp = time();                                                                                  
$starttime = $timestamp;

$regenwhlast = 0;

open LOGFILE, ">>", "$logdirectory/$logfile" or die $!;                                               

print LOGFILE "starting leafspy-process.pl at $timestamp\n";

# this will read from either stdin or a file specified on the commandline
while (<STDIN>)
{
# Leafspy pro logfile format
#Date/Time,Lat,Long,Elv,Speed,Gids,SOC,AHr,Pack Volts,Pack Amps,Max CP mV,Min CP mV,Avg CP mV,CP mV Diff,Judgment Value,Pack T1 F,Pack T1 C,Pack T2 F,Pack T2 C,Pack T3 F,Pack T3 C,Pack T4 F,Pack T4 C,CP1,CP2,CP3,CP4,CP5,CP6,CP7,CP8,CP9,CP10,CP11,CP12,CP13,CP14,CP15,CP16,CP17,CP18,CP19,CP20,CP21,CP22,CP23,CP24,CP25,CP26,CP27,CP28,CP29,CP30,CP31,CP32,CP33,CP34,CP35,CP36,CP37,CP38,CP39,CP40,CP41,CP42,CP43,CP44,CP45,CP46,CP47,CP48,CP49,CP50,CP51,CP52,CP53,CP54,CP55,CP56,CP57,CP58,CP59,CP60,CP61,CP62,CP63,CP64,CP65,CP66,CP67,CP68,CP69,CP70,CP71,CP72,CP73,CP74,CP75,CP76,CP77,CP78,CP79,CP80,CP81,CP82,CP83,CP84,CP85,CP86,CP87,CP88,CP89,CP90,CP91,CP92,CP93,CP94,CP95,CP96,12v Bat Amps,VIN,Hx,12v Bat Volts,Odo(km),QC,L1/L2,TP-FL,TP-FR,TP-RR,TP-RL,Ambient,SOH,RegenWh,BLevel,epoch time,Motor Pwr(100w),Aux Pwr(100w),A/C Pwr(250w),A/C Comp(0.1MPa),Est Pwr A/C(50w),Est Pwr Htr(250w),Plug State,Charge Mode,OBC Out Pwr,Gear,HVolt1,HVolt2,GPS Status,Power SW,BMS,OBC
# 0.39.97 (april 2017) adds 3 more fields to the end of the line: motor temperature, inverter 2 temperature, inverter 4 temperature
  @line = split(",",$_);
  $lineitems = scalar (@line);
  $datetime = $line[0];
  # silently skip the valid first line of a file (field names) without logging anything
  if ( $datetime =~ /Date\/Time/ )
    { next; }
  # first thing on a valid line is a date in format 2 digits, slash, 2 digits, slash, 4 digits
  # valid lines have 152 items on them until leafspy 0.39.97, at which point they gained 3 and have 155 items
  if ( $datetime !~ /\d{2}\/\d{2}\/\d{4}/ ) 
  {
    print "line appears corrupt, skipping\n";
    next;
  }
  if ( $lineitems < 152 ) 
  {
    print "line appears truncated, skipping\n";
    next;
  }
  ($date,$time) = split(" ",$datetime);
  ($month,$day,$year) = split("/",$date);
  ($hour,$minute,$second) = split(":",$time);
# need to form epoch from these to update rrds with
# timegm requires months in range 0-11 (!)
  $stupidmonth = $month -1;
  $linetime = timegm($second, $minute, $hour, $day, $stupidmonth, $year);

  # if it's the first line then this will be unset, so set it, we use it later 
  #  to calculate regen watts
  if (not defined ($linetimelast)) { $linetimelast = $linetime; }

  $lat = $line[1];
  $long = $line[2];
  # in units determined by the android device, from android gps 
  #  - if we select miles (which we do) as unit, as seem to get feet here
  $elevationfeet = $line[3];
  $elevation = $elevationfeet * 0.3048;
  # also in android units from android gps
  $speed = $line[4];
  # units of 80Wh of energy left in pack
  $gids = $line[5];
  # pack percent charged * 10000
  $socstupid = $line[6];
  $soc = $socstupid / 10000;
  # pack capacity in amp-hours * 10000
  $amphrstupid = $line[7];
  $amphr = $amphrstupid / 10000;
  $packvolts = $line[8];
  # current draw, negative indicated regen or charging
  $packamps = $line[9];
  # cp = cell pair, these tell us how far apart the best/worst cps are
  $maxcpmv = $line[10];
  $mincpmv = $line[11];
  $avgcpmv = $line[12];
  $cpmvdiff = $line[13];
  # judgement value only works when the pack is low and tells us which cps need replacement
  # by giving a threshold voltage below which a CP is goosed
  $judgementval = $line[14];
  # we'll ignore the fahrenheit values here
  $packtemp1 = $line[16];
  $packtemp2 = $line[18];
  # think only gen1 leafs had a temp sensor #3, ours gives text string "none"
  $packtemp3 = $line[20];
  $packtemp4 = $line[22];
  # 96 cell pair voltages in mV; negative indicates shunted for balancing
  # leaf counts cps from 1, this array from 0 - so $cp[5] is cellpair 6 etc
  @cp = @line[23..118];
  # la = leadacid - our car doesn't have this value, it's gen1 only
  $ampsla = $line[119];
  $vin = $line[120];
  # this one is actually hx - internal resistance
  $packhealth = $line[121];
  # leadacid again
  $voltsla = $line[122];
  $odomkm = $line[123];
  $odom = $odomkm * 0.621371;
  # rrdtool will choke on decimal places in the odometer value 
  #  because it's a COUNTER not a GAUGE
  $odom = int $odom;
  $quickcharges = $line[124];
  $slowcharges = $line[125];
  # tyre pressures frontleft/frontright/rearright/rearleft - read 0 if no data
  $tpfl = $line[126];
  $tpfr = $line[127];
  $tprr = $line[128];
  $tprl = $line[129];
  $ambienttempf = $line[130];
  $ambienttemp = ($ambienttempf - 32) * 5/9;
  # is this just a rounded version of packhealth1?
  $packhealth2 = $line[131];
  # we get negative numbers out of this which make rrdtool choke
  $regenwh = $line[132];
  $regenwh = abs $regenwh;
  # also i'm shit at understanding counter-type rrds so mangle this to watts
  $regenwhdiff = $regenwh - $regenwhlast;
  $timediff = $linetime - $linetimelast;
  # we have a number of watt-hours and a number of seconds
  #  "watt-hours per hour" are watts, so watt hours per second*3600 are watts
  # don't divide by zero, but set it to something first so we don't have it undefined
  # if the current value is 0, don't do anything
  $regenwatts = 0;
  if (( $timediff > 0 ) && ($regenwh > 0))
  {
    $regenwhpersec = $regenwhdiff / $timediff;
    $regenwatts = $regenwhpersec * 3600;
  }
  # phone battery in %
  $phonebatt = $line[133];
  $epochtime = $line[134];
  # drive motor power in 100w units
  $drivemotorstupid = $line[135];
  $drivemotor = $drivemotorstupid * 100;
  # auxiliaries power in 100w units
  $auxpowerstupid = $line[136];
  $auxpower = $auxpowerstupid * 100;
  # aircon power in 250w units
  #  looks like this is the sum of the "resistive heater" and "heat pump" nos
  $acpowerstupid = $line[137];
  $acpower = $acpowerstupid * 250;
  # aircon compressor high-side pressure in MPa
  $acpresstupid = $line[138];
  $acpres = $acpresstupid * 14.50377;
  # "estimated aircon power" in 50W units - ie heat pump
  $acpower2stupid = $line[139];
  $acpower2 = $acpower2stupid * 50;
  # "estimated cabin heater power" in 250W units - ie resistive heater
  $heatpowerstupid = $line[140];
  $heatpower = $heatpowerstupid * 250;
  # plug state of ac port; 0 not plugged, 1 partially plugged (!), 2 plugged
  $plugstate = $line[141];
  # charge mode; 0 not, 1 level 1 (110v), 2 level 2 (240v), 3 chademo
  $chargemode = $line[142];
  # charging power to leaf in watts
  $chargepower = $line[143];
  # gear; 0 not read, 1 park, 2 reverse, 3 netural, 4 drive, 7 b/eco
  $gear = $line[144];
  # unclear where these 2 different pack readings come from
  $packvolts2 = $line[145];
  $packvolts3 = $line[146];
  # phone gps or car gps? 
  #  01 hw avail, 02 enabled, 04 logging enabled, 08 gps on, 10 accuracy valid
  #  20 altitude valid 40 speed valid
  $gpsstate = $line[147];
  # 1 if power switch read and found active else 0
  $powerswitch = $line[148];
  # 1 if bms ecu read else 0
  $bmsecu = $line[149];
  # 1 if obc ecu read else 0
  $obcecu = $line[150];
  $debuginfo = $line[151];
  # last field of the line ends in newline
  if ( $lineitems == 152 ) { chomp $debuginfo; }
  # 0.39.97 (april 2017) adds 3 more fields to the end of the line
  if ( $lineitems == 155 ) 
  { 
    # subtract 40 from value to get degrees C!
    $motortempstupid = $line[152];
    $motortemp = $motortempstupid - 40;
    $inverter2tempstupid = $line[153];
    $inverter2temp = $inverter2tempstupid - 40;
    $inverter4tempstupid = $line[154];
    chomp $inverter4tempstupid; 
    $inverter4temp = $inverter4tempstupid - 40;
  }

  # some stuff to fix up stupid shit that leafspy has put in logs

  # we've had some spikes of this to 95C / 203F, which fucks up the graphs
  #  writing "U" to the rrd is a special value which will just enter an unknown
  if ($ambienttemp > 50 ) { $ambienttemp = "U" };

  # ignore log lines where packvolts3 goes absurdly low - must do before check below as
  #  otherwise it will intermittently attempt to do arithmetic comparison on "U".
  if ( abs ($packvolts3) < 250 ) { $packvolts3 = "U"; }
  # had some bad lines were both of these were set to the same crazy value, one negative
  if ( abs ($packvolts) == abs ($packamps) )
    { $packvolts = "U"; $packamps = "U"; $packvolts2 = "U"; $packvolts3 = "U"; }

  # had some lines where packhealth2 gets set to 0
  if ($packhealth2 == 0) { $packhealth2 = "U"; }

  # we get drive motor spikes to way over the rated max 80kW, despike these
  if ( $drivemotor > 100000 ) { $drivemotor = "U"; }

if ($modeswitch eq "process")
{
  print LOGFILE "processing line from $epochtime\n";

  @rrds = ("speed", "packamps", "drivemotor", "auxpower", "acpower", "acpres", "acpower2", "heatpower", "chargepower", "elevation", "gids", "soc", "amphr", "packvolts", "packvolts2", "packvolts3", "maxcpmv", "mincpmv", "avgcpmv", "cpmvdiff", "judgementval", "packtemp1", "packtemp2", "packtemp4", "voltsla", "packhealth", "packhealth2", "ambienttemp", "phonebatt", "regenwh", "regenwatts", "odom", "quickcharges", "slowcharges");

  # 0.39.97 (april 2017) adds 3 more fields to the end of the line   
  if ( $lineitems == 155 )
  {
#   at the moment the inverter temp ones are outputting just zeros
#    push @rrds, ("motortemp", "inverter2temp", "inverter4temp");
    push @rrds, ("motortemp");
  }
  foreach $rrd (@rrds)
  {
  #  print LOGFILE "updating rrd for $rrd...";
    if ( -f "$rrddirectory/ls-$rrd.rrd" )
    {
      # this uses a symbolic reference and is naughty
      $output = `rrdtool update $rrddirectory/ls-$rrd.rrd $epochtime:$$rrd`;
      if (length $output)
      { 
        chomp $output;
        print LOGFILE "rrd $rrd got error $output..."; 
      }
  #    print LOGFILE "ok";
    }
    else
    {
      print LOGFILE "rrd $rrd not found; skipping..."
    }
    #  print LOGFILE "; ";
  }

  # cellpairs in the @cp array are 0..95 but in the car are 1..96
  foreach $cellpairstupid (0..95)
  {
    $cellpair = $cellpairstupid + 1;
  # there seem to be failure/error modes of leafspy where it returns the voltages as negatives
    $cpvalue = abs $cp[$cellpairstupid];
  #  print LOGFILE "updating rrd for cp$cellpair...";
    if ( -f "$rrddirectory/ls-cp$cellpair.rrd" )
    {
      $output = `rrdtool update $rrddirectory/ls-cp$cellpair.rrd $epochtime:$cpvalue`;

      if (length $output)
      {
        chomp $output;
        print LOGFILE "rrd $rrd got error $output...";
      }
  #    print LOGFILE "ok";
    }
    else
    {
      print LOGFILE "rrd $rrd not found; skipping..."
    }
  #  print LOGFILE "; ";
  }
}
print LOGFILE "\n";

if ($modeswitch eq "dump")
{
  print "log line summary:\n";
  print "$year $month $day $hour $minute $second epoch $epochtime calculated epoch $linetime\n";
  print "lat $lat long $long elevation $elevation speed $speed\n";
  print "gids: $gids percent-soc: $soc amphr: $amphr volts (3 readings) $packvolts $packvolts2 $packvolts3\n";
  print "cellpairs max $maxcpmv min $mincpmv avg $avgcpmv biggest difference $cpmvdiff judgementval $judgementval\n";
  print "pack temps $packtemp1 $packtemp2 $packtemp3 $packtemp4 health1 $packhealth health2 $packhealth2 quickcharges $quickcharges slowcharges $slowcharges\n";
  print "odometer miles $odom 12v volts $voltsla outside temp $ambienttemp c\n";
  print "tyre presures front left $tpfl front right $tpfr rear left $tprl rear right $tprr\n";
  print "regen cumulative wh $regenwh regen power $regenwatts drive motor $drivemotor W aux $auxpower W\n";
  print "ac pressure $acpres psi, power $acpower W est power $acpower2 W heater est power $heatpower W\n";
  print "phone battery $phonebatt\n";
  # 0.39.97 (april 2017) adds 3 more fields to the end of the line
  if ( $lineitems == 155 )
  {
    print "new log format - motor temp $motortemp c, inverter temps $inverter2temp c $inverter4temp c\n";
  }
}


# we need these values next time round
$linetimelast = $linetime;
$regenwhlast = $regenwh;

}

$endtime = time();
$runtime = $endtime - $starttime;

print LOGFILE "exiting successfully after $runtime seconds \n\n";
#close LOCKFILE;
#unlink $lockfile;


