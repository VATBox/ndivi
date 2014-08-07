#!/bin/bash

task_name=$1
shift
ok=0
pid_file="tmp/pids/$task_name.pid"
pid=$$

# check already running
/bin/kill -0 `cat $pid_file` >& /dev/null
if [ $? -eq 0 ] ; then
  echo "$task_name already running."
  exit
fi
echo $pid > $pid_file
 
while [ 1 -eq 1 ]; do
  cd $PWD
  rails runner $*
  sleep 10
done

