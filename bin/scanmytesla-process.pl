#! /usr/bin/perl -w
#
# scanmytesla-process.pl - parse datafiles from leafspy
#
### this writes to rrds but not to any new logfiles, and is therefore
### safe to repeatedly re-run over the same data, as when leafspy appends
### new lines to an existing file
#
### it's called by leafspy.pl when new data arrives but can be used manually
#
# based on leafspy-process.pl
#
# GH 2018-02-17
# begun while l and n were in london and t played happily in n's room...
#
# 2018-04-{01-04}
# while brian james and d were here, influxdb and grafana'd with the eye infection

# for calculating epoch from logfile values
use Time::Local;

##if ($ARGV[0] eq "-process")  { $modeswitch = "process"; }
if ($ARGV[0] eq "-process")  { die "process mode not implemented yet\n"; }
if ($ARGV[0] eq "-dump")  { $modeswitch = "dump"; }
if (($ARGV[0] ne "-process") && ($ARGV[0] ne "-dump"))
# we can't just accept data in a pipe because we need to examine the filename
# in order to get the starting timestamp
{
  print "usage: scanmytesla-process.pl -process (to add log values to rrds) or -dump (to print to stdout) FILENAME\n";
  exit 1;
}

$filename = $ARGV[1];
if (defined $filename)
{
  if (-f $filename)
  {
    #print "file exists!\n";
  }
  else
  {
      die "file not found: $filename \n";
  }
}
else
{
  die "no file specified\n";
}

##
### symbolic references don't 'count' so we get a load of 'only used once' warnings
##no warnings 'once';

$rrddirectory="/data/hm/rrd";
$logdirectory="/data/hm/log";
$logfile="scanmytesla-process.log";

$timestamp = time();                                                                                  
$starttime = $timestamp;


open LOGFILE, ">>", "$logdirectory/$logfile" or die $!;                                               

print LOGFILE "starting scanmytesla-process.pl at $timestamp\n";

open INPUT, "<", "$filename" or die $!;

print "opened $filename\n";

# the timestamps in the file are all relative to start time, not epoch, so we
# have to calculate the epoch of the start time using the filename, yuck

# don't quite understand this, splitting on non-numeric
# with filename in the format "All yyyy-mm-dd hh-mm-ss.csv" it should work
@line = split (/\D+/, $filename);
$lineitems = scalar(@line);
$year = $line[1];
$month = $line[2];
$day = $line[3];
$hour = $line[4];
$minute = $line[5];
$second = $line[6];
# thanks leafspy-process.pl for this bit:
# need to form epoch from these to update rrds with
# timegm requires months in range 0-11 (!)
$stupidmonth = $month -1;
# unfortunately this is going to assume UTC, we have no way to know the TZ
# influxdb assumes all-utc so this is probably right if we glue the logging
#  device to utc
$filetime = timegm($second, $minute, $hour, $day, $stupidmonth, $year);

$filetimestupid = $filetime * 1000;

# scanmytesla "all" logfile format
#
#0-4
#Time,Battery voltage,Battery current,Battery power,DC-DC current,
#5-9
#DC-DC voltage,DC-DC coolant inlet,DC-DC input power,12v systems,DC-DC output power,
#10-14
#DC-DC efficiency,400V systems,Heating/cooling,Fr torque measured,Rr/Fr torque bias,
#15-19
#Rr torque measured,Watt pedal,Fr mech power,Fr dissipation,Fr input power,
#20-24
#Fr mech power HP,Fr stator current,Fr drive power max,Mech power combined,HP combined,
#25-29
#Fr efficiency,Rr inverter 12V,Rr mech power,Rr dissipation,Rr input power,
#30-34
#Propulsion,Rr mech power HP,Rr stator current,Rr regen power max,Rr drive power max,
#35-39
#Rr efficiency,Fr torque estimate,Rr torque estimate,Speed,Consumption,
#40-44
#Rr coolant inlet,Rr inverter PCB,Rr stator,Rr DC capacitor,Rr heat sink,
#45-49
#Rr inverter,Nominal full pack,Nominal remaining,Expected remaining,Ideal remaining,
#50-54
#To charge complete,Energy buffer,SOC,Usable full pack,Usable remaining,
#55-59
#DC Charge total,AC Charge total,DC Charge,AC Charge,Charge total,
#60-64
#Discharge total,Regenerated,Energy,Discharge,Charge,
#65-69
#Regen total,Regen %,Discharge cycles,Charge cycles,Battery odometer,
#70-74
#Trip distance,Trip consumption,Fr motor RPM,Rr motor RPM,Max discharge power,
#75-79
#Max regen power,Brake pedal,Steering angle,Rated range,Typical range,
#80-84
#Full rated range,Full typical range,Last cell block updated,Front left,Front right,
#85-89
#Front drive ratio,Rear left,Rear right,Rear drive ratio,Outside temp,
#90-94
#Outside temp filtered,Inside temp,A/C air temp,Floor vent L,Floor vent R,
#95-99
#Mid vent L,Mid vent R,Louver 1,Louver 2,Louver 3,
#100-104
#Louver 4,Louver 5,Louver 6,Louver 7,Louver 8,
#105-109
#HVAC floor,HVAC mid,HVAC window,HVAC A/C,HVAC on/off,
#110-114
#HVAC fan speed,HVAC temp left,HVAC temp right,Cell temp min,Cell temp avg,
#115-119
#Cell temp max,Cell temp diff,Cell min,Cell avg,Cell max,
#120-124
#Cell diff,Cell  1 voltage,Cell  2 voltage,Cell  3 voltage,Cell 1 temp
#125-129
#Cell  4 voltage,Cell  5 voltage,Cell  6 voltage,Cell  2 temp,Cell  7 voltage,
#Cell  8 voltage,Cell  9 voltage,Cell  3 temp,Cell 10 voltage,Cell 11 voltage,Cell 12 voltage,Cell  4 temp,Cell 13 voltage,Cell 14 voltage,Cell 15 voltage,Cell  5 temp,Cell 16 voltage,Cell 17 voltage,Cell 18 voltage,Cell  6 temp,Cell 19 voltage,Cell 20 voltage,Cell 21 voltage,Cell  7 temp,Cell 22 voltage,Cell 23 voltage,Cell 24 voltage,Cell  8 temp,Cell 25 voltage,Cell 26 voltage,Cell 27 voltage,Cell  9 temp,Cell 28 voltage,Cell 29 voltage,Cell 30 voltage,Cell 10 temp,Cell 31 voltage,Cell 32 voltage,Cell 33 voltage,Cell 11 temp,Cell 34 voltage,Cell 35 voltage,Cell 36 voltage,Cell 12 temp,Cell 37 voltage,Cell 38 voltage,Cell 39 voltage,Cell 13 temp,Cell 40 voltage,Cell 41 voltage,Cell 42 voltage,Cell 14 temp,Cell 43 voltage,Cell 44 voltage,Cell 45 voltage,Cell 15 temp,Cell 46 voltage,Cell 47 voltage,Cell 48 voltage,Cell 16 temp,Cell 49 voltage,Cell 50 voltage,Cell 51 voltage,Cell 17 temp,Cell 52 voltage,Cell 53 voltage,Cell 54 voltage,Cell 18 temp,Cell 55 voltage,Cell 56 voltage,Cell 57 voltage,Cell 19 temp,Cell 58 voltage,Cell 59 voltage,Cell 60 voltage,Cell 20 temp,Cell 61 voltage,Cell 62 voltage,Cell 63 voltage,Cell 21 temp,Cell 64 voltage,Cell 65 voltage,Cell 66 voltage,Cell 22 temp,Cell 67 voltage,Cell 68 voltage,Cell 69 voltage,Cell 23 temp,Cell 70 voltage,Cell 71 voltage,Cell 72 voltage,Cell 24 temp,Cell 73 voltage,Cell 74 voltage,Cell 75 voltage,Cell 25 temp,Cell 76 voltage,Cell 77 voltage,Cell 78 voltage,Cell 26 temp,Cell 79 voltage,Cell 80 voltage,Cell 81 voltage,Cell 27 temp,Cell 82 voltage,Cell 83 voltage,Cell 84 voltage,Cell 28 temp,Cell 85 voltage,Cell 86 voltage,Cell 87 voltage,Cell 29 temp,Cell 88 voltage,Cell 89 voltage,Cell 90 voltage,Cell 30 temp,Cell 91 voltage,Cell 92 voltage,Cell 93 voltage,Cell 31 temp,Cell 94 voltage,Cell 95 voltage,Cell 96 voltage,Cell 32 temp,
#
#
#
$influxcmdline="";
$influxcmdlinevolts="";
$logversion="";
while (<INPUT>)
{
  @line = split(",",$_);
  $lineitems = scalar (@line);
  $timeoffset = $line[0];
  # the first line of the file starts like this
  if ( $timeoffset =~ /Time/ ) 
  { 
    # scanmytesla 1.4.0(ish), we call this "version 1"
    if (( $lineitems == 250) && ($line[4] =~/DC-DC current/ ))
    {
      $logversion = 1;
      $logoffset = 0;
      print "file is version 1 format\n";
    }
    # scanmytesla 1.4.3 20180321 added 2 new values, now 252 items per line, we call this "version 2"
    if (( $lineitems == 252) && ($line[4] =~/Battery inlet/ ))
    {
      $logversion = 2;
      $logoffset = 2;
      print "file is version 2 format\n";
    }
    # if we didn't positively identify a log format, quit
    if ( $logversion eq "" ) { die "first line of file appears corrupt or unknown scanmytesla format\n"; }
    # skip on to the next line as there's nothing else to do 
    next; 
  }
  # first thing on a valid line is a number
  if ( $timeoffset !~ /\d/ ) { print "line appears corrupt, skipping\n"; next; }
  if ( $lineitems < 250 ) { print "line appears truncated, skipping\n"; next; }
  # epoch format timestamp we'll use to feed the db
  $timestampline = $filetimestupid + $timeoffset;
  $battvolts = $line[1];
  $battamps = $line[2];
  $battpower = $line[3];    # kW
  if ( $logversion == 2 )
  {
    # coolant temperature after battery heater, entering battery
    $batteryinlettemp = $line[4];
    # coolant temp from crossover valve towards du
    $ptinlettemp = $line[5];
  }
  $dcdcamps = $line[$logoffset+4];
  $dcdcvolts = $line[$logoffset+5];
  $dcdccoolantin = $line[$logoffset+6];
  $dcdcinpower = $line[$logoffset+7];
  $sys12v = $line[$logoffset+8];
  $dcdcoutpower = $line[$logoffset+9];
  $dcdcefficiency = $line[$logoffset+10];
  $sys400v = $line[$logoffset+11];
  $heatingcooling = $line[$logoffset+12];
  $torquefr = $line[$logoffset+13];
  $torquebias = $line[$logoffset+14];
  $torquerr = $line[$logoffset+15];
  $wattpedal = $line[$logoffset+16];
  $mechpowerfr = $line[$logoffset+17];
  $dissipationfr = $line[$logoffset+18];
  $inpowerfr = $line[$logoffset+19];
  $hpfr = $line[$logoffset+20];  
  $statorampsfr = $line[$logoffset+21];
  $inpowerrr = $line[$logoffset+29];
  $propulsion = $line[$logoffset+30];
  $hprr = $line[$logoffset+31];
  $statorampsrr = $line[$logoffset+32];
  $regenpowermaxrr = $line[$logoffset+33];
  $drivepowermaxrr = $line[$logoffset+34];
  $efficiencyrr = $line[$logoffset+35];
  $torqueestfr = $line[$logoffset+36];
  $torqueestrr = $line[$logoffset+37];
  $speed = $line[$logoffset+38];
  $consumption = $line[$logoffset+39];
  $coolantinletrr = $line[$logoffset+40];
  $inverterpcbrr = $line[$logoffset+41];
  $statorrr = $line[$logoffset+42];
  $dccapacitorrr = $line[$logoffset+43];
  $heatsinkrr = $line[$logoffset+44];
  $inverterrr = $line[$logoffset+45];
  # only see this while charging?
  $chargetocomplete = $line[$logoffset+50];
  # "permanently" reads 4 - kwh anti-bricking reserve?
  $energybuffer = $line[$logoffset+51];
  $soc = $line[$logoffset+52];
  $packfullusable = $line[$logoffset+53];
  $packremainingusable = $line[$logoffset+54];
  $chargetotaldc = $line[$logoffset+55];
  $chargetotalac = $line[$logoffset+56];
  $chargedc = $line[$logoffset+57];
  $chargeac = $line[$logoffset+58];
  $chargetotal = $line[$logoffset+59];
  $dischargetotal = $line[$logoffset+60]; 

##60-64
##Discharge total,Regenerated,Energy,Discharge,Charge,
##65-69
##Regen total,Regen %,Discharge cycles,Charge cycles,Battery odometer, 

  $battodom = $line[$logoffset+69];
  $frrpm = $line[$logoffset+72];
  $rrrpm = $line[$logoffset+73];
  $tripdistance = $line[$logoffset+75];

  $tempoutfilt = $line[$logoffset+90];
  $tempin = $line[$logoffset+91];
  $tempacair = $line[$logoffset+92];
  $floorventl = $line[$logoffset+93];
  $floorventr = $line[$logoffset+94];

  # these refer to vents being enabled - 1 on 0 off
  $hvacfloor = $line[$logoffset+105];
  $hvacmid = $line[$logoffset+106];
  $hvacwindow = $line[$logoffset+107];

  $celltempmin = $line[$logoffset+113];
  $celltempavg = $line[$logoffset+114];
  $celltempmax = $line[$logoffset+115];
  $celltempdiff = $line[$logoffset+116];
  $cellmin = $line[$logoffset+117];
  $cellavg = $line[$logoffset+118];
  $cellmax = $line[$logoffset+119];
  $celldiff = $line[$logoffset+120];
  $cellvolts01 = $line[$logoffset+121];
  $cellvolts02 = $line[$logoffset+122];
  $cellvolts03 = $line[$logoffset+123];
  $celltemp01 = $line[$logoffset+124];
  $cellvolts04 = $line[$logoffset+125];
  $cellvolts05 = $line[$logoffset+126];
  $cellvolts06 = $line[$logoffset+127];
  $celltemp02 = $line[$logoffset+128];
  $cellvolts07 = $line[$logoffset+129];
  $cellvolts08 = $line[$logoffset+130];
  $cellvolts09 = $line[$logoffset+131];
  $celltemp03 = $line[$logoffset+132];
  $cellvolts10 = $line[$logoffset+133];
  $cellvolts11 = $line[$logoffset+134];
  $cellvolts12 = $line[$logoffset+135];
  $celltemp04 = $line[$logoffset+136];
  $cellvolts13 = $line[$logoffset+137];
  $cellvolts14 = $line[$logoffset+138];
  $cellvolts15 = $line[$logoffset+139];
  $celltemp05 = $line[$logoffset+140];
  $cellvolts16 = $line[$logoffset+141];
  $cellvolts17 = $line[$logoffset+142];
  $cellvolts18 = $line[$logoffset+143];
  $celltemp06 = $line[$logoffset+144];
  $cellvolts19 = $line[$logoffset+145];
  $cellvolts20 = $line[$logoffset+146];
  $cellvolts21 = $line[$logoffset+147];
  $celltemp07 = $line[$logoffset+148];
  $cellvolts22 = $line[$logoffset+149];
  $cellvolts23 = $line[$logoffset+150];
  $cellvolts24 = $line[$logoffset+151];
  $celltemp08 = $line[$logoffset+152];
  $cellvolts25 = $line[$logoffset+153];
  $cellvolts26 = $line[$logoffset+154];
  $cellvolts27 = $line[$logoffset+155];
  $celltemp09 = $line[$logoffset+156];
  $cellvolts28 = $line[$logoffset+157];
  $cellvolts29 = $line[$logoffset+158];
  $cellvolts30 = $line[$logoffset+159];
  $celltemp10 = $line[$logoffset+160];
  $cellvolts31 = $line[$logoffset+161];
  $cellvolts32 = $line[$logoffset+162];
  $cellvolts33 = $line[$logoffset+163];
  $celltemp11 = $line[$logoffset+164];
  $cellvolts34 = $line[$logoffset+165];
  $cellvolts35 = $line[$logoffset+166];
  $cellvolts36 = $line[$logoffset+167];
  $celltemp12 = $line[$logoffset+168];
  $cellvolts37 = $line[$logoffset+169];
  $cellvolts38 = $line[$logoffset+170];
  $cellvolts39 = $line[$logoffset+171];
  $celltemp13 = $line[$logoffset+172];
  $cellvolts40 = $line[$logoffset+173];
  $cellvolts41 = $line[$logoffset+174];
  $cellvolts42 = $line[$logoffset+175];
  $celltemp14 = $line[$logoffset+176];
  $cellvolts43 = $line[$logoffset+177];
  $cellvolts44 = $line[$logoffset+178];
  $cellvolts45 = $line[$logoffset+179];
  $celltemp15 = $line[$logoffset+180];
  $cellvolts46 = $line[$logoffset+181];
  $cellvolts47 = $line[$logoffset+182];
  $cellvolts48 = $line[$logoffset+183];
  $celltemp16 = $line[$logoffset+184];
  $cellvolts49 = $line[$logoffset+185];
  $cellvolts50 = $line[$logoffset+186];
  $cellvolts51 = $line[$logoffset+187];
  $celltemp17 = $line[$logoffset+188];
  $cellvolts52 = $line[$logoffset+189];
  $cellvolts53 = $line[$logoffset+190];
  $cellvolts54 = $line[$logoffset+191];
  $celltemp18 = $line[$logoffset+192];
  $cellvolts55 = $line[$logoffset+193];
  $cellvolts56 = $line[$logoffset+194];
  $cellvolts57 = $line[$logoffset+195];
  $celltemp19 = $line[$logoffset+196];
  $cellvolts58 = $line[$logoffset+197];
  $cellvolts59 = $line[$logoffset+198];
  $cellvolts60 = $line[$logoffset+199];
  $celltemp20 = $line[$logoffset+200];
  $cellvolts61 = $line[$logoffset+201];
  $cellvolts62 = $line[$logoffset+202];
  $cellvolts63 = $line[$logoffset+203];
  $celltemp21 = $line[$logoffset+204];
  $cellvolts64 = $line[$logoffset+205];
  $cellvolts65 = $line[$logoffset+206];
  $cellvolts66 = $line[$logoffset+207];
  $celltemp22 = $line[$logoffset+208];
  $cellvolts67 = $line[$logoffset+209];
  $cellvolts68 = $line[$logoffset+210];
  $cellvolts69 = $line[$logoffset+211];
  $celltemp23 = $line[$logoffset+212];
  $cellvolts70 = $line[$logoffset+213];
  $cellvolts71 = $line[$logoffset+214];
  $cellvolts72 = $line[$logoffset+215];
  $celltemp24 = $line[$logoffset+216];
  $cellvolts73 = $line[$logoffset+217];
  $cellvolts74 = $line[$logoffset+218];
  $cellvolts75 = $line[$logoffset+219];
  $celltemp25 = $line[$logoffset+220];
  $cellvolts76 = $line[$logoffset+221];
  $cellvolts77 = $line[$logoffset+222];
  $cellvolts78 = $line[$logoffset+223];
  $celltemp26 = $line[$logoffset+224];
  $cellvolts79 = $line[$logoffset+225];
  $cellvolts80 = $line[$logoffset+226];
  $cellvolts81 = $line[$logoffset+227];
  $celltemp27 = $line[$logoffset+228];
  $cellvolts82 = $line[$logoffset+229];
  $cellvolts83 = $line[$logoffset+230];
  $cellvolts84 = $line[$logoffset+231];
  $celltemp28 = $line[$logoffset+232];
  $cellvolts85 = $line[$logoffset+233];
  $cellvolts86 = $line[$logoffset+234];
  $cellvolts87 = $line[$logoffset+235];
  $celltemp29 = $line[$logoffset+236];
  $cellvolts88 = $line[$logoffset+237];
  $cellvolts89 = $line[$logoffset+238];
  $cellvolts90 = $line[$logoffset+239];
  $celltemp30 = $line[$logoffset+240];
  $cellvolts91 = $line[$logoffset+241];
  $cellvolts92 = $line[$logoffset+242];
  $cellvolts93 = $line[$logoffset+243];
  $celltemp31 = $line[$logoffset+244];
  $cellvolts94 = $line[$logoffset+245];
  $cellvolts95 = $line[$logoffset+246];
  $cellvolts96 = $line[$logoffset+247];
  $celltemp32 = $line[$logoffset+248];


  if ( ! $battvolts eq "" ) { $influxcmdline .= "battery_voltage value=${battvolts} ${timestampline}000000\n"; }
  if ( ! $battamps eq "" ) { $influxcmdline .= "battery_amps value=${battamps} ${timestampline}000000\n"; }
  if ( ! $battpower eq "" ) { $influxcmdline .= "battery_power value=${battpower} ${timestampline}000000\n"; }
# duplicate of watts really, we could scrap this if the db is too full
  if ( ! $dcdcamps eq "" ) { $influxcmdline .= "dcdc_amps value=${dcdcamps} ${timestampline}000000\n"; }
  if ( ! $dcdcvolts eq "" ) { $influxcmdline .= "dcdc_volts value=${dcdcvolts} ${timestampline}000000\n"; }
  if ( ! $dcdccoolantin eq "" ) { $influxcmdline .= "dcdc_coolantin value=${dcdccoolantin} ${timestampline}000000\n"; }
  if ( ! $sys12v eq "" ) { $influxcmdline .= "dcdc_watts value=${sys12v} ${timestampline}000000\n"; }
# these don't seem very interesting, efficiency seems reasonable at 90ish-%
#  if ( ! $dcdcoutpower eq "" ) { $influxcmdline .= "dcdc_amps value=${dcdcoutpower} ${timestampline}000000\n"; }
#  if ( ! $dcdcefficiency eq "" ) { $influxcmdline .= "dcdc_amps value=${dcdcefficiency} ${timestampline}000000\n"; }
  if ( ! $sys400v eq "" ) { $influxcmdline .= "hv_kw value=${sys400v} ${timestampline}000000\n"; }
# units make no sense here, it goes up to 40 which means it can't be kw
  if ( ! $heatingcooling eq "" ) { $influxcmdline .= "hvac value=${heatingcooling} ${timestampline}000000\n"; }


  if ( ! $batteryinlettemp eq "" ) { $influxcmdline .= "temp_battery_coolantin value=${batteryinlettemp} ${timestampline}000000\n"; }
  if ( ! $ptinlettemp eq "" ) { $influxcmdline .= "temp_pt_coolantin value=${ptinlettemp} ${timestampline}000000\n"; }

  if ( ! $battodom eq "")
  { $influxcmdline .= "battery_odometer value=${battodom} ${timestampline}000000\n"; }
  # torque - units?? bias - percent rear?
  if ( ! $torquefr eq "" ) { $influxcmdline .= "torque_front value=${torquefr} ${timestampline}000000\n"; }
  if ( ! $torquerr eq "" ) { $influxcmdline .= "torque_rear value=${torquerr} ${timestampline}000000\n"; }
  if ( ! $torquebias eq "" ) { $influxcmdline .= "torque_bias value=${torquebias} ${timestampline}000000\n"; }

  if ( ! $hpfr eq "" ) { $influxcmdline .= "hp_front value=${hpfr} ${timestampline}000000\n"; }
  if ( ! $hprr eq "" ) { $influxcmdline .= "hp_rear value=${hprr} ${timestampline}000000\n"; }

  # units? bit wtf
  # 
#  if ( ! $wattpedal eq "" ) { $influxcmdline .= "watt_pedal value=${wattpedal} ${timestampline}000000\n"; print "wpedal $wattpedal\n"; }
#  if ( ! $mechpowerfr eq "" ) { $influxcmdline .= "mechpower_front value=${mechpowerfr} ${timestampline}000000\n"; print "powerfr $mechpowerfr\n"; }
  # think these all deg C
  if ( ! $statorrr eq "" ) { $influxcmdline .= "temp_stator_rear value=${statorrr} ${timestampline}000000\n"; }
  if ( ! $dccapacitorrr eq "" ) { $influxcmdline .= "temp_dccapacitor_rear value=${dccapacitorrr} ${timestampline}000000\n"; }
  if ( ! $heatsinkrr eq "" ) { $influxcmdline .= "temp_heatsink_rear value=${heatsinkrr} ${timestampline}000000\n"; }
  if ( ! $inverterrr eq "" ) { $influxcmdline .= "temp_inverter_rear value=${inverterrr} ${timestampline}000000\n"; }

# permanently 4 (kwh) ?
  if ( ! $energybuffer eq "" ) { $influxcmdline .= "pack_energy_buffer value=${energybuffer} ${timestampline}000000\n"; }
  if ( ! $soc eq "" ) { $influxcmdline .= "pack_soc value=${soc} ${timestampline}000000\n"; }
  if ( ! $packfullusable eq "" ) { $influxcmdline .= "pack_usable_full value=${packfullusable} ${timestampline}000000\n"; }
  if ( ! $packremainingusable eq "" ) { $influxcmdline .= "pack_usable_remain value=${packremainingusable} ${timestampline}000000\n"; }
  if ( ! $chargetotaldc eq "" ) { $influxcmdline .= "pack_charge_total_dc value=${chargetotaldc} ${timestampline}000000\n"; }
  if ( ! $chargetotalac eq "" ) { $influxcmdline .= "pack_charge_total_ac value=${chargetotalac} ${timestampline}000000\n"; }
  if ( ! $chargedc eq "" ) { $influxcmdline .= "pack_charge_dc value=${chargedc} ${timestampline}000000\n"; }
  if ( ! $chargeac eq "" ) { $influxcmdline .= "pack_charge_ac value=${chargeac} ${timestampline}000000\n"; }
  if ( ! $chargetotal eq "" ) { $influxcmdline .= "pack_charge_total value=${chargetotal} ${timestampline}000000\n"; }
  if ( ! $dischargetotal eq "" ) { $influxcmdline .= "pack_discharge_total value=${dischargetotal} ${timestampline}000000\n"; }

# km/h ?
  if ( ! $speed eq "" ) { $influxcmdline .= "speed value=${speed} ${timestampline}000000\n"; }
# wh/km
#  if ( ! $consumption eq "" ) { $influxcmdline .= "consumption value=${consumption} ${timestampline}000000\n"; print "consumption $consumption\n"; }
#  never reads?
  if ( ! $coolantinletrr eq "" ) { $influxcmdline .= "temp_inlet_rear value=${coolantinletrr} ${timestampline}000000\n"; print "coolant rear $coolantinletrr\n"; } 
  if ( ! $inverterpcbrr eq "" ) { $influxcmdline .= "temp_inverterpcb_rear value=${inverterpcbrr} ${timestampline}000000\n"; }

  # nonsense values spike graphs
  if ( ! $celltempmin eq "" ) { if ( $celltempmin > -20 ) { $influxcmdline .= "cell_temp_min value=${celltempmin} ${timestampline}000000\n"; } }
  if ( ! $celltempavg eq "" ) { $influxcmdline .= "cell_temp_avg value=${celltempavg} ${timestampline}000000\n"; }
  if ( ! $celltempmax eq "" ) { $influxcmdline .= "cell_temp_max value=${celltempmax} ${timestampline}000000\n"; }
  # nonsense values spike graphs
  if ( ! $celltempdiff eq "" ) { if ( $celltempdiff < 30 ) { $influxcmdline .= "cell_temp_diff value=${celltempdiff} ${timestampline}000000\n"; } }

  if ( ! $celltemp01 eq "" ) { if ( $celltemp01 > -20 ) { $influxcmdline .= "cell_temp_01 value=${celltemp01} ${timestampline}000000\n"; } }
  if ( ! $celltemp02 eq "" ) { if ( $celltemp02 > -20 ) { $influxcmdline .= "cell_temp_02 value=${celltemp02} ${timestampline}000000\n"; } }
  if ( ! $celltemp03 eq "" ) { if ( $celltemp03 > -20 ) { $influxcmdline .= "cell_temp_03 value=${celltemp03} ${timestampline}000000\n"; } }
  if ( ! $celltemp04 eq "" ) { if ( $celltemp04 > -20 ) { $influxcmdline .= "cell_temp_04 value=${celltemp04} ${timestampline}000000\n"; } }
  if ( ! $celltemp05 eq "" ) { if ( $celltemp05 > -20 ) { $influxcmdline .= "cell_temp_05 value=${celltemp05} ${timestampline}000000\n"; } }
  if ( ! $celltemp06 eq "" ) { if ( $celltemp06 > -20 ) { $influxcmdline .= "cell_temp_06 value=${celltemp06} ${timestampline}000000\n"; } }
  if ( ! $celltemp07 eq "" ) { if ( $celltemp07 > -20 ) { $influxcmdline .= "cell_temp_07 value=${celltemp07} ${timestampline}000000\n"; } }
  if ( ! $celltemp08 eq "" ) { if ( $celltemp08 > -20 ) { $influxcmdline .= "cell_temp_08 value=${celltemp08} ${timestampline}000000\n"; } }
  if ( ! $celltemp09 eq "" ) { if ( $celltemp09 > -20 ) { $influxcmdline .= "cell_temp_09 value=${celltemp09} ${timestampline}000000\n"; } }
  if ( ! $celltemp10 eq "" ) { if ( $celltemp10 > -20 ) { $influxcmdline .= "cell_temp_10 value=${celltemp10} ${timestampline}000000\n"; } }
  if ( ! $celltemp11 eq "" ) { if ( $celltemp11 > -20 ) { $influxcmdline .= "cell_temp_11 value=${celltemp11} ${timestampline}000000\n"; } }
  if ( ! $celltemp12 eq "" ) { if ( $celltemp12 > -20 ) { $influxcmdline .= "cell_temp_12 value=${celltemp12} ${timestampline}000000\n"; } }
  if ( ! $celltemp13 eq "" ) { if ( $celltemp13 > -20 ) { $influxcmdline .= "cell_temp_13 value=${celltemp13} ${timestampline}000000\n"; } }
  if ( ! $celltemp14 eq "" ) { if ( $celltemp14 > -20 ) { $influxcmdline .= "cell_temp_14 value=${celltemp14} ${timestampline}000000\n"; } }
  if ( ! $celltemp15 eq "" ) { if ( $celltemp15 > -20 ) { $influxcmdline .= "cell_temp_15 value=${celltemp15} ${timestampline}000000\n"; } }
  if ( ! $celltemp16 eq "" ) { if ( $celltemp16 > -20 ) { $influxcmdline .= "cell_temp_16 value=${celltemp16} ${timestampline}000000\n"; } }
  if ( ! $celltemp17 eq "" ) { if ( $celltemp17 > -20 ) { $influxcmdline .= "cell_temp_17 value=${celltemp17} ${timestampline}000000\n"; } }
  if ( ! $celltemp18 eq "" ) { if ( $celltemp18 > -20 ) { $influxcmdline .= "cell_temp_18 value=${celltemp18} ${timestampline}000000\n"; } }
  if ( ! $celltemp19 eq "" ) { if ( $celltemp19 > -20 ) { $influxcmdline .= "cell_temp_19 value=${celltemp19} ${timestampline}000000\n"; } }
  if ( ! $celltemp20 eq "" ) { if ( $celltemp20 > -20 ) { $influxcmdline .= "cell_temp_20 value=${celltemp20} ${timestampline}000000\n"; } }
  if ( ! $celltemp21 eq "" ) { if ( $celltemp21 > -20 ) { $influxcmdline .= "cell_temp_21 value=${celltemp21} ${timestampline}000000\n"; } }
  if ( ! $celltemp22 eq "" ) { if ( $celltemp22 > -20 ) { $influxcmdline .= "cell_temp_22 value=${celltemp22} ${timestampline}000000\n"; } }
  if ( ! $celltemp23 eq "" ) { if ( $celltemp23 > -20 ) { $influxcmdline .= "cell_temp_23 value=${celltemp23} ${timestampline}000000\n"; } }
  if ( ! $celltemp24 eq "" ) { if ( $celltemp24 > -20 ) { $influxcmdline .= "cell_temp_24 value=${celltemp24} ${timestampline}000000\n"; } }
  if ( ! $celltemp25 eq "" ) { if ( $celltemp25 > -20 ) { $influxcmdline .= "cell_temp_25 value=${celltemp25} ${timestampline}000000\n"; } }
  if ( ! $celltemp26 eq "" ) { if ( $celltemp26 > -20 ) { $influxcmdline .= "cell_temp_26 value=${celltemp26} ${timestampline}000000\n"; } }
  if ( ! $celltemp27 eq "" ) { if ( $celltemp27 > -20 ) { $influxcmdline .= "cell_temp_27 value=${celltemp27} ${timestampline}000000\n"; } }
  if ( ! $celltemp28 eq "" ) { if ( $celltemp28 > -20 ) { $influxcmdline .= "cell_temp_28 value=${celltemp28} ${timestampline}000000\n"; } }
  if ( ! $celltemp29 eq "" ) { if ( $celltemp29 > -20 ) { $influxcmdline .= "cell_temp_29 value=${celltemp29} ${timestampline}000000\n"; } }
  if ( ! $celltemp30 eq "" ) { if ( $celltemp30 > -20 ) { $influxcmdline .= "cell_temp_30 value=${celltemp30} ${timestampline}000000\n"; } }
  if ( ! $celltemp31 eq "" ) { if ( $celltemp31 > -20 ) { $influxcmdline .= "cell_temp_31 value=${celltemp31} ${timestampline}000000\n"; } }
  if ( ! $celltemp32 eq "" ) { if ( $celltemp32 > -20 ) { $influxcmdline .= "cell_temp_32 value=${celltemp32} ${timestampline}000000\n"; } }

  if ( ! $cellvolts01 eq "" ) { if ( ( $cellvolts01 > 2) && ( $cellvolts01 < 5 )) { $influxcmdlinevolts .= "cell_volts_01 value=${cellvolts01} ${timestampline}000000\n"; } }
  if ( ! $cellvolts02 eq "" ) { if ( ( $cellvolts02 > 2) && ( $cellvolts02 < 5 )) { $influxcmdlinevolts .= "cell_volts_02 value=${cellvolts02} ${timestampline}000000\n"; } }
  if ( ! $cellvolts03 eq "" ) { if ( ( $cellvolts03 > 2) && ( $cellvolts03 < 5 )) { $influxcmdlinevolts .= "cell_volts_03 value=${cellvolts03} ${timestampline}000000\n"; } }
  if ( ! $cellvolts04 eq "" ) { if ( ( $cellvolts04 > 2) && ( $cellvolts04 < 5 )) { $influxcmdlinevolts .= "cell_volts_04 value=${cellvolts04} ${timestampline}000000\n"; } }
  if ( ! $cellvolts05 eq "" ) { if ( ( $cellvolts05 > 2) && ( $cellvolts05 < 5 )) { $influxcmdlinevolts .= "cell_volts_05 value=${cellvolts05} ${timestampline}000000\n"; } }
  if ( ! $cellvolts06 eq "" ) { if ( ( $cellvolts06 > 2) && ( $cellvolts06 < 5 )) { $influxcmdlinevolts .= "cell_volts_06 value=${cellvolts06} ${timestampline}000000\n"; } }
  if ( ! $cellvolts07 eq "" ) { if ( ( $cellvolts07 > 2) && ( $cellvolts07 < 5 )) { $influxcmdlinevolts .= "cell_volts_07 value=${cellvolts07} ${timestampline}000000\n"; } }
  if ( ! $cellvolts08 eq "" ) { if ( ( $cellvolts08 > 2) && ( $cellvolts08 < 5 )) { $influxcmdlinevolts .= "cell_volts_08 value=${cellvolts08} ${timestampline}000000\n"; } }
  if ( ! $cellvolts09 eq "" ) { if ( ( $cellvolts09 > 2) && ( $cellvolts09 < 5 )) { $influxcmdlinevolts .= "cell_volts_09 value=${cellvolts09} ${timestampline}000000\n"; } }
  if ( ! $cellvolts10 eq "" ) { if ( ( $cellvolts10 > 2) && ( $cellvolts10 < 5 )) { $influxcmdlinevolts .= "cell_volts_10 value=${cellvolts10} ${timestampline}000000\n"; } }
  if ( ! $cellvolts11 eq "" ) { if ( ( $cellvolts11 > 2) && ( $cellvolts11 < 5 )) { $influxcmdlinevolts .= "cell_volts_11 value=${cellvolts11} ${timestampline}000000\n"; } }
  if ( ! $cellvolts12 eq "" ) { if ( ( $cellvolts12 > 2) && ( $cellvolts12 < 5 )) { $influxcmdlinevolts .= "cell_volts_12 value=${cellvolts12} ${timestampline}000000\n"; } }
  if ( ! $cellvolts13 eq "" ) { if ( ( $cellvolts13 > 2) && ( $cellvolts13 < 5 )) { $influxcmdlinevolts .= "cell_volts_13 value=${cellvolts13} ${timestampline}000000\n"; } }
  if ( ! $cellvolts14 eq "" ) { if ( ( $cellvolts14 > 2) && ( $cellvolts14 < 5 )) { $influxcmdlinevolts .= "cell_volts_14 value=${cellvolts14} ${timestampline}000000\n"; } }
  if ( ! $cellvolts15 eq "" ) { if ( ( $cellvolts15 > 2) && ( $cellvolts15 < 5 )) { $influxcmdlinevolts .= "cell_volts_15 value=${cellvolts15} ${timestampline}000000\n"; } }
  if ( ! $cellvolts16 eq "" ) { if ( ( $cellvolts16 > 2) && ( $cellvolts16 < 5 )) { $influxcmdlinevolts .= "cell_volts_16 value=${cellvolts16} ${timestampline}000000\n"; } }
  if ( ! $cellvolts17 eq "" ) { if ( ( $cellvolts17 > 2) && ( $cellvolts17 < 5 )) { $influxcmdlinevolts .= "cell_volts_17 value=${cellvolts17} ${timestampline}000000\n"; } }
  if ( ! $cellvolts18 eq "" ) { if ( ( $cellvolts18 > 2) && ( $cellvolts18 < 5 )) { $influxcmdlinevolts .= "cell_volts_18 value=${cellvolts18} ${timestampline}000000\n"; } }
  if ( ! $cellvolts19 eq "" ) { if ( ( $cellvolts19 > 2) && ( $cellvolts19 < 5 )) { $influxcmdlinevolts .= "cell_volts_19 value=${cellvolts19} ${timestampline}000000\n"; } }
  if ( ! $cellvolts20 eq "" ) { if ( ( $cellvolts20 > 2) && ( $cellvolts20 < 5 )) { $influxcmdlinevolts .= "cell_volts_20 value=${cellvolts20} ${timestampline}000000\n"; } }
  if ( ! $cellvolts21 eq "" ) { if ( ( $cellvolts21 > 2) && ( $cellvolts21 < 5 )) { $influxcmdlinevolts .= "cell_volts_21 value=${cellvolts21} ${timestampline}000000\n"; } }
  if ( ! $cellvolts22 eq "" ) { if ( ( $cellvolts22 > 2) && ( $cellvolts22 < 5 )) { $influxcmdlinevolts .= "cell_volts_22 value=${cellvolts22} ${timestampline}000000\n"; } }
  if ( ! $cellvolts23 eq "" ) { if ( ( $cellvolts23 > 2) && ( $cellvolts23 < 5 )) { $influxcmdlinevolts .= "cell_volts_23 value=${cellvolts23} ${timestampline}000000\n"; } }
  if ( ! $cellvolts24 eq "" ) { if ( ( $cellvolts24 > 2) && ( $cellvolts24 < 5 )) { $influxcmdlinevolts .= "cell_volts_24 value=${cellvolts24} ${timestampline}000000\n"; } }
  if ( ! $cellvolts25 eq "" ) { if ( ( $cellvolts25 > 2) && ( $cellvolts25 < 5 )) { $influxcmdlinevolts .= "cell_volts_25 value=${cellvolts25} ${timestampline}000000\n"; } }
  if ( ! $cellvolts26 eq "" ) { if ( ( $cellvolts26 > 2) && ( $cellvolts26 < 5 )) { $influxcmdlinevolts .= "cell_volts_26 value=${cellvolts26} ${timestampline}000000\n"; } }
  if ( ! $cellvolts27 eq "" ) { if ( ( $cellvolts27 > 2) && ( $cellvolts27 < 5 )) { $influxcmdlinevolts .= "cell_volts_27 value=${cellvolts27} ${timestampline}000000\n"; } }
  if ( ! $cellvolts28 eq "" ) { if ( ( $cellvolts28 > 2) && ( $cellvolts28 < 5 )) { $influxcmdlinevolts .= "cell_volts_28 value=${cellvolts28} ${timestampline}000000\n"; } }
  if ( ! $cellvolts29 eq "" ) { if ( ( $cellvolts29 > 2) && ( $cellvolts29 < 5 )) { $influxcmdlinevolts .= "cell_volts_29 value=${cellvolts29} ${timestampline}000000\n"; } }
  if ( ! $cellvolts30 eq "" ) { if ( ( $cellvolts30 > 2) && ( $cellvolts30 < 5 )) { $influxcmdlinevolts .= "cell_volts_30 value=${cellvolts30} ${timestampline}000000\n"; } }
  if ( ! $cellvolts31 eq "" ) { if ( ( $cellvolts31 > 2) && ( $cellvolts31 < 5 )) { $influxcmdlinevolts .= "cell_volts_31 value=${cellvolts31} ${timestampline}000000\n"; } }
  if ( ! $cellvolts32 eq "" ) { if ( ( $cellvolts32 > 2) && ( $cellvolts32 < 5 )) { $influxcmdlinevolts .= "cell_volts_32 value=${cellvolts32} ${timestampline}000000\n"; } }
  if ( ! $cellvolts33 eq "" ) { if ( ( $cellvolts33 > 2) && ( $cellvolts33 < 5 )) { $influxcmdlinevolts .= "cell_volts_33 value=${cellvolts33} ${timestampline}000000\n"; } }
  if ( ! $cellvolts34 eq "" ) { if ( ( $cellvolts34 > 2) && ( $cellvolts34 < 5 )) { $influxcmdlinevolts .= "cell_volts_34 value=${cellvolts34} ${timestampline}000000\n"; } }
  if ( ! $cellvolts35 eq "" ) { if ( ( $cellvolts35 > 2) && ( $cellvolts35 < 5 )) { $influxcmdlinevolts .= "cell_volts_35 value=${cellvolts35} ${timestampline}000000\n"; } }
  if ( ! $cellvolts36 eq "" ) { if ( ( $cellvolts36 > 2) && ( $cellvolts36 < 5 )) { $influxcmdlinevolts .= "cell_volts_36 value=${cellvolts36} ${timestampline}000000\n"; } }
  if ( ! $cellvolts37 eq "" ) { if ( ( $cellvolts37 > 2) && ( $cellvolts37 < 5 )) { $influxcmdlinevolts .= "cell_volts_37 value=${cellvolts37} ${timestampline}000000\n"; } }
  if ( ! $cellvolts38 eq "" ) { if ( ( $cellvolts38 > 2) && ( $cellvolts38 < 5 )) { $influxcmdlinevolts .= "cell_volts_38 value=${cellvolts38} ${timestampline}000000\n"; } }
  if ( ! $cellvolts39 eq "" ) { if ( ( $cellvolts39 > 2) && ( $cellvolts39 < 5 )) { $influxcmdlinevolts .= "cell_volts_39 value=${cellvolts39} ${timestampline}000000\n"; } }
  if ( ! $cellvolts40 eq "" ) { if ( ( $cellvolts40 > 2) && ( $cellvolts40 < 5 )) { $influxcmdlinevolts .= "cell_volts_40 value=${cellvolts40} ${timestampline}000000\n"; } }
  if ( ! $cellvolts41 eq "" ) { if ( ( $cellvolts41 > 2) && ( $cellvolts41 < 5 )) { $influxcmdlinevolts .= "cell_volts_41 value=${cellvolts41} ${timestampline}000000\n"; } }
  if ( ! $cellvolts42 eq "" ) { if ( ( $cellvolts42 > 2) && ( $cellvolts42 < 5 )) { $influxcmdlinevolts .= "cell_volts_42 value=${cellvolts42} ${timestampline}000000\n"; } }
  if ( ! $cellvolts43 eq "" ) { if ( ( $cellvolts43 > 2) && ( $cellvolts43 < 5 )) { $influxcmdlinevolts .= "cell_volts_43 value=${cellvolts43} ${timestampline}000000\n"; } }
  if ( ! $cellvolts44 eq "" ) { if ( ( $cellvolts44 > 2) && ( $cellvolts44 < 5 )) { $influxcmdlinevolts .= "cell_volts_44 value=${cellvolts44} ${timestampline}000000\n"; } }
  if ( ! $cellvolts45 eq "" ) { if ( ( $cellvolts45 > 2) && ( $cellvolts45 < 5 )) { $influxcmdlinevolts .= "cell_volts_45 value=${cellvolts45} ${timestampline}000000\n"; } }
  if ( ! $cellvolts46 eq "" ) { if ( ( $cellvolts46 > 2) && ( $cellvolts46 < 5 )) { $influxcmdlinevolts .= "cell_volts_46 value=${cellvolts46} ${timestampline}000000\n"; } }
  if ( ! $cellvolts47 eq "" ) { if ( ( $cellvolts47 > 2) && ( $cellvolts47 < 5 )) { $influxcmdlinevolts .= "cell_volts_47 value=${cellvolts47} ${timestampline}000000\n"; } }
  if ( ! $cellvolts48 eq "" ) { if ( ( $cellvolts48 > 2) && ( $cellvolts48 < 5 )) { $influxcmdlinevolts .= "cell_volts_48 value=${cellvolts48} ${timestampline}000000\n"; } }
  if ( ! $cellvolts49 eq "" ) { if ( ( $cellvolts49 > 2) && ( $cellvolts49 < 5 )) { $influxcmdlinevolts .= "cell_volts_49 value=${cellvolts49} ${timestampline}000000\n"; } }
  if ( ! $cellvolts50 eq "" ) { if ( ( $cellvolts50 > 2) && ( $cellvolts50 < 5 )) { $influxcmdlinevolts .= "cell_volts_50 value=${cellvolts50} ${timestampline}000000\n"; } }
  if ( ! $cellvolts51 eq "" ) { if ( ( $cellvolts51 > 2) && ( $cellvolts51 < 5 )) { $influxcmdlinevolts .= "cell_volts_51 value=${cellvolts51} ${timestampline}000000\n"; } }
  if ( ! $cellvolts52 eq "" ) { if ( ( $cellvolts52 > 2) && ( $cellvolts52 < 5 )) { $influxcmdlinevolts .= "cell_volts_52 value=${cellvolts52} ${timestampline}000000\n"; } }
  if ( ! $cellvolts53 eq "" ) { if ( ( $cellvolts53 > 2) && ( $cellvolts53 < 5 )) { $influxcmdlinevolts .= "cell_volts_53 value=${cellvolts53} ${timestampline}000000\n"; } }
  if ( ! $cellvolts54 eq "" ) { if ( ( $cellvolts54 > 2) && ( $cellvolts54 < 5 )) { $influxcmdlinevolts .= "cell_volts_54 value=${cellvolts54} ${timestampline}000000\n"; } }
  if ( ! $cellvolts55 eq "" ) { if ( ( $cellvolts55 > 2) && ( $cellvolts55 < 5 )) { $influxcmdlinevolts .= "cell_volts_55 value=${cellvolts55} ${timestampline}000000\n"; } }
  if ( ! $cellvolts56 eq "" ) { if ( ( $cellvolts56 > 2) && ( $cellvolts56 < 5 )) { $influxcmdlinevolts .= "cell_volts_56 value=${cellvolts56} ${timestampline}000000\n"; } }
  if ( ! $cellvolts57 eq "" ) { if ( ( $cellvolts57 > 2) && ( $cellvolts57 < 5 )) { $influxcmdlinevolts .= "cell_volts_57 value=${cellvolts57} ${timestampline}000000\n"; } }
  if ( ! $cellvolts58 eq "" ) { if ( ( $cellvolts58 > 2) && ( $cellvolts58 < 5 )) { $influxcmdlinevolts .= "cell_volts_58 value=${cellvolts58} ${timestampline}000000\n"; } }
  if ( ! $cellvolts59 eq "" ) { if ( ( $cellvolts59 > 2) && ( $cellvolts59 < 5 )) { $influxcmdlinevolts .= "cell_volts_59 value=${cellvolts59} ${timestampline}000000\n"; } }
  if ( ! $cellvolts60 eq "" ) { if ( ( $cellvolts60 > 2) && ( $cellvolts60 < 5 )) { $influxcmdlinevolts .= "cell_volts_60 value=${cellvolts60} ${timestampline}000000\n"; } }
  if ( ! $cellvolts61 eq "" ) { if ( ( $cellvolts61 > 2) && ( $cellvolts61 < 5 )) { $influxcmdlinevolts .= "cell_volts_61 value=${cellvolts61} ${timestampline}000000\n"; } }
  if ( ! $cellvolts62 eq "" ) { if ( ( $cellvolts62 > 2) && ( $cellvolts62 < 5 )) { $influxcmdlinevolts .= "cell_volts_62 value=${cellvolts62} ${timestampline}000000\n"; } }
  if ( ! $cellvolts63 eq "" ) { if ( ( $cellvolts63 > 2) && ( $cellvolts63 < 5 )) { $influxcmdlinevolts .= "cell_volts_63 value=${cellvolts63} ${timestampline}000000\n"; } }
  if ( ! $cellvolts64 eq "" ) { if ( ( $cellvolts64 > 2) && ( $cellvolts64 < 5 )) { $influxcmdlinevolts .= "cell_volts_64 value=${cellvolts64} ${timestampline}000000\n"; } }
  if ( ! $cellvolts65 eq "" ) { if ( ( $cellvolts65 > 2) && ( $cellvolts65 < 5 )) { $influxcmdlinevolts .= "cell_volts_65 value=${cellvolts65} ${timestampline}000000\n"; } }
  if ( ! $cellvolts66 eq "" ) { if ( ( $cellvolts66 > 2) && ( $cellvolts66 < 5 )) { $influxcmdlinevolts .= "cell_volts_66 value=${cellvolts66} ${timestampline}000000\n"; } }
  if ( ! $cellvolts67 eq "" ) { if ( ( $cellvolts67 > 2) && ( $cellvolts67 < 5 )) { $influxcmdlinevolts .= "cell_volts_67 value=${cellvolts67} ${timestampline}000000\n"; } }
  if ( ! $cellvolts68 eq "" ) { if ( ( $cellvolts68 > 2) && ( $cellvolts68 < 5 )) { $influxcmdlinevolts .= "cell_volts_68 value=${cellvolts68} ${timestampline}000000\n"; } }
  if ( ! $cellvolts69 eq "" ) { if ( ( $cellvolts69 > 2) && ( $cellvolts69 < 5 )) { $influxcmdlinevolts .= "cell_volts_69 value=${cellvolts69} ${timestampline}000000\n"; } }
  if ( ! $cellvolts70 eq "" ) { if ( ( $cellvolts70 > 2) && ( $cellvolts70 < 5 )) { $influxcmdlinevolts .= "cell_volts_70 value=${cellvolts70} ${timestampline}000000\n"; } }
  if ( ! $cellvolts71 eq "" ) { if ( ( $cellvolts71 > 2) && ( $cellvolts71 < 5 )) { $influxcmdlinevolts .= "cell_volts_71 value=${cellvolts71} ${timestampline}000000\n"; } }
  if ( ! $cellvolts72 eq "" ) { if ( ( $cellvolts72 > 2) && ( $cellvolts72 < 5 )) { $influxcmdlinevolts .= "cell_volts_72 value=${cellvolts72} ${timestampline}000000\n"; } }
  if ( ! $cellvolts73 eq "" ) { if ( ( $cellvolts73 > 2) && ( $cellvolts73 < 5 )) { $influxcmdlinevolts .= "cell_volts_73 value=${cellvolts73} ${timestampline}000000\n"; } }
  if ( ! $cellvolts74 eq "" ) { if ( ( $cellvolts74 > 2) && ( $cellvolts74 < 5 )) { $influxcmdlinevolts .= "cell_volts_74 value=${cellvolts74} ${timestampline}000000\n"; } }
  if ( ! $cellvolts75 eq "" ) { if ( ( $cellvolts75 > 2) && ( $cellvolts75 < 5 )) { $influxcmdlinevolts .= "cell_volts_75 value=${cellvolts75} ${timestampline}000000\n"; } }
  if ( ! $cellvolts76 eq "" ) { if ( ( $cellvolts76 > 2) && ( $cellvolts76 < 5 )) { $influxcmdlinevolts .= "cell_volts_76 value=${cellvolts76} ${timestampline}000000\n"; } }
  if ( ! $cellvolts77 eq "" ) { if ( ( $cellvolts77 > 2) && ( $cellvolts77 < 5 )) { $influxcmdlinevolts .= "cell_volts_77 value=${cellvolts77} ${timestampline}000000\n"; } }
  if ( ! $cellvolts78 eq "" ) { if ( ( $cellvolts78 > 2) && ( $cellvolts78 < 5 )) { $influxcmdlinevolts .= "cell_volts_78 value=${cellvolts78} ${timestampline}000000\n"; } }
  if ( ! $cellvolts79 eq "" ) { if ( ( $cellvolts79 > 2) && ( $cellvolts79 < 5 )) { $influxcmdlinevolts .= "cell_volts_79 value=${cellvolts79} ${timestampline}000000\n"; } }
  if ( ! $cellvolts80 eq "" ) { if ( ( $cellvolts80 > 2) && ( $cellvolts80 < 5 )) { $influxcmdlinevolts .= "cell_volts_80 value=${cellvolts80} ${timestampline}000000\n"; } }
  if ( ! $cellvolts81 eq "" ) { if ( ( $cellvolts81 > 2) && ( $cellvolts81 < 5 )) { $influxcmdlinevolts .= "cell_volts_81 value=${cellvolts81} ${timestampline}000000\n"; } }
  if ( ! $cellvolts82 eq "" ) { if ( ( $cellvolts82 > 2) && ( $cellvolts82 < 5 )) { $influxcmdlinevolts .= "cell_volts_82 value=${cellvolts82} ${timestampline}000000\n"; } }
  if ( ! $cellvolts83 eq "" ) { if ( ( $cellvolts83 > 2) && ( $cellvolts83 < 5 )) { $influxcmdlinevolts .= "cell_volts_83 value=${cellvolts83} ${timestampline}000000\n"; } }
  if ( ! $cellvolts84 eq "" ) { if ( ( $cellvolts84 > 2) && ( $cellvolts84 < 5 )) { $influxcmdlinevolts .= "cell_volts_84 value=${cellvolts84} ${timestampline}000000\n"; } }
  if ( ! $cellvolts85 eq "" ) { if ( ( $cellvolts85 > 2) && ( $cellvolts85 < 5 )) { $influxcmdlinevolts .= "cell_volts_85 value=${cellvolts85} ${timestampline}000000\n"; } }
  if ( ! $cellvolts86 eq "" ) { if ( ( $cellvolts86 > 2) && ( $cellvolts86 < 5 )) { $influxcmdlinevolts .= "cell_volts_86 value=${cellvolts86} ${timestampline}000000\n"; } }
  if ( ! $cellvolts87 eq "" ) { if ( ( $cellvolts87 > 2) && ( $cellvolts87 < 5 )) { $influxcmdlinevolts .= "cell_volts_87 value=${cellvolts87} ${timestampline}000000\n"; } }
  if ( ! $cellvolts88 eq "" ) { if ( ( $cellvolts88 > 2) && ( $cellvolts88 < 5 )) { $influxcmdlinevolts .= "cell_volts_88 value=${cellvolts88} ${timestampline}000000\n"; } }
  if ( ! $cellvolts89 eq "" ) { if ( ( $cellvolts89 > 2) && ( $cellvolts89 < 5 )) { $influxcmdlinevolts .= "cell_volts_89 value=${cellvolts89} ${timestampline}000000\n"; } }
  if ( ! $cellvolts90 eq "" ) { if ( ( $cellvolts90 > 2) && ( $cellvolts90 < 5 )) { $influxcmdlinevolts .= "cell_volts_90 value=${cellvolts90} ${timestampline}000000\n"; } }
  if ( ! $cellvolts91 eq "" ) { if ( ( $cellvolts91 > 2) && ( $cellvolts91 < 5 )) { $influxcmdlinevolts .= "cell_volts_91 value=${cellvolts91} ${timestampline}000000\n"; } }
  if ( ! $cellvolts92 eq "" ) { if ( ( $cellvolts92 > 2) && ( $cellvolts92 < 5 )) { $influxcmdlinevolts .= "cell_volts_92 value=${cellvolts92} ${timestampline}000000\n"; } }
  if ( ! $cellvolts93 eq "" ) { if ( ( $cellvolts93 > 2) && ( $cellvolts93 < 5 )) { $influxcmdlinevolts .= "cell_volts_93 value=${cellvolts93} ${timestampline}000000\n"; } }
  if ( ! $cellvolts94 eq "" ) { if ( ( $cellvolts94 > 2) && ( $cellvolts94 < 5 )) { $influxcmdlinevolts .= "cell_volts_94 value=${cellvolts94} ${timestampline}000000\n"; } }
  if ( ! $cellvolts95 eq "" ) { if ( ( $cellvolts95 > 2) && ( $cellvolts95 < 5 )) { $influxcmdlinevolts .= "cell_volts_95 value=${cellvolts95} ${timestampline}000000\n"; } }
  if ( ! $cellvolts96 eq "" ) { if ( ( $cellvolts96 > 2) && ( $cellvolts96 < 5 )) { $influxcmdlinevolts .= "cell_volts_96 value=${cellvolts96} ${timestampline}000000\n"; } }
 
# grafana only permits 100 measurements per datastore so we split over more than 1 

  if (length($influxcmdline) > 10000)
  {
    # -s - silent; -S - show errors
    $result = `curl -s -S -i -XPOST 'http://localhost:8086/write?db=tesla' --data-binary '${influxcmdline}'`;
##    print "$result \n";
    $influxcmdline = "";
  }

  if (length($influxcmdlinevolts) > 10000)
  {
    $result = `curl -s -S -i -XPOST 'http://localhost:8086/write?db=tesla_cell_voltages' --data-binary '${influxcmdlinevolts}'`;
    $influxcmdlinevolts = "";
  }


# this is old leafspy shit and needs tidying/replacing
if ($modeswitch eq "dump")
{
#  print "log line summary:\n";
#  print "$year $month $day $hour $minute $second epoch $epochtime calculated epoch $linetime\n";
#  print "lat $lat long $long elevation $elevation speed $speed\n";
#  print "gids: $gids percent-soc: $soc amphr: $amphr volts (3 readings) $packvolts $packvolts2 $packvolts3\n";
#  print "cellpairs max $maxcpmv min $mincpmv avg $avgcpmv biggest difference $cpmvdiff judgementval $judgementval\n";
#  print "pack temps $packtemp1 $packtemp2 $packtemp3 $packtemp4 health1 $packhealth health2 $packhealth2 quickcharges $quickcharges slowcharges $slowcharges\n";
#  print "odometer miles $odom 12v volts $voltsla outside temp $ambienttemp c\n";
#  print "tyre presures front left $tpfl front right $tpfr rear left $tprl rear right $tprr\n";
#  print "regen cumulative wh $regenwh regen power $regenwatts drive motor $drivemotor W aux $auxpower W\n";
#  print "ac pressure $acpres psi, power $acpower W est power $acpower2 W heater est power $heatpower W\n";
#  print "phone battery $phonebatt\n";
#  # 0.39.97 (april 2017) adds 3 more fields to the end of the line
#  if ( $lineitems > 152 )
#  {
#    print "new log format - motor temp $motortemp c, inverter temps $inverter2temp c $inverter4temp c\n";
#  }
#  # 0.40.101 (august 2017) adds a further 3 fields to the end of the line
#  if ( $lineitems > 155 )
#  {
#    print "newer log format - speed sensors: 1 $speedsensor1 mph 2 $speedsensor2 mph\n";
#  }
#
}


# we need these values next time round
#$linetimelast = $linetime;

}

$endtime = time();
$runtime = $endtime - $starttime;

print LOGFILE "exiting successfully after $runtime seconds \n\n";


