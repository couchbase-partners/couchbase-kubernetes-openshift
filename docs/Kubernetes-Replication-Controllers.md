Replication controllers manage the number of nodes (minions) on which a pod (and it's containers) are running. So it's ensuring that a specific number of copies of the stack are running. The idea is just define the number of replicas and Kubernetes takes care of that these are running.

The next example extends our simple Pod example (running a single Couchbase node) by making sure that at least 3 nodes of Couchbase are running.

```
apiVersion: v1
kind: ReplicationController
metadata:
  name: couchbase-cluster
  labels:
    name: couchbase-cluster
spec:
  replicas: 3
  selector:
    name: couchbase-cluster
  template:
    metadata:
      labels:
        name: couchbase-cluster
    spec:
      containers:
      - name: couchbase-server
        image: couchbase:enterprise-4.5.0
        ports:
        - containerPort: 8091
```

You can describe the replication controller by using the following command:

```
david@steambox:~/Git/dmaier-couchbase/cb-openshift3/examples/k8s$ /home/david/opt/kubernetes/cluster/kubectl.sh describe rc -l name=couchbase-cluster
Name:		couchbase-cluster
Namespace:	default
Image(s):	couchbase:enterprise-4.5.0
Selector:	name=couchbase-cluster
Labels:		name=couchbase-cluster
Replicas:	3 current / 3 desired
Pods Status:	3 Running / 0 Waiting / 0 Succeeded / 0 Failed
No volumes.
Events:
  FirstSeen	LastSeen	Count	From				SubobjectPath	Type		Reason			Message
  ---------	--------	-----	----				-------------	--------	------			-------
  7m		7m		1	{replication-controller }			Normal		SuccessfulCreate	Created pod: couchbase-cluster-ta0eh
  7m		7m		1	{replication-controller }			Normal		SuccessfulCreate	Created pod: couchbase-cluster-rg7jp
  7m		7m		1	{replication-controller }			Normal		SuccessfulCreate	Created pod: couchbase-cluster-r2chl

```

