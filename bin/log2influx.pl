#! /usr/bin/perl -w
#
# log2influx.pl - add data from existing logs to influxdb
#
# GH 2018-02-08
# with brian home and the others out at the party

$logdirectory="/data/hm/log";


# power stuff

open INPUT, "<", "$logdirectory/power.log" or die $!;
print "opened power.log special format file\n";
$result = "";
$influxcmdline = "";
while ( $line = <INPUT> )
{
  ($timestamp, $type, $watts, $temp) = split(' ',$line);
  # any number of digits and cnt - a count line, ignore it
  if ( $watts =~ /\d+cnt/ ) { next; } 
  if ( $type eq "opti" )
  {
    chop($watts);
    $influxcmdline .= "wholehouse_optical value=${watts} ${timestamp}000000000\n";
  }
  if ( $type eq "clamp" )
  {
    chop($watts);
    $influxcmdline .= "wholehouse_clamp value=${watts} ${timestamp}000000000\n";
  }


  if (length($influxcmdline) > 10000)
  {
    # -s - silent; -S - show errors
    `curl -s -S -i -XPOST 'http://localhost:8086/write?db=styes_power' --data-binary '${influxcmdline}'` or warn "Could not run curl because $!\n";
    $influxcmdline = "";
   }

}
$result = `curl -s -S -i -XPOST 'http://localhost:8086/write?db=styes_power' --data-binary '${influxcmdline}'` or warn "Could not run curl because $!\n";
close INPUT;

open INPUT, "<", "$logdirectory/rtl433-cciamofficedesk.log" or die $!;
print "opened file odesk\n";
$influxcmdline = "";
foreach $line (<INPUT>)
{
  ($timestamp, $watts) = split(' ',$line);
  $influxcmdline .= "office_desk value=${watts} ${timestamp}000000000\n";

  if (length($influxcmdline) > 10000)
  {
    # -s - silent; -S - show errors
    $result = `curl -s -S -i -XPOST 'http://localhost:8086/write?db=styes_power' --data-binary '${influxcmdline}'` or warn "Could not run curl because $!\n";
##    print "$result \n";
    $influxcmdline = "";
  }
}
$result = `curl -s -S -i -XPOST 'http://localhost:8086/write?db=styes_power' --data-binary '${influxcmdline}'` or warn "Could not run curl because $!\n";
close INPUT;


open INPUT, "<", "$logdirectory/rtl433-cciamupsb.log" or die $!;
print "opened file upsb\n";
$influxcmdline = "";
foreach $line (<INPUT>)
{
  ($timestamp, $watts) = split(' ',$line);
  $influxcmdline .= "ups_basement value=${watts} ${timestamp}000000000\n";

  if (length($influxcmdline) > 10000)
  {
    # -s - silent; -S - show errors
    $result = `curl -s -S -i -XPOST 'http://localhost:8086/write?db=styes_power' --data-binary '${influxcmdline}'` or warn "Could not run curl because $!\n";
##    print "$result \n";
    $influxcmdline = "";
  }
}
$result = `curl -s -S -i -XPOST 'http://localhost:8086/write?db=styes_power' --data-binary '${influxcmdline}'` or warn "Could not run curl because $!\n";
close INPUT;


open INPUT, "<", "$logdirectory/rtl433-cciamtoaster.log" or die $!;
print "opened file toaster\n";
$influxcmdline = "";
foreach $line (<INPUT>)
{
  ($timestamp, $watts) = split(' ',$line);
  $influxcmdline .= "toaster value=${watts} ${timestamp}000000000\n";

  if (length($influxcmdline) > 10000)
  {
    # -s - silent; -S - show errors
    $result = `curl -s -S -i -XPOST 'http://localhost:8086/write?db=styes_power' --data-binary '${influxcmdline}'` or warn "Could not run curl because $!\n";
##    print "$result \n";
    $influxcmdline = "";
  }
}
$result = `curl -s -S -i -XPOST 'http://localhost:8086/write?db=styes_power' --data-binary '${influxcmdline}'` or warn "Could not run curl because $!\n";
close INPUT;


