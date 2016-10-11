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

SSH into the master instance
Load on all compute nodes:

```
# Get image
curl -sO https://s3-us-west-1.amazonaws.com/cb-openshift/rhel72_cb451.tar

# Load into local docker
docker load -i rhel72_cb451.tar

# Authorize user to be able to push
oc policy add-role-to-user admin admin -n openshift

# Push into local registry
REGISTRY_IP=$(kubectl get svc docker-registry -o jsonpath={.spec.clusterIP})
IMAGE_NAME="${REGISTRY_IP}:5000/openshift/couchbase:4.5.1-enterprise"
# Get from https://openshift.jetstack.net:8443/console/command-line
TOKEN=xxx
docker login -u admin -e tech@jetstack.io -p ${TOKEN} "${REGISTRY_IP}:5000"
docker tag afaf32cb629c $IMAGE_NAME
docker push $IMAGE_NAME
```

#### Adds couchbase template

```
MASTER_IP=w.x.y.z

# Allow root containers
ssh centos@${MASTER_IP} "sudo oc patch scc restricted -p '{\"runAsUser\":{\"type\": \"RunAsAny\"}}'"

# Allow SETUID/SETGID
ssh centos@${MASTER_IP} "sudo oc patch scc restricted -p '{\"requiredDropCapabilities\":[\"KILL\", \"MKNOD\", \"SYS_CHROOT\"]}'"

# Creates template
cat templates/couchbase-single-node-persistent.yaml | ssh centos@${MASTER_IP} sudo oc apply --namespace=openshift -f -
```
