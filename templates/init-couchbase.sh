#!/bin/bash

set -x 

USERNAME=${COUCHBASE_USERNAME:-admin}
PASSWORD=${COUCHBASE_PASSWORD:-password}
DATABASE=${COUCHBASE_DATABASE:-sampledb}

# wait for reachability
while true; do
   if curl --fail -s http://127.0.0.1:8091 > /dev/null; then
     break
   fi
   sleep 1
done

# exit if failing
set -e

CURL="curl --fail"
CURL_AUTH="${CURL} -u ${USERNAME}:${PASSWORD}"

# Setup index and memory quota
${CURL} -X POST http://127.0.0.1:8091/pools/default -d memoryQuota=256 -d indexMemoryQuota=256

# Setup services
${CURL} http://127.0.0.1:8091/node/controller/setupServices -d services=kv%2Cn1ql%2Cindex

# Setup credentials
${CURL} http://127.0.0.1:8091/settings/web -d port=8091 -d username=${USERNAME} -d password=${PASSWORD}

# Setup Memory Optimized Indexes
${CURL_AUTH} -X POST http://127.0.0.1:8091/settings/indexes -d 'storageMode=memory_optimized'

# Create empty bucket
${CURL_AUTH} -X POST http://127.0.0.1:8091/pools/default/buckets -d "name=${DATABASE}" -d "type=couchbase" -d "authType=none" -d "proxyPort=32000" -d "ramQuotaMB=256"
