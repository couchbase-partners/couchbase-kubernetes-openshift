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

exec ansible-playbook $@ \
    -i inventory/aws/hosts \
    -e "cluster_id=jetstack cluster_env=dev deployment_type=${deployment_type} openshift_cloudprovider_kind=aws openshift_cloudprovider_aws_access_key=$(echo "${terraform_output}" | jq -r ".iam_access_key.value") openshift_cloudprovider_aws_secret_key=$(echo "${terraform_output}" | jq -r ".iam_secret_key.value")" \
    playbooks/aws/openshift-cluster/update.yml
