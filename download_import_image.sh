#!/bin/bash

set -x
set -e

IMAGE_ID=00e4d95aa26c

# download image
test -e os-cb.tar || curl -o os-cb.tar https://s3-eu-west-1.amazonaws.com/os-cb-image/os-cb-0.2.tar

# Load into local docker
docker inspect $IMAGE_ID > /dev/null || docker load -i os-cb.tar

# Authorize user to be able to push
oc policy add-role-to-user admin admin -n openshift

# Login into oc
cp /root/.kube/config /root/tmp-kube
export KUBECONFIG=/root/tmp-kube
oc login -u admin -p admin
TOKEN=$(oc whoami -t)
unset KUBECONFIG

# Push into local registry
REGISTRY_IP=$(kubectl get svc docker-registry -o "jsonpath={.spec.clusterIP}")
# Get from https://openshift.jetstack.net:8443/console/command-line
docker login -u admin -e tech@jetstack.io -p "${TOKEN}" "${REGISTRY_IP}:5000"

IMAGE_NAME="${REGISTRY_IP}:5000/openshift/couchbase-noroot:4.5.1-enterprise"
docker tag "$IMAGE_ID" "$IMAGE_NAME"
docker push "$IMAGE_NAME"
