# Importing Couchbase RHEL image

- This downloads and imports the couchbase RHEL image into the private registry

```
make ssh_import_image
```

# Create a `couchbase` Project and authorize the Service Accounts

* Create a project `couchbase`
* Allow Service Account `default` in couchbase to:
  * create resources in its namespace with role `edit`
  * read node labels with cluster role `system:node-reader`

```
make ssh_project
```

# Install patched openshift server 1.3

* Makes DNS resolving work for Pods in state terminating and unready tolerating service
* See PR: https://github.com/kubernetes/kubernetes/pull/37093
* Patched binary available here: https://storage.googleapis.com/jetstack-openshift-builds/openshift-1.3.3-dns-unready-patched.bz2

```
make ssh_dns_patch
```

# Custom modifications to the scheduler

- Increase weight of zone anti-affinity
- Stronger assuarances only possible with OpenShift 1.4's Pod Annotations (see https://docs.openshift.org/latest/admin_guide/manage_nodes.html#pod-anti-affinity)
- Use k8s' label for zones

- /etc/origin/master/scheduler.json:
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
