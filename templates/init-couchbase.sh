#!/bin/bash

set -x

USER=${COUCHBASE_USER:-admin}
PASSWORD=${COUCHBASE_PASSWORD:-password}
DATABASE=${COUCHBASE_DATABASE:-sampledb}
MEMORY_LIMIT=${MEMORY_LIMIT:-1024}
MEMORY=$(expr $(expr $MEMORY_LIMIT - 256) / 2)

# wait for reachability
while true; do
   if curl --fail -s http://127.0.0.1:8091 > /dev/null; then
     break
   fi
   sleep 1
done

# exit if failing
set -e

couchbase-cli cluster-init -c 127.0.0.1:8091 \
    --cluster-init-username=${USER} \
    --cluster-init-password=${PASSWORD} \
    --cluster-ramsize=${MEMORY} \
    --cluster-index-ramsize=${MEMORY} \
    --services=data,index,query

couchbase-cli bucket-create -c 127.0.0.1:8091 -u ${USER} -p ${PASSWORD} \
    --bucket=${DATABASE} --bucket-type=couchbase --bucket-port=11222 \
    --bucket-ramsize=${MEMORY} --bucket-replica=1
