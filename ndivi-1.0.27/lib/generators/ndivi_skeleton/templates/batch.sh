#!/bin/bash 

i=$1
shift
ok=0
pid_file="tmp/pids/batch.pid"
pid=$$
# check already running
/bin/kill -0 `cat $pid_file` >& /dev/null
if [ $? -eq 0 ]; then
  echo "Batch already running."
  exit
fi
echo $pid > $pid_file
 
while [ $ok -eq 0 ]; do
  cd $PWD
  rails runner $* "Batch.run($i)"
  ok=$?
  let i=i+1
done

if [ $ok -eq 42 ]; then
  echo $pid > "$pid_file.finished"  
else 
  exit $ok
fi