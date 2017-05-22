## Setup OpenShift cli

```
curl -L O openshift-client.tar.gz https://github.com/openshift/origin/releases/download/v1.5.1/openshift-origin-client-tools-v1.5.1-7b451fc-linux-64bit.tar.gz
tar xvzf openshift-client.tar.gz --strip-components=1 -C ~/bin/
```

## Setup terraform

- Download 0.9.x from https://www.terraform.io/downloads.html

## Setup python env

```
virtualenv venv
source venv/bin/activate
pip install -r contrib/ansible/requirements.txt
```

## Setup the environment on AWS

Make sure you have configured environemnt variables for your AWS account: http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html

### Setup infrastructure

```
# check the variables if they suit your needs (see `contrib/aws-terraform/variables.tf`)
# If not create a new file `contrib/aws-terraform/terraform.tfvars`
make terraform_apply
```

### Setup openshift

```
./run-ansible.sh

```

## Destroy environment

```
make terraform_destroy
```
