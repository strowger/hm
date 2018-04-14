#! /usr/bin/perl -w
#
# log2influx.pl - add data from existing logs to influxdb
#
# GH 2018-02-08
# with brian home and the others out at the party

$logdirectory="/data/hm/log";

# ebus stuff

$ebconfig="/data/hm/conf/ebusread.conf";

open EBCONFIG, "<", "$ebconfig" or die $!;
print "ebus devices: ";

foreach $configline (<EBCONFIG>)
{
  ($valuex, $field, $circuit, $localname) = split(',',$configline);
  # starts with hash means comment, so ignore
  # ignore if there isn't a value for all items
  if (($valuex !~ /\#.*/) && (defined $valuex) && (defined $field) && (defined $circuit) && (defined $localname))
  {
    # here is stuff we just do for each *valid* config line
    chomp $localname;
    print "$localname ";
    open INPUT, "<", "$logdirectory/$localname.log" or die $!;
    $result = "";
    $influxcmdline = "";
    while ( $line = <INPUT> )
    {
      ($timestamp, $value) = split(' ',$line);
      if ( $value eq "" ) { next; }
      $influxcmdline .= "${localname} value=${value} ${timestamp}000000000\n";
      if (length($influxcmdline) > 20000)
      {
        $result = `curl -s -S -i -XPOST 'http://localhost:8086/write?db=styes_ebus' --data-binary '${influxcmdline}'` or warn "Could not run curl because $!\n";
        $influxcmdline = "";
        # attempt to sleep 100ms
        select(undef, undef, undef, 0.1);
      }
    }
  }

}

$result = `curl -s -S -i -XPOST 'http://localhost:8086/write?db=styes_ebus' --data-binary '${influxcmdline}'` or warn "Could not run curl because $!\n";
$influxcmdline = "";

close EBCONFIG;


exit 0;

# 1-wire stuff - the sleep after each curl will make this take a week to run

$owconfig="/data/hm/conf/1wireread.conf";

open OWCONFIG, "<", "$owconfig" or die $!;

foreach $configline (<OWCONFIG>)
{
  ($configdevice, $configvalue, $configfilename) = split(',',$configline);
  if (($configdevice !~ /\#.*/) && (defined $configdevice) && (defined $configvalue) && (defined $configfilename))
  {
    chomp $configfilename;
    print "onewire: working on $configfilename\n";
    open INPUT, "<", "$logdirectory/$configfilename.log" or die $!;
    $result = "";
    $influxcmdline = "";
    while ( $line = <INPUT> )
    {
      ($timestamp, $value) = split(' ',$line);
      if ( $value eq "" ) { next; }
      if ( $configfilename =~ /hum$/ )
      {
        # just silently ignore humidity values that make no sense, of which there are quite a lot
        if (( $value < 0 ) || ( $value > 100 )) { next; }
      }
      $influxcmdline .= "${configfilename} value=${value} ${timestamp}000000000\n";

      if (length($influxcmdline) > 20000)
      {
      $result = `curl -s -S -i -XPOST 'http://localhost:8086/write?db=styes_1wire' --data-binary '${influxcmdline}'` or warn "Could not run curl because $!\n";
      $influxcmdline = "";
      sleep 1;
      }

    }
    $result = `curl -s -S -i -XPOST 'http://localhost:8086/write?db=styes_1wire' --data-binary '${influxcmdline}'` or warn "Could not run curl because $!\n";
    sleep 1;
  }
}


# basement ups stuff

open INPUT, "<", "$logdirectory/upsb-batterycharge.log" or die $!;
print "opened ups battery charge log\n";
$result = "";
$influxcmdline = "";
while ( $line = <INPUT> )
{
  ($timestamp, $value) = split(' ',$line);
  $influxcmdline .= "ups_basement_charge value=${value} ${timestamp}000000000\n";

  if (length($influxcmdline) > 10000)                                                                                                              {                                                                                                                                                  # -s - silent; -S - show errors
    $result = `curl -s -S -i -XPOST 'http://localhost:8086/write?db=styes_power' --data-binary '${influxcmdline}'` or warn "Could not run curl because $!\n";
    $influxcmdline = "";
   }
}
$result = `curl -s -S -i -XPOST 'http://localhost:8086/write?db=styes_power' --data-binary '${influxcmdline}'` or warn "Could not run curl because $!\n";                                                                                                                                         close INPUT;


open INPUT, "<", "$logdirectory/upsb-batteryvolts.log" or die $!;
print "opened ups battery volts log\n";
$result = "";
$influxcmdline = "";
while ( $line = <INPUT> )
{
  ($timestamp, $value) = split(' ',$line);
  $influxcmdline .= "ups_basement_battery_volts value=${value} ${timestamp}000000000\n";

  if (length($influxcmdline) > 10000)                                                                                                              {                                                                                                                                                  # -s - silent; -S - show errors
    $result = `curl -s -S -i -XPOST 'http://localhost:8086/write?db=styes_power' --data-binary '${influxcmdline}'` or warn "Could not run curl because $!\n";
    $influxcmdline = "";
   }
}
$result = `curl -s -S -i -XPOST 'http://localhost:8086/write?db=styes_power' --data-binary '${influxcmdline}'` or warn "Could not run curl because $!\n";                                                                                                                                         close INPUT;


open INPUT, "<", "$logdirectory/upsb-mainsfreq.log" or die $!;
print "opened ups mains freq log\n";
$result = "";
$influxcmdline = "";
while ( $line = <INPUT> )
{
  ($timestamp, $value) = split(' ',$line);
  $influxcmdline .= "ups_basement_mains_frequency value=${value} ${timestamp}000000000\n";

  if (length($influxcmdline) > 10000)                                                                                                              {                                                                                                                                                  # -s - silent; -S - show errors
    $result = `curl -s -S -i -XPOST 'http://localhost:8086/write?db=styes_power' --data-binary '${influxcmdline}'` or warn "Could not run curl because $!\n";
    $influxcmdline = "";
   }
}
$result = `curl -s -S -i -XPOST 'http://localhost:8086/write?db=styes_power' --data-binary '${influxcmdline}'` or warn "Could not run curl because $!\n";                                                                                                                                         close INPUT;


open INPUT, "<", "$logdirectory/upsb-mainsvolts.log" or die $!;
print "opened ups mains volts log\n";
$result = "";
$influxcmdline = "";
while ( $line = <INPUT> )
{
  ($timestamp, $value) = split(' ',$line);
  $influxcmdline .= "ups_basement_mains_volts value=${value} ${timestamp}000000000\n";

  if (length($influxcmdline) > 10000)                                                                                                              {                                                                                                                                                  # -s - silent; -S - show errors
    $result = `curl -s -S -i -XPOST 'http://localhost:8086/write?db=styes_power' --data-binary '${influxcmdline}'` or warn "Could not run curl because $!\n";
    $influxcmdline = "";
   }
}
$result = `curl -s -S -i -XPOST 'http://localhost:8086/write?db=styes_power' --data-binary '${influxcmdline}'` or warn "Could not run curl because $!\n";                                                                                                                                         close INPUT;



open INPUT, "<", "$logdirectory/upsb-outputvolts.log" or die $!;
print "opened ups output volts log\n";
$result = "";
$influxcmdline = "";
while ( $line = <INPUT> )
{
  ($timestamp, $value) = split(' ',$line);
  $influxcmdline .= "ups_basement_output_volts value=${value} ${timestamp}000000000\n";

  if (length($influxcmdline) > 10000)                                                                                                              {                                                                                                                                                  # -s - silent; -S - show errors
    $result = `curl -s -S -i -XPOST 'http://localhost:8086/write?db=styes_power' --data-binary '${influxcmdline}'` or warn "Could not run curl because $!\n";
    $influxcmdline = "";
   }
}
$result = `curl -s -S -i -XPOST 'http://localhost:8086/write?db=styes_power' --data-binary '${influxcmdline}'` or warn "Could not run curl because $!\n";                                                                                                                                         close INPUT;



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


