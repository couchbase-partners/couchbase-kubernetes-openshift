#!/bin/bash

set -x
set -e

# make sure aws storage classes exists
kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1beta1
kind: StorageClass
metadata:
  name: fast
  annotations:
    storageclass.beta.kubernetes.io/is-default-class: "true"
provisioner: kubernetes.io/aws-ebs
parameters:
  type: gp2
EOF
