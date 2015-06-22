#! /bin/bash
pkill power.pl
/data/hm/bin/power.pl > /data/hm/log/getpower-run.log 2> /data/hm/log/getpower-err.log &
