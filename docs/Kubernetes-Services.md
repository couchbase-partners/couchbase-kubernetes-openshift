## Services

There are multiple kinds of services. Services are there in order to expose access (internal or external) to Pods. Let's assume that we labeled some pods with 'couchbase-cluster', then the following descriptor would expose the Couchbase Admin port internally:

```
apiVersion: v1
kind: Service
metadata:
  name: couchbase-cluster-int
  labels:
    name: couchbase-cluster
spec:
  ports:
  - port: 8091
  selector:
    name: couchbase-cluster

```

In order to register our service, the following command can be issued:

```
kubectl.sh create -f couchbase-service-internal.yaml
```

In order to list our services, we can then use:

```
david@steambox:~/Git/dmaier-couchbase/cb-openshift3/examples/k8s$ kubectl.sh get services -l name=couchbase-cluster
NAME                    CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
couchbase-cluster-int   10.247.202.160   <none>        8091/TCP   5m
```

The discovery works via environment variables:

```
david@steambox:~/Git/dmaier-couchbase/cb-openshift3/examples/k8s$ kubectl.sh exec couchbase-cluster-hhb2z -- env | grep COUCHBASE_CLUSTER_INT
COUCHBASE_CLUSTER_INT_SERVICE_HOST=10.247.202.160
COUCHBASE_CLUSTER_INT_PORT_8091_TCP_ADDR=10.247.202.160
COUCHBASE_CLUSTER_INT_PORT_8091_TCP_PROTO=tcp
COUCHBASE_CLUSTER_INT_PORT_8091_TCP_PORT=8091
COUCHBASE_CLUSTER_INT_PORT_8091_TCP=tcp://10.247.202.160:8091
COUCHBASE_CLUSTER_INT_SERVICE_PORT=8091
COUCHBASE_CLUSTER_INT_PORT=tcp://10.247.202.160:8091
```

## Kube-Proxy

The idea of services is that (as far as I understand) they are exposed via a Kube-Proxy (running on the minion node). This is usually a very good thing because it decouples the access to a specific endpoint from the actual instances those are providing it. Means that this proxy just forwards the access to several endpoints. Our 3 node replica set then causes 3 endpoints those are only accessible via Kube-Proxy:

```
Name:			couchbase-cluster-int
Namespace:		default
Labels:			name=couchbase-cluster
Selector:		name=couchbase-cluster
Type:			ClusterIP
IP:			10.247.202.160
Port:			<unset>	8091/TCP
Endpoints:		10.246.34.5:8091,10.246.34.6:8091,10.246.34.7:8091
Session Affinity:	None
```
So we can execute the following from a Pod:

```
david@steambox:~/Git/dmaier-couchbase/cb-openshift3/examples/k8s$ kubectl.sh exec couchbase-cluster-godc0 -- curl http://10.247.202.160:8091/pools

{"isAdminCreds":true,"isROAdminCreds":false,"isEnterprise":true,"pools":[],"settings":[],"uuid":[],"implementationVersion":"4.5.0-2601-enterprise","componentsVersion":{"lhttpc":"1.3.0","os_mon":"2.2.14","public_key":"0.21","asn1":"2.0.4","kernel":"2.16.4","ale":"4.5.0-2601-enterprise","inets":"5.9.8","ns_server":"4.5.0-2601-enterprise","crypto":"3.2","ssl":"5.3.3","sasl":"2.3.4","stdlib":"1.19.4"}}david@steambox:~/Git/dmaier-couchbase
```
whereby '10.247.202.160' is our service ip address. We can indeed still us the following command in order to communicate directly between the Pod endpoints:

```
kubectl.sh exec couchbase-cluster-godc0 -- curl http://10.246.34.5:8091/pools
kubectl.sh exec couchbase-cluster-godc0 -- curl http://10.246.34.6:8091/pools
kubectl.sh exec couchbase-cluster-godc0 -- curl http://10.246.34.7:8091/pools
```

Using the proxy might be a very good idea for accessing Couchbase's admin REST service on port 8091 but it is problematic for the data access because the data is sharded hash based and the clients are cluster-aware. So each client needs to establish a connection to each endpoint. It's easy to see that the service approach doesn't work in this case.

## Internal service registry

Another fair point is how to actually join the replicas into one Couchbase cluster. Whereby this is not necessary for e.g. REST services (because one app server might not know about another one behind the same proxy or load balancer), this is different for Couchbase. Each member of the cluster is aware of the other members. So how to solve this with replica sets. One solution might be a Couchbase service registry. Here some requirements: 

* The service registry is again a service.
* The service registry of a cluster needs to be existent in the context of a cluster (labels?) 
* Each service registry instance of a cluster (across Pods) needs to provide a consistent state.

