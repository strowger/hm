#!/usr/bin/perl -w
 
# send sms alerts using input from stdin

# GH 2017-10-30
# begun

$config="/data/hm/conf/alert.conf";
$logdirectory="/data/hm/log";
$logfile="alert.log";

$timestamp = time();
open LOGFILE, ">>", "$logdirectory/$logfile" or die $!;
print LOGFILE "starting alert.pl at $timestamp\n";

open CONFIG, "<", "$config" or die $!;

foreach $configline (<CONFIG>)
{
  # this is really just to keep the twilio credentials & phone nos out of git
  ($twiliosid,$twiliotoken,$fromnumber,$tonumber) = split(',',$configline);
  if (($twiliosid !~ /\#.*/) && (defined $twiliotoken) && (defined $fromnumber) &&(defined $tonumber))
  {
    chomp $tonumber;
    print LOGFILE "$timestamp: read twilio sid $twiliosid and token, src $fromnumber dst $tonumber from config\n";
  }
}

close CONFIG;

if ((! defined $twiliotoken) || (! defined $twiliosid) || (! defined $fromnumber) || (! defined $tonumber) || ($twiliosid =~ /\#.*/))
  { die "haven't got twilio credentials and numbers from config"; }


$text = do { local $/; <STDIN> };

print LOGFILE "unsanitized input text: $text";

# convert linefeeds to spaces
$text =~ tr{\n}{ };

# sanitize that input, only permit these characters:
$OK_CHARS='-a-zA-Z0-9_.@ ';
$text =~ s/[^$OK_CHARS]//go;

print LOGFILE "sanitized input text: $text\n";

$result = `curl -sS -XPOST https://api.twilio.com/2010-04-01/Accounts/${twiliosid}/Messages.json \\
-d "Body=${text}" \\
-d "To=%2B${tonumber}" \\
-d "From=%2B${fromnumber}" \\
-u '${twiliosid}:${twiliotoken}'`;

print LOGFILE "twilio response $result\n";

exit 0;