open INPUT, "<", "$logdirectory/rtl433-ccclamptowelrail.log" or die $!;
print "opened file towelrail\n";
$influxcmdline = "";
foreach $line (<INPUT>)
{
  ($timestamp, $watts) = split(' ',$line);
  $influxcmdline .= "towelrail value=${watts} ${timestamp}000000000\n";

  if (length($influxcmdline) > 10000)
  {
    # -s - silent; -S - show errors
    $result = `curl -s -S -i -XPOST 'http://localhost:8086/write?db=styes_power' --data-binary '${influxcmdline}'` or warn "Could not run curl because $!\n";
##    print "$result \n";
    $influxcmdline = "";
  }
}
$result = `curl -s -S -i -XPOST 'http://localhost:8086/write?db=styes_power' --data-binary '${influxcmdline}'` or warn "Could not run curl because $!\n";
close INPUT;


open INPUT, "<", "$logdirectory/rtl433-cciamwasher.log" or die $!;
print "opened file washer\n";
$influxcmdline = "";
foreach $line (<INPUT>)
{
  ($timestamp, $watts) = split(' ',$line);
  $influxcmdline .= "washing_machine value=${watts} ${timestamp}000000000\n";

  if (length($influxcmdline) > 10000)
  {
    # -s - silent; -S - show errors
    $result = `curl -s -S -i -XPOST 'http://localhost:8086/write?db=styes_power' --data-binary '${influxcmdline}'` or warn "Could not run curl because $!\n";
##    print "$result \n";
    $influxcmdline = "";
  }
}
$result = `curl -s -S -i -XPOST 'http://localhost:8086/write?db=styes_power' --data-binary '${influxcmdline}'` or warn "Could not run curl because $!\n";
close INPUT;


open INPUT, "<", "$logdirectory/rtl433-cciamdwasher.log" or die $!;
print "opened file dwasher\n";
$influxcmdline = "";
foreach $line (<INPUT>)
{
  ($timestamp, $watts) = split(' ',$line);
  $influxcmdline .= "dishwasher value=${watts} ${timestamp}000000000\n";

  if (length($influxcmdline) > 10000)
  {
    # -s - silent; -S - show errors
    $result = `curl -s -S -i -XPOST 'http://localhost:8086/write?db=styes_power' --data-binary '${influxcmdline}'` or warn "Could not run curl because $!\n";
##    print "$result \n";
    $influxcmdline = "";
  }
}
$result = `curl -s -S -i -XPOST 'http://localhost:8086/write?db=styes_power' --data-binary '${influxcmdline}'` or warn "Could not run curl because $!\n";
close INPUT;


open INPUT, "<", "$logdirectory/rtl433-ccclampcook.log" or die $!;
print "opened file cooker\n";
$influxcmdline = "";
foreach $line (<INPUT>)
{
  ($timestamp, $watts) = split(' ',$line);
  $influxcmdline .= "cooker value=${watts} ${timestamp}000000000\n";

  if (length($influxcmdline) > 10000)
  {
    # -s - silent; -S - show errors
    $result = `curl -s -S -i -XPOST 'http://localhost:8086/write?db=styes_power' --data-binary '${influxcmdline}'` or warn "Could not run curl because $!\n";
##    print "$result \n";
    $influxcmdline = "";
  }
}
$result = `curl -s -S -i -XPOST 'http://localhost:8086/write?db=styes_power' --data-binary '${influxcmdline}'` or warn "Could not run curl because $!\n";
close INPUT;


open INPUT, "<", "$logdirectory/rtl433-ccclampheat.log" or die $!;
print "opened file heat\n";
$influxcmdline = "";
foreach $line (<INPUT>)
{
  ($timestamp, $watts) = split(' ',$line);
  $influxcmdline .= "central_heating value=${watts} ${timestamp}000000000\n";

  if (length($influxcmdline) > 10000)
  {
    # -s - silent; -S - show errors
    $result = `curl -s -S -i -XPOST 'http://localhost:8086/write?db=styes_power' --data-binary '${influxcmdline}'` or warn "Could not run curl because $!\n";
##    print "$result \n";
    $influxcmdline = "";
  }
}
$result = `curl -s -S -i -XPOST 'http://localhost:8086/write?db=styes_power' --data-binary '${influxcmdline}'` or warn "Could not run curl because $!\n";
close INPUT;

