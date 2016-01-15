#! /bin/bash
cd /data/hm/rrd
for i in `ls *rrd` 
do
  grep -q $i /data/hm/bin/graph.pl
  greprc=$?
#  if [[ $greprc -eq 0 ]]
#  then
#    echo "$i is in graph.pl"
#  fi
  if [[ $greprc -eq 1 ]]
  then
    echo "$i is an ungraphed RRD"
  fi
done
