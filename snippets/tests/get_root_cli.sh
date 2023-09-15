#!/bin/bash

container_id=`docker container ls | grep postgres | awk '{print $1}'`
if [ "$container_id" = "" ]; then
   echo "Run start_server.sh first"
   exit
fi

mode=-i
if [ "$1" == "--tty" ]; then
   mode=-it
fi
docker exec $mode $container_id psql -U postgres 