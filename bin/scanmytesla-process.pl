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
%cellvolts;
%cellvoltslast;
%celltemp;
%celltemplast;
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
  $midventl = $line[$logoffset+95];
  $midventr = $line[$logoffset+96];
  # these are flaps within the hvac system 
  # measurement units unsure, perhaps degrees? 16-250 = 0-100%
  # from facebook convo with scanmytesla author
  $louver1 = $line[$logoffset+97];
  $louver2 = $line[$logoffset+98];
  $louver3 = $line[$logoffset+99];
  $louver4 = $line[$logoffset+100];
  $louver5 = $line[$logoffset+101];
  $louver6 = $line[$logoffset+102];
  $louver7 = $line[$logoffset+103];
  $louver8 = $line[$logoffset+104];
  # these refer to vents being enabled - 1 on 0 off
  $hvacflr = $line[$logoffset+105];
  $hvacmid = $line[$logoffset+106];
  $hvacwin = $line[$logoffset+107];
  $hvacac = $line[$logoffset+108];
  $hvacoff = $line[$logoffset+109];
  $hvacfanspeed = $line[$logoffset+110];
  $hvactempleft = $line[$logoffset+111];
  $hvactempright = $line[$logoffset+112];

  $celltempmin = $line[$logoffset+113];
  $celltempavg = $line[$logoffset+114];
  $celltempmax = $line[$logoffset+115];
  $celltempdiff = $line[$logoffset+116];
  $cellmin = $line[$logoffset+117];
  $cellavg = $line[$logoffset+118];
  $cellmax = $line[$logoffset+119];
  $celldiff = $line[$logoffset+120];
  $cellvolts{'01'} = $line[$logoffset+121];
  $cellvolts{'02'} = $line[$logoffset+122]; 
  $cellvolts{'03'} = $line[$logoffset+123]; 
  $celltemp{'01'} = $line[$logoffset+124];
  $cellvolts{'04'} = $line[$logoffset+125];
  $cellvolts{'05'} = $line[$logoffset+126];
  $cellvolts{'06'} = $line[$logoffset+127];
  $celltemp{'02'} = $line[$logoffset+128];
  $cellvolts{'07'} = $line[$logoffset+129];
  $cellvolts{'08'} = $line[$logoffset+130];
  $cellvolts{'09'} = $line[$logoffset+131];
  $celltemp{'03'} = $line[$logoffset+132];
  $cellvolts{'10'} = $line[$logoffset+133];
  $cellvolts{'11'} = $line[$logoffset+134];
  $cellvolts{'12'} = $line[$logoffset+135];
  $celltemp{'04'} = $line[$logoffset+136];
  $cellvolts{'13'} = $line[$logoffset+137];
  $cellvolts{'14'} = $line[$logoffset+138];
  $cellvolts{'15'} = $line[$logoffset+139];
  $celltemp{'05'} = $line[$logoffset+140];
  $cellvolts{'16'} = $line[$logoffset+141];
  $cellvolts{'17'} = $line[$logoffset+142];
  $cellvolts{'18'} = $line[$logoffset+143];
  $celltemp{'06'} = $line[$logoffset+144];
  $cellvolts{'19'} = $line[$logoffset+145];
  $cellvolts{'20'} = $line[$logoffset+146];
  $cellvolts{'21'} = $line[$logoffset+147];
  $celltemp{'07'} = $line[$logoffset+148];
  $cellvolts{'22'} = $line[$logoffset+149];
  $cellvolts{'23'} = $line[$logoffset+150];
  $cellvolts{'24'} = $line[$logoffset+151];
  $celltemp{'08'} = $line[$logoffset+152];
  $cellvolts{'25'} = $line[$logoffset+153];
  $cellvolts{'26'} = $line[$logoffset+154];
  $cellvolts{'27'} = $line[$logoffset+155];
  $celltemp{'09'} = $line[$logoffset+156];
  $cellvolts{'28'} = $line[$logoffset+157];
  $cellvolts{'29'} = $line[$logoffset+158];
  $cellvolts{'30'} = $line[$logoffset+159];
  $celltemp{'10'} = $line[$logoffset+160];
  $cellvolts{'31'} = $line[$logoffset+161];
  $cellvolts{'32'} = $line[$logoffset+162];
  $cellvolts{'33'} = $line[$logoffset+163];
  $celltemp{'11'} = $line[$logoffset+164];
  $cellvolts{'34'} = $line[$logoffset+165];
  $cellvolts{'35'} = $line[$logoffset+166];
  $cellvolts{'36'} = $line[$logoffset+167];
  $celltemp{'12'} = $line[$logoffset+168];
  $cellvolts{'37'} = $line[$logoffset+169];
  $cellvolts{'38'} = $line[$logoffset+170];
  $cellvolts{'39'} = $line[$logoffset+171];
  $celltemp{'13'} = $line[$logoffset+172];
  $cellvolts{'40'} = $line[$logoffset+173];
  $cellvolts{'41'} = $line[$logoffset+174];
  $cellvolts{'42'} = $line[$logoffset+175];
  $celltemp{'14'} = $line[$logoffset+176];
  $cellvolts{'43'} = $line[$logoffset+177];
  $cellvolts{'44'} = $line[$logoffset+178];
  $cellvolts{'45'} = $line[$logoffset+179];
  $celltemp{'15'} = $line[$logoffset+180];
  $cellvolts{'46'} = $line[$logoffset+181];
  $cellvolts{'47'} = $line[$logoffset+182];
  $cellvolts{'48'} = $line[$logoffset+183];
  $celltemp{'16'} = $line[$logoffset+184];
  $cellvolts{'49'} = $line[$logoffset+185];
  $cellvolts{'50'} = $line[$logoffset+186];
  $cellvolts{'51'} = $line[$logoffset+187];
  $celltemp{'17'} = $line[$logoffset+188];
  $cellvolts{'52'} = $line[$logoffset+189];
  $cellvolts{'53'} = $line[$logoffset+190];
  $cellvolts{'54'} = $line[$logoffset+191];
  $celltemp{'18'} = $line[$logoffset+192];
  $cellvolts{'55'} = $line[$logoffset+193];
  $cellvolts{'56'} = $line[$logoffset+194];
  $cellvolts{'57'} = $line[$logoffset+195];
  $celltemp{'19'} = $line[$logoffset+196];
  $cellvolts{'58'} = $line[$logoffset+197];
  $cellvolts{'59'} = $line[$logoffset+198];
  $cellvolts{'60'} = $line[$logoffset+199];
  $celltemp{'20'} = $line[$logoffset+200];
  $cellvolts{'61'} = $line[$logoffset+201];
  $cellvolts{'62'} = $line[$logoffset+202];
  $cellvolts{'63'} = $line[$logoffset+203];
  $celltemp{'21'} = $line[$logoffset+204];
  $cellvolts{'64'} = $line[$logoffset+205];
  $cellvolts{'65'} = $line[$logoffset+206];
  $cellvolts{'66'} = $line[$logoffset+207];
  $celltemp{'22'} = $line[$logoffset+208];
  $cellvolts{'67'} = $line[$logoffset+209];
  $cellvolts{'68'} = $line[$logoffset+210];
  $cellvolts{'69'} = $line[$logoffset+211];
  $celltemp{'23'} = $line[$logoffset+212];
  $cellvolts{'70'} = $line[$logoffset+213];
  $cellvolts{'71'} = $line[$logoffset+214];
  $cellvolts{'72'} = $line[$logoffset+215];
  $celltemp{'24'} = $line[$logoffset+216];
  $cellvolts{'73'} = $line[$logoffset+217];
  $cellvolts{'74'} = $line[$logoffset+218];
  $cellvolts{'75'} = $line[$logoffset+219];
  $celltemp{'25'} = $line[$logoffset+220];
  $cellvolts{'76'} = $line[$logoffset+221];
  $cellvolts{'77'} = $line[$logoffset+222];
  $cellvolts{'78'} = $line[$logoffset+223];
  $celltemp{'26'} = $line[$logoffset+224];
  $cellvolts{'79'} = $line[$logoffset+225];
  $cellvolts{'80'} = $line[$logoffset+226];
  $cellvolts{'81'} = $line[$logoffset+227];
  $celltemp{'27'} = $line[$logoffset+228];
  $cellvolts{'82'} = $line[$logoffset+229];
  $cellvolts{'83'} = $line[$logoffset+230];
  $cellvolts{'84'} = $line[$logoffset+231];
  $celltemp{'28'} = $line[$logoffset+232];
  $cellvolts{'85'} = $line[$logoffset+233];
  $cellvolts{'86'} = $line[$logoffset+234];
  $cellvolts{'87'} = $line[$logoffset+235];
  $celltemp{'29'} = $line[$logoffset+236];
  $cellvolts{'88'} = $line[$logoffset+237];
  $cellvolts{'89'} = $line[$logoffset+238];
  $cellvolts{'90'} = $line[$logoffset+239];
  $celltemp{'30'} = $line[$logoffset+240];
  $cellvolts{'91'} = $line[$logoffset+241];
  $cellvolts{'92'} = $line[$logoffset+242];
  $cellvolts{'93'} = $line[$logoffset+243];
  $celltemp{'31'} = $line[$logoffset+244];
  $cellvolts{'94'} = $line[$logoffset+245];
  $cellvolts{'95'} = $line[$logoffset+246];
  $cellvolts{'96'} = $line[$logoffset+247];
  $celltemp{'32'} = $line[$logoffset+248];


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
# this is meant to be heating/cooling but suffers from spikes and nonsense data
  if ( ! $heatingcooling eq "" ) { if ( ( $heatingcooling > -12) && ( $heatingcooling < 12 )) { $influxcmdline .= "hvac value=${heatingcooling} ${timestampline}000000\n"; } }

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

  if ( ! $tempoutfilt eq "" ) { if (( $tempoutfilt > -40 ) && ( $tempoutfilt < 60 )) { $influxcmdline .= "temp_outside_filtered value=${tempoutfilt} ${timestampline}000000\n"; } }
  if ( ! $tempin eq "" ) { if (( $tempin > -40 ) && ( $tempin <70 )) { $influxcmdline .= "temp_inside value=${tempin} ${timestampline}000000\n"; } }
  if ( ! $tempacair eq "" ) { if (( $tempacair > -40 ) && ( $tempacair < 80 )) { $influxcmdline .= "temp_aircon_air value=${tempacair} ${timestampline}000000\n"; } }
  if ( ! $floorventl eq "" ) { if (( $floorventl > -40 ) && ( $floorventl < 80 )) { $influxcmdline .= "temp_floor_vent_l value=${floorventl} ${timestampline}000000\n"; } }
  if ( ! $floorventr eq "" ) { if (( $floorventr > -40 ) && ( $floorventr < 80 )) { $influxcmdline .= "temp_floor_vent_r value=${floorventr} ${timestampline}000000\n"; } }
  if ( ! $midventl eq "" ) { if (( $midventl > -40 ) && ( $midventl < 60 )) { $influxcmdline .= "temp_mid_vent_l value=${midventl} ${timestampline}000000\n"; } }
  if ( ! $midventr eq "" ) { if (( $midventr > -40 ) && ( $midventr < 60 )) { $influxcmdline .= "temp_mid_vent_r value=${midventr} ${timestampline}000000\n"; } }
  if ( ! $hvactempleft eq "" ) { if (( $hvactempleft > 0 ) && ( $hvactempleft < 60 )) { $influxcmdline .= "temp_set_left value=${hvactempleft} ${timestampline}000000\n"; } }
  if ( ! $hvactempright eq "" ) { if (( $hvactempright > 0 ) && ( $hvactempright < 60 )) { $influxcmdline .= "temp_set_right value=${hvactempright} ${timestampline}000000\n"; } }
  if ( ! $hvacfanspeed eq "" ) { if (( $hvacfanspeed > 0 ) && ( $hvacfanspeed < 12 )) { $influxcmdline .= "cabin_fan_speed value=${hvacfanspeed} ${timestampline}000000\n"; } }



