## Next Steps moving forward

### Couchbase 

* Better support of container resource constraints

### Kubernetes / OpenShift

* Support Node Local SSD: https://github.com/kubernetes/kubernetes/pull/30044 (Sticky EmptyDir PV) 
* Don't shutdown DNS for PetSet/StatefulSet Pods in State `Terminating`: https://github.com/kubernetes/kubernetes/pull/37093
* Easier exposure of node labels to Pods (currently requires cluster level access to allow Pods to read node lables)
  
### Sidecar

* Operate an elected sidecar master
* Creation of a Bucket specified in the OS template
* Operate as parent process of Couchbase
* Monitor free disk space 