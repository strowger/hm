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
# ignore-missing-args saves a whinge mail/log entry when there are no files to transfer on the source. required an rsync upgrade.
rsync --remove-source-files --ignore-missing-args strowger@192.168.1.40:/data/hm/rtl/* /data/hm/rtl-in >> /data/hm/log/alarmbox-rsync-errors.log 2>> /data/hm/log/alarmbox-rsync-errors.log

rsync --remove-source-files --ignore-missing-args strowger@192.168.1.41:/data/hm/rtl/* /data/hm/rtl-in >> /data/hm/log/office-rsync-errors.log 2>> /data/hm/log/office-rsync-errors.log

rm /tmp/rtl433-logsync-lock

/data/hm/bin/rtl433-logimport.pl