#$floorventl = $line[$logoffset+93];
#$floorventr = $line[$logoffset+94];
#$midventl = $line[$logoffset+95];
#$midventr = $line[$logoffset+96];
#$louver1 = $line[$logoffset+97];
#[...]
#  $louver8 = $line[$logoffset+104];                                                                                                                  # these refer to vents being enabled - 1 on 0 off
#  $hvacflr = $line[$logoffset+105];
#  $hvacmid = $line[$logoffset+106];
#  $hvacwin = $line[$logoffset+107];
#  $hvacac = $line[$logoffset+108];
#  $hvacoff = $line[$logoffset+109];


  if ( ! $celltempmin eq "" ) 
  { 
    if ( ! defined $celltempminlast ) { $celltempminlast = $celltempmin; }
    $ctdiff = abs ($celltempmin - $celltempminlast);
    if (( $ctdiff < 5 ) && ( $celltempmin > -25 ) && ( $celltempmin < 75 ))
    { 
      $influxcmdline .= "cell_temp_min value=${celltempmin} ${timestampline}000000\n"; 
    } 
    $celltempminlast = $celltempmin;
  }

  if ( ! $celltempavg eq "" ) 
  { 
    if ( ! defined $celltempavglast ) { $celltempavglast = $celltempavg; }
    $ctdiff = abs ($celltempavg - $celltempavglast);
    if (( $ctdiff < 5 ) && ( $celltempavg > -25 ) && ( $celltempavg < 75))
    { 
      $influxcmdline .= "cell_temp_avg value=${celltempavg} ${timestampline}000000\n"; 
    } 
    $celltempavglast = $celltempavg;
  }

  if ( ! $celltempmax eq "" ) 
  { 
    if ( ! defined $celltempmaxlast ) { $celltempmaxlast = $celltempmax; }
    $ctdiff = abs ($celltempmax - $celltempmaxlast);
    if (( $ctdiff < 5 ) && ( $celltempmax > -25 ) && ( $celltempmax < 75))
    { 
      $influxcmdline .= "cell_temp_max value=${celltempmax} ${timestampline}000000\n"; 
    } 
    $celltempmaxlast = $celltempmax;
  }

  if ( ! $celltempdiff eq "" ) { if ( $celltempdiff < 30 ) { $influxcmdline .= "cell_temp_diff value=${celltempdiff} ${timestampline}000000\n"; } }

