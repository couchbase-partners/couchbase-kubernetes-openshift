# Demo 19/12/2016

## Setup cluster

```
# setup all aws resources
make terraform_apply

# run ansible
virtualenv venv
source venv/bin/activate
./run-ansible.sh

# import RHEL image
make ssh_import_image

# create project and allow service account default in couchbase to create
# resources in its namespace and read the node labels
make ssh_project

# install patched openshift server
## fixed kube dns for PetSet https://github.com/kubernetes/kubernetes/pull/37093

```

## Custom modifications to the scheduler

- Increase weight of zone anti-affinity
- Stronger assuarances only possible with OpenShift 1.4's Pod Annotations (see https://docs.openshift.org/latest/admin_guide/manage_nodes.html#pod-anti-affinity)
- Use k8s' label for zones

```json
{
	"argument": {
		"serviceAntiAffinity": {
			"label": "failure-domain.beta.kubernetes.io/zone"
		}
	},
		"name": "Zone",
		"weight": 8
}
```

- `systemctl restart origin-master`
