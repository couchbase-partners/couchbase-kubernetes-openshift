#!/bin/bash

set -x
set -e

# import image
oc --namespace openshift delete imagestream couchbase-rhel-4.5 || true
oc --namespace openshift import-image couchbase-rhel-4.5 --confirm --from='eu.gcr.io/jetstack-couchbase/server:rhel-4.5.1-jetstack0.2'