# need these numbers in "" in order to preserve the leading zeros
  foreach $ctno("01".."32")
  {
    # if we actually got a value for it on this line...
    if ( ! $celltemp{$ctno} eq "" )
    {
#      print "celltemp debug: ctno $ctno temp $celltemp{$ctno}\n";
      # if this is the first of these we've had, we need to populate the hash of last values
      if ( ! defined $celltemplast{$ctno} ) { $celltemplast{$ctno} = $celltemp{$ctno}; }
      # if we haven't had an avg yet, we'll bodge it
      # we want to bin values that are too far from the average
      if ( ! $celltempavglast eq "" ) { $avgtemp = $celltempavglast; }
      else { $avgtemp = $celltemp{$ctno}; }
      $avgdiff = abs ($celltemp{$ctno} - $avgtemp);
      # if the value we've got seems sane
      $ctdiff = abs ($celltemp{$ctno} - $celltemplast{$ctno});
      # if the current value is more than 5 deg different to previous, it's bogus; also ignore clearly nonsense values
#      print "celltemp debug: ctno $ctno temp $celltemp{$ctno} diff $ctdiff last $celltemplast{$ctno}\n";
      if (( $ctdiff < 5 ) && ( $celltemp{$ctno} > -25 ) && ( $celltemp{$ctno} < 75 ) && ( $avgdiff < 10))
      {
        $influxcmdline .= "cell_temp_$ctno value=$celltemp{$ctno} ${timestampline}000000\n";     
      }
      $celltemplast{$ctno} = $celltemp{$ctno};  
    }
  }

  foreach $cvno("01".."96")
  {
    # if we actually got a value for it on this line...
    if ( ! $cellvolts{$cvno} eq "" )
    {
      # if this is the first of these we've had, we need to populate the hash of last values
      if ( ! defined $cellvoltslast{$cvno} ) { $cellvoltslast{$cvno} = $cellvolts{$cvno}; }
      # if the value we've got seems sane
      $cvdiff = abs ($cellvolts{$cvno} - $cellvoltslast{$cvno});
      # if the current value is more than 1 volt different to previous, it's bogus; also ignore clearly nonsense values
#      print "cell volts debug - cell $cvno difference $cvdiff voltage $cellvolts{$cvno}\n";
      if (( $cvdiff < 1 ) && ( $cellvolts{$cvno} < 5 ) && ( $cellvolts{$cvno} > 2 ))
      {
        $influxcmdlinevolts .= "cell_volts_$cvno value=$cellvolts{$cvno} ${timestampline}000000\n";
      }
      $cellvoltslast{$cvno} = $cellvolts{$cvno};  
    }
  }

 
# grafana only permits 100 measurements per datastore so we split over more than 1 

  if (length($influxcmdline) > 10000)
  {
    # -s - silent; -S - show errors
    `curl -s -S -i -XPOST 'http://localhost:8086/write?db=tesla' --data-binary '${influxcmdline}'` or warn "Could not run curl because $!\n";
    $influxcmdline = "";
  }

  if (length($influxcmdlinevolts) > 10000)
  {
    `curl -s -S -i -XPOST 'http://localhost:8086/write?db=tesla_cell_voltages' --data-binary '${influxcmdlinevolts}'` or warn "Could not run curl because $!\n";
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


