# cb-openshift3

## Setup OpenShift cli

```
curl -LO https://github.com/openshift/origin/releases/download/v1.3.0/openshift-origin-client-tools-v1.3.0-3ab7af3d097b57f933eccef684a714f2368804e7-linux-64bit.tar.gz
tar xvzf openshift-origin-client-tools-v1.3.0-3ab7af3d097b57f933eccef684a714f2368804e7-linux-64bit.tar.gz
mv openshift-origin-client-tools-v1.3.0-3ab7af3d097b57f933eccef684a714f2368804e7-linux-64bit/oc ~/bin/
```

## Setup terraform

- Download 0.7.x from https://www.terraform.io/downloads.html

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
make terraform_apply
```

### Setup openshift

```
./run-ansible.sh

```

## Destory environment

```
make terraform_destroy
```

## Demos

### Single node template

#### Load enterprise image

```
make ssh_import_image
```

#### Adds couchbase template

```
make ssh_templates
```
