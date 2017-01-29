#! /usr/bin/perl -w
#
# leafspy.pl - parse datafiles from leafspy
#
# GH 2017-01-28
# begun
#
##$rrddirectory="/data/hm/rrd";
##$logdirectory="/data/hm/log";
##$logfile="leafspy.log";
##$errorlog="leafspy-errors.log";

$timestamp = time();
#$starttime = $timestamp;

#open LOGFILE, ">>", "$logdirectory/$logfile" or die $!;
#open ERRORLOG, ">>", "$logdirectory/$errorlog" or die $!;
#open TEMPLOGFILE, ">>", "$logdirectory/$templogfile" or die $!;

#print LOGFILE "starting leafspy.pl at $timestamp\n";

# FIXME locking?

# FIXME how do we get the latest file:
#  - we get one file per day, which grows


# this will read from either stdin or a file specified on the commandline

while (<>)
{
# Leafspy pro logfile format
#Date/Time,Lat,Long,Elv,Speed,Gids,SOC,AHr,Pack Volts,Pack Amps,Max CP mV,Min CP mV,Avg CP mV,CP mV Diff,Judgment Value,Pack T1 F,Pack T1 C,Pack T2 F,Pack T2 C,Pack T3 F,Pack T3 C,Pack T4 F,Pack T4 C,CP1,CP2,CP3,CP4,CP5,CP6,CP7,CP8,CP9,CP10,CP11,CP12,CP13,CP14,CP15,CP16,CP17,CP18,CP19,CP20,CP21,CP22,CP23,CP24,CP25,CP26,CP27,CP28,CP29,CP30,CP31,CP32,CP33,CP34,CP35,CP36,CP37,CP38,CP39,CP40,CP41,CP42,CP43,CP44,CP45,CP46,CP47,CP48,CP49,CP50,CP51,CP52,CP53,CP54,CP55,CP56,CP57,CP58,CP59,CP60,CP61,CP62,CP63,CP64,CP65,CP66,CP67,CP68,CP69,CP70,CP71,CP72,CP73,CP74,CP75,CP76,CP77,CP78,CP79,CP80,CP81,CP82,CP83,CP84,CP85,CP86,CP87,CP88,CP89,CP90,CP91,CP92,CP93,CP94,CP95,CP96,12v Bat Amps,VIN,Hx,12v Bat Volts,Odo(km),QC,L1/L2,TP-FL,TP-FR,TP-RR,TP-RL,Ambient,SOH,RegenWh,BLevel,epoch time,Motor Pwr(100w),Aux Pwr(100w),A/C Pwr(250w),A/C Comp(0.1MPa),Est Pwr A/C(50w),Est Pwr Htr(250w),Plug State,Charge Mode,OBC Out Pwr,Gear,HVolt1,HVolt2,GPS Status,Power SW,BMS,OBC
  @line = split(",",$_);
  $lineitems = scalar (@line);
  $datetime = $line[0];
  # silently skip the valid first line of a file (field names) without logging anything
  if ( $datetime =~ /Date\/Time/ )
    { next; }
  # first thing on a valid line is a date in format 2 digits, slash, 2 digits, slash, 4 digits
  # valid lines have 152 items on them
  if (( $datetime !~ /\d{2}\/\d{2}\/\d{4}/ ) || ( $lineitems != 152))
  {
    print "line appears corrupt, skipping\n";
    next;
  }
  ($date,$time) = split(" ",$datetime);
  ($month,$day,$year) = split("/",$date);
  ($hour,$minute,$second) = split(":",$time);
  $lat = $line[1];
  $long = $line[2];
  # in units determined by the android device, from android gps
  $elevation = $line[3];
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
  $packhealth = $line[121];
  # leadacid again
  $voltsla = $line[122];
  $odometerkm = $line[123];
  $odometermiles = $odometerkm * 0.621371;
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
  $regenwh = $line[132];
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

  print "log line summary:\n";
  print "$year $month $day $hour $minute $second epoch $epochtime\n";
  print "lat $lat long $long elevation $elevation speed $speed\n";
  print "gids $gids state-of-charge $soc amp capacity $amphr volts (3 readings) $packvolts $packvolts2 $packvolts3 amps $packamps\n";
  print "cellpairs max $maxcpmv min $mincpmv avg $avgcpmv biggest difference $cpmvdiff judgementval $judgementval\n";
  print "pack temps $packtemp1 $packtemp2 $packtemp3 $packtemp4 health1 $packhealth health2 $packhealth2 quickcharges $quickcharges slowcharges $slowcharges\n";
  print "vin $vin odometer miles $odometermiles 12v volts $voltsla outside temp $ambienttemp\n";
  print "tyre presures front left $tpfl front right $tpfr rear left $tprl rear right $tprr\n";
  print "regenwh $regenwh drive motor $drivemotor W aux $auxpower W\n";
  print "ac pressure $acpres psi, power $acpower W est power $acpower2 W heater est power $heatpower W\n";
  print "phone battery $phonebatt\n";

}

##print TEMPLOGFILE "$carwingsoutput";
### splitting on space splits on any kind of whitespace incl newline
##@cwoutputlines = split(" ",$carwingsoutput);

#print LOGFILE "exiting successfully\n\n";