open INPUT, "<", "$logdirectory/rtl433-ccclampcar.log" or die $!;
print "opened file\n";
$influxcmdline = "";
foreach $line (<INPUT>)
{
  ($timestamp, $watts) = split(' ',$line);
  $influxcmdline .= "car_charger value=${watts} ${timestamp}000000000\n";

  if (length($influxcmdline) > 10000)
  {
    # -s - silent; -S - show errors
    $result = `curl -s -S -i -XPOST 'http://localhost:8086/write?db=styes_power' --data-binary '${influxcmdline}'` or warn "Could not run curl because $!\n";
##    print "$result \n";
    print "|\n";
    $influxcmdline = "";
  }
}
$result = `curl -s -S -i -XPOST 'http://localhost:8086/write?db=styes_power' --data-binary '${influxcmdline}'` or warn "Could not run curl because $!\n";
close INPUT;

open INPUT, "<", "$logdirectory/rtl433-cciamdryer.log" or die $!;
print "opened file\n";
$influxcmdline = "";
foreach $line (<INPUT>)
{
  ($timestamp, $watts) = split(' ',$line);
  $influxcmdline .= "dryer value=${watts} ${timestamp}000000000\n";

  if (length($influxcmdline) > 10000)
  {
    # -s - silent; -S - show errors
    $result = `curl -s -S -i -XPOST 'http://localhost:8086/write?db=styes_power' --data-binary '${influxcmdline}'` or warn "Could not run curl because $!\n";
##    print "$result \n";
    print "|\n";
    $influxcmdline = "";
  }
}
$result = `curl -s -S -i -XPOST 'http://localhost:8086/write?db=styes_power' --data-binary '${influxcmdline}'` or warn "Could not run curl because $!\n";
close INPUT;


open INPUT, "<", "$logdirectory/rtl433-cciamupso.log" or die $!;
print "opened file\n";
$influxcmdline = "";
foreach $line (<INPUT>)
{
  ($timestamp, $watts) = split(' ',$line);
  $influxcmdline .= "ups_office value=${watts} ${timestamp}000000000\n";

  if (length($influxcmdline) > 10000)
  {
    # -s - silent; -S - show errors
    $result = `curl -s -S -i -XPOST 'http://localhost:8086/write?db=styes_power' --data-binary '${influxcmdline}'` or warn "Could not run curl because $!\n";
##    print "$result \n";
    print "|\n";
    $influxcmdline = "";
  }
}
$result = `curl -s -S -i -XPOST 'http://localhost:8086/write?db=styes_power' --data-binary '${influxcmdline}'` or warn "Could not run curl because $!\n";
close INPUT;


open INPUT, "<", "$logdirectory/rtl433-cciamfridge.log" or die $!;
print "opened file\n";
$influxcmdline = "";
foreach $line (<INPUT>)
{
  ($timestamp, $watts) = split(' ',$line);
  $influxcmdline .= "fridge value=${watts} ${timestamp}000000000\n";

  if (length($influxcmdline) > 10000)
  {
    # -s - silent; -S - show errors
    $result = `curl -s -S -i -XPOST 'http://localhost:8086/write?db=styes_power' --data-binary '${influxcmdline}'` or warn "Could not run curl because $!\n";
##    print "$result \n";
    print "|\n";
    $influxcmdline = "";
  }
}
$result = `curl -s -S -i -XPOST 'http://localhost:8086/write?db=styes_power' --data-binary '${influxcmdline}'` or warn "Could not run curl because $!\n";
close INPUT;


open INPUT, "<", "$logdirectory/rtl433-cciamkettle.log" or die $!;
print "opened file\n";
$influxcmdline = "";
foreach $line (<INPUT>)
{
  ($timestamp, $watts) = split(' ',$line);
  $influxcmdline .= "kettle value=${watts} ${timestamp}000000000\n";

  if (length($influxcmdline) > 10000)
  {
    # -s - silent; -S - show errors
    $result = `curl -s -S -i -XPOST 'http://localhost:8086/write?db=styes_power' --data-binary '${influxcmdline}'` or warn "Could not run curl because $!\n";
##    print "$result \n";
    print "|\n";
    $influxcmdline = "";
  }
}
$result = `curl -s -S -i -XPOST 'http://localhost:8086/write?db=styes_power' --data-binary '${influxcmdline}'` or warn "Could not run curl because $!\n";
close INPUT;


