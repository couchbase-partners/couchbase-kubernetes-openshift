Kubernetes relies on [[Docker]] as the container solution and adds:

* Orchestration
* Resource Management
* HA clustering
* Operability
* Monitoring
* Service Discovery

and more.

## Setup

Let's first download Kubernetes:

* Make sure that the latest Vagrant version is installed (1.8.5 in my case) and ready to use. Vagrant uses by default VirtualBox as the compute host.
* Create the directory '$HOME/opt' and change the directory into it
* Execute the following commands

```
curl -sS https://get.k8s.io | bash
export KUBERNETES_PROVIDER=vagrant
cd kubernetes
./cluster/kube-up.sh
```

* I had an issue with the certificate based SSH authentication method. A quick workaround was to disable it via the Vagrant file:

```
config.ssh.pty = false
config.ssh.insert_key = false
```

You should now see the message 'Starting cluster: Using provider vagrant'. Optional providers are 'gce' (Google Compute Engine) or 'aws' (Amazon Web Services).

The setup might take a few minutes. It took something like 30 mins in my case.

## Examining the Kubernetes environment

The setup should have created 2 VM-s for your Kubernetes Cluster:

* Master: The master provides the core API by allowing to define the targeted cluster and workload state
* Node/Minion: The 'Kublet' on the 'Minion' interacts with the API server to updte the state and to start new workloads. The minions also run a 'Kube-proxy' for basic load balancing. The minions will host our containers within Pods. Pods allow to group containers logically together. Pods are running one or more containers. One minion runs one ore many pods.

Following the output of 'vagrant status':

```
david@steambox:~/opt/kubernetes$ vagrant status
Current machine states:

master                    running (virtualbox)
node-1                    running (virtualbox)

```

Then the command

```
kubectl cluster-info
```

gives further details about your cluster and which services it is running:

```
Kubernetes master is running at https://10.245.1.2
Heapster is running at https://10.245.1.2/api/v1/proxy/namespaces/kube-system/services/heapster
KubeDNS is running at https://10.245.1.2/api/v1/proxy/namespaces/kube-system/services/kube-dns
kubernetes-dashboard is running at https://10.245.1.2/api/v1/proxy/namespaces/kube-system/services/kubernetes-dashboard
Grafana is running at https://10.245.1.2/api/v1/proxy/namespaces/kube-system/services/monitoring-grafana
InfluxDB is running at https://10.245.1.2/api/v1/proxy/namespaces/kube-system/services/monitoring-influxdb
```
## Running a Couchbase Pod

The following YAML describes a Pod which is running a single [[Couchbase]] node which is only accessible on the container's internal IP via the Admin REST port 8091:

```
apiVersion: v1
kind: Pod
metadata:
  name: couchbase-pod
spec:
  containers:
  - name: couchbase-pod
    image: couchbase:enterprise-4.5.0
    ports:
    - containerPort: 8091
```

You can run this port by executing the following command:

```
kubectl create -f src/couchbase-pod.yaml
```

Then the following command shows the running Couchbase container:

```
david@steambox:~/opt/kubernetes$ ./cluster/kubectl.sh describe pods/couchbase-pod
Name:		couchbase-pod
Namespace:	default
Node:		kubernetes-node-1/10.245.1.3
Start Time:	Mon, 19 Sep 2016 20:02:58 +0200
Labels:		<none>
Status:		Running
IP:		10.246.34.5
Controllers:	<none>
Containers:
  couchbase-pod:
    Container ID:	docker://e57d7a96d388df1dfbf5fea6c56a160e30b22c93c11e2064daac4a8ccba30a5f
    Image:		couchbase:enterprise-4.5.0
    Image ID:		docker://sha256:b4606a18f237de4f51976d7d6b63f7dd7a17c39cd931dac30b9f13e39bef31ba
    Port:		8091/TCP
    Requests:
      cpu:			100m
    State:			Running
      Started:			Mon, 19 Sep 2016 20:04:15 +0200
    Ready:			True
    Restart Count:		0
    Environment Variables:	<none>
Conditions:
  Type		Status
  Initialized 	True 
  Ready 	True 
  PodScheduled 	True 
Volumes:
  default-token-ejyfn:
    Type:	Secret (a volume populated by a Secret)
    SecretName:	default-token-ejyfn
QoS Tier:	Burstable
Events:
  FirstSeen	LastSeen	Count	From				SubobjectPath			Type		Reason		Message
  ---------	--------	-----	----				-------------			--------	------		-------
  3m		3m		1	{default-scheduler }						Normal		Scheduled	Successfully assigned couchbase-pod to kubernetes-node-1
  3m		3m		1	{kubelet kubernetes-node-1}	spec.containers{couchbase-pod}	Normal		Pulling		pulling image "couchbase:enterprise-4.5.0"
  2m		2m		1	{kubelet kubernetes-node-1}	spec.containers{couchbase-pod}	Normal		Pulled		Successfully pulled image "couchbase:enterprise-4.5.0"
  2m		2m		1	{kubelet kubernetes-node-1}	spec.containers{couchbase-pod}	Normal		Created		Created container with docker id e57d7a96d388
  2m		2m		1	{kubelet kubernetes-node-1}	spec.containers{couchbase-pod}	Normal		Started		Started container with docker id e57d7a96d388
```

So in order to double check if Couchbase is running and listening on the internal IP, the following can be executed:

```
./cluster/kubectl.sh exec couchbase-pod -- curl 10.246.34.5:8091/pools/

{"isAdminCreds":true,"isROAdminCreds":false,"isEnterprise":true,"pools":[],"settings":[],"uuid":[],"implementationVersion":"4.5.0-2601-enterprise","componentsVersion":{"lhttpc":"1.3.0","os_mon":"2.2.14","public_key":"0.21","asn1":"2.0.4","kernel":"2.16.4","ale":"4.5.0-2601-enterprise","inets":"5.9.8","ns_server":"4.5.0-2601-enterprise","crypto":"3.2","ssl":"5.3.3","sasl":"2.3.4","stdlib":"1.19.4"}}
```

Our Couchbase Server cluster is indeed not yet set up, so what we need to do is to execute a few commands after the container did spin up. There are a bunch of parameters to take into account. My understanding is that we don't do this in the Pod directly. A better place might be the [[Docker]] file. But we will learn later how to do this in a better way. Anyway: I added this simple example as:

* https://raw.githubusercontent.com/dmaier-couchbase/cb-openshift3/master/examples/k8s/couchbase-pod-simple.yaml

