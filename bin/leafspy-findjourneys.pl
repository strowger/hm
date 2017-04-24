#! /usr/bin/perl -w
#
# leafspy-findjourneys.pl
# GH 2017-02-01
#
#
# looks for the vehicle being switched on and off to output epoch values of journey
#  start and end times, in order to create graphs of journeys
#

# for calculating epoch from logfile values
use Time::Local;

no warnings 'once';

$timestamp = time();                                                                                  
$starttime = $timestamp;

@oldline=();
$oldpowerswitch=0;

# this will read from either stdin or a file specified on the commandline
while (<>)
{
  @line = split(",",$_);
  $lineitems = scalar (@line);
  $datetime = $line[0];
  # silently skip the valid first line of a file (field names) without logging anything
  if ( $datetime =~ /Date\/Time/ )
    { next; }
  # first thing on a valid line is a date in format 2 digits, slash, 2 digits, slash, 4 digits
  # valid lines have 152 or 155 items on them
  if (( $datetime !~ /\d{2}\/\d{2}\/\d{4}/ ) || ( $lineitems < 152))
  {
    print "line appears corrupt, skipping\n";
    next;
  }
  ($date,$time) = split(" ",$datetime);
  ($month,$day,$year) = split("/",$date);
  ($hour,$minute,$second) = split(":",$time);
# need to form epoch from these to update rrds with
# timegm requires months in range 0-11 (!)
  $stupidmonth = $month -1;
  $linetime = timegm($second, $minute, $hour, $day, $stupidmonth, $year);
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
  # phone battery in %
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


if ( defined $lastlinetime )
{
  # gap in seconds between lines
  $lineinterval = $linetime - $lastlinetime;
  if ( $lineinterval > 100 )
  {
    print "possible journey end at $lastlinetime\n";
    print "possible journey start at $linetime\n";
  }
  $lastlinetime = $linetime; 
}
else
{
  # no last line time - first line of the file? the powerswitch check 
  # below should catch the journey if so
  $lastlinetime = $linetime;
}

# power switch is off now but was on last poll - journey end?
# with the bluetooth module powered only by switched live, we never get
# any "powerswitch = 0" lines - this should still catch the first
# power-on of the day though
if (($powerswitch == 1) && ($oldpowerswitch == 0))
{
  print "possible journey start at $epochtime\n";
}

if (($powerswitch == 0) && ($oldpowerswitch == 1))
{
  print "possible journey end at $epochtime\n";
} 

@oldline = @line;
$oldpowerswitch = $powerswitch;
}

# after the last line of the time...

$timenow = time();
$lineage = $timenow - $linetime;
if ( $lineage > 1800)
{
  print "possible journey end at $linetime\n";
}


