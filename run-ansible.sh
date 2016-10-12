#!/bin/bash

set -e

source venv/bin/activate

set -x

cd contrib/ansible

pip install -r requirements.txt

terraform_output=$(cd ../aws-terraform; terraform output -json)

# check for operationg system
operating_system=$(echo "${terraform_output}" | jq -r ".operating_system.value")
if [ "${operating_system}" = "rhel7" ]; then
    deployment_type="openshift-enterprise"
else
    deployment_type="origin"
fi

VARS="cluster_id=jetstack"
VARS="${VARS} cluster_env=dev"
VARS="${VARS} deployment_type=${deployment_type}"
VARS="${VARS} openshift_cloudprovider_kind=aws"
VARS="${VARS} openshift_cloudprovider_aws_access_key=$(echo "${terraform_output}" | jq -r ".iam_access_key.value")"
VARS="${VARS} openshift_cloudprovider_aws_secret_key=$(echo "${terraform_output}" | jq -r ".iam_secret_key.value")"
VARS="${VARS} openshift_master_default_subdomain=$(echo "${terraform_output}" | jq -r ".hostname_apps.value")"
VARS="${VARS} openshift_master_cluster_public_hostname=$(echo "${terraform_output}" | jq -r ".hostname_master.value")"

exec ansible-playbook \
    -i inventory/aws/hosts \
    -e "${VARS}" \
    playbooks/aws/openshift-cluster/update.yml
