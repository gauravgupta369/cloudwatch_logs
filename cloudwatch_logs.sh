#!/bin/bash
function dumpstreams() {
  aws $AWSARGS logs describe-log-streams \
    --order-by LastEventTime --log-group-name $LOGGROUP \
    --output text | while read -a st; do 
      [ "${st[4]}" -lt "$starttime" ] && continue
      stname="${st[1]}"
      echo ${stname##*:}
    done | while read stream; do
      aws $AWSARGS logs get-log-events \
        --start-from-head --start-time $starttime \
        --log-group-name $LOGGROUP --log-stream-name $stream --output text
    done
}

AWSARGS="--profile redis_loader_prod --region ap-south-1"
LOGGROUP="/aws/lambda/redis-loader"
TAIL=
starttime=$(date --date "-1 days" +%s)000
nexttime=$(date +%s)000
dumpstreams
if [ -n "$TAIL" ]; then
  while true; do
    starttime=$nexttime
    nexttime=$(date +%s)000
    sleep 1
    dumpstreams
  done
fi