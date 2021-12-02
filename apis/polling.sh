#!/bin/bash

declare -i duration=1
declare hasUrl=""
declare endpoint
declare bStatus=false
declare iCounter=0

usage() {
    cat <<END
    polling.sh [-i] [-h] endpoint
    
    Report the health status of the endpoint
    -i: include Uri for the format
    -h: help
END
}

while getopts "ih" opt; do 
  case $opt in 
    i)
      hasUrl=true
      ;;
    h) 
      usage
      exit 0
      ;;
    \?)
     echo "Unknown option: -${OPTARG}" >&2
     exit 1
     ;;
  esac
done

shift $((OPTIND -1))

if [[ $1 ]]; then
  endpoint=$1
else
  echo "Please specify the endpoint."
  usage
  exit 1 
fi 


healthcheck() {
    declare url=$1    
    result=$(curl --http2 -i $url 2>/dev/null | grep "HTTP/[12][12\.]*")
    echo  $result
}

while [[ true ]]; do
   result=`healthcheck $endpoint` 
   declare status
   if [[ -z $result ]]; then 
      status="N/A"
   else
      status=${result:6:4}
      #echo $status
   fi 
   timestamp=$(date "+%Y%m%d-%H%M%S")
   #if [[ -z $hasUrl ]]; then
   #  echo $status #"$timestamp | $status "
   #else
   #  echo $status #"$timestamp | $status | $endpoint " 
   #fi

   if [[ $status -eq 200 ]]; then
    echo $status
    bStatus=true
    ((iCounter=iCounter+1))
    if [[ $iCounter -eq 45 ]]; then
        break
    fi    
   else
    #We come here if the slot is not healty
    echo $status
    bStatus=false
    break
   fi
   sleep $duration
done


if [ bStatus ] && [ $iCounter -eq 45 ]; then
    echo "Deploy to Prod"
    exit 0
elif [[ bStatus -eq 'false' ]]; then
    echo "Deploy to Stage"
    exit 1
fi
