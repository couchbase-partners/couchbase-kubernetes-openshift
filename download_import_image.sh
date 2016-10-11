#!/bin/bash

set -x
set -e

IMAGE_ID=afaf32cb629c

# download image
test -e rhel72_cb451.tar || curl -O https://s3-us-west-1.amazonaws.com/cb-openshift/rhel72_cb451.tar

# Load into local docker
docker inspect $IMAGE_ID > /dev/null || docker load -i rhel72_cb451.tar

# Authorize user to be able to push
oc policy add-role-to-user admin admin -n openshift

# Login into oc
cp /root/.kube/config /root/tmp-kube
export KUBECONFIG=/root/tmp-kube
oc login -u admin -p admin
TOKEN=$(oc whoami -t)
unset KUBECONFIG

# Push into local registry
REGISTRY_IP=$(kubectl get svc docker-registry -o jsonpath={.spec.clusterIP})
IMAGE_NAME="${REGISTRY_IP}:5000/openshift/couchbase:4.5.1-enterprise"
# Get from https://openshift.jetstack.net:8443/console/command-line
docker login -u admin -e tech@jetstack.io -p ${TOKEN} "${REGISTRY_IP}:5000"
docker tag $IMAGE_ID $IMAGE_NAME
docker push $IMAGE_NAME
