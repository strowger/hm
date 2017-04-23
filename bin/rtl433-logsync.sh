#! /bin/bash
#
# 20170404 rsync rtl433 logs from alarmbox
# 
# used to be a simple one-liner in a cron job but it has to have locking otherwise
# rsync processes can accumulate until one or both boxes falls over

if [ -e /tmp/rtl433-logsync-lock ]
then
  echo "lockfile exists, aborting"
  exit 1
fi
touch /tmp/rtl433-logsync-lock

rsync --remove-source-files strowger@192.168.1.40:/data/hm/rtl/* /data/hm/rtl-in >> /data/hm/log/alarmbox-rsync-errors.log 2>> /data/hm/log/alarmbox-rsync-errors.log

rm /tmp/rtl433-logsync-lock

