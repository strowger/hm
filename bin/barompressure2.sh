#! /bin/bash
#
# temporary hack to fetch data from another barometer on the internet and store it in an rrd
# so we can compare it to our 1-w one
#
if [ -e /tmp/barom-lock ]
then
  echo "lockfile exists, aborting"
  exit 1
fi
touch /tmp/barom-lock

TIMESTAMP=`date +%s`
# last sed is for safety, remove non-digit characters, so if the site changes
# to include backticks or whatever, we don't execute them
PRES=`wget -O - --quiet http://www.weatherforce.org.uk/index.php|grep gizmobaro|grep hPa|awk '{print $3}'|sed 's/id="gizmobaro">//'|sed 's/[^0-9].[^0-9]//g'`

echo -n "$TIMESTAMP " >> /data/hm/log/barompressure2.log
echo $PRES >> /data/hm/log/barompressure2.log

rrdtool update /data/hm/rrd/barompressure2.rrd $TIMESTAMP:$PRES

rm /tmp/barom-lock

