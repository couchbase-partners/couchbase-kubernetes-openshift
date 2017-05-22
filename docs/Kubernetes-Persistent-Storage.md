Containers are by default transient (so stateless). If a container dies, then all changes those were performed within the container are lost. A persistent volume that exists outside the container allows us to save our important data across container outages. Persistent storage with Kubernetes lasts beyond the lifetime of a container. There are several kinds of storage supported:

*** Temp. disks**: 'emptyDir' can be backed by the medium 'Memory'. The stored files will be removed when the Pod is deleted but they sustain the restart of containers within the Pod. 
* **Cloud volumes**: As 'gcePersistentDisk' or 'awsElasticBlockStore'
* **Host**: The 'hostPath' volume allows you mount a directory from the hosts file system into the Pod
* **Secret**: The 'secret' volume is used to pass sensitive information to Pods
* **SAN**: The 'nfs' and 'iscsi' allow you to mount shared space.
* **Git**: The 'gitRepo' volume is used to share the contents of a Git repo
...

## Mounting an NFS share

### NFS server setup

First we need an NFS server. My host is an Ubuntu one and so the following works:

```
sudo  apt-get install nfs-kernel-server
```

Then create a volume:

```
mkdir -p /home/david/opt/kubernetes/volumes/data
sudo mkdir -p /export/data
sudo chmod 777 -R /export
```
Then add the following line to '/etc/fstab' in order to define how to bind the 'data' directory to '/export/data'.

```
/home/david/opt/kubernetes/volumes/data  /export/data   none    bind  0  0
```

Finally bind it:

```
sudo mount -a
```

Now let's export our data share by adding the following to the config file '/etc/exports'

```
/export       192.168.178.0/24(rw,fsid=0,insecure,no_subtree_check,async)
/export/data  192.168.178.0/24(rw,nohide,insecure,no_subtree_check,async)
```

Last but not least let's try to mount the just exported NFS share (this should work on another machine in the same network):

```
sudo mkdir /mnt/nfstest
sudo mount -t nfs -o proto=tcp,port=2049 192.168.178.112:/ /mnt/nfstest
touch /home/david/opt/kubernetes/volumes/data/test.txt
ls /mnt/nfstest/data/
```

### Using the NFS share

Now, we want to use our share in our pods.

First we need to create a PersistentVolume resource based on the following file:

```
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nfs-share
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteMany
  nfs:
    server: 192.168.178.112
    path: "/"
```

The following command will create our 'nfs-share':

```
kubectl.sh create -f nfs-share-pv.yaml
```

In order to assign it to a persistent volume claim, we use the following YAML file:

```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nfs-share
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Gi
```

The following shows the output of getting details about the share:

```
david@steambox:~/Git/dmaier-couchbase/cb-openshift3/examples/k8s$ kubectl.sh get pv
NAME        CAPACITY   ACCESSMODES   STATUS    CLAIM               REASON    AGE
nfs-share   1Gi        RWX           Bound     default/nfs-share             22m
```

OK, now that we have created a persistent volume, let's add it to our replication controller:

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
        volumeMounts:
        - mountPath: /mnt
          name: nfs
      volumes:
      - name: nfs
        persistentVolumeClaim:
          claimName: nfs-share
```

The following command (pod id needs to be adapted) then lists the contents of our shared storage:

```
david@steambox:~/Git/dmaier-couchbase/cb-openshift3/examples/k8s$ kubectl.sh exec couchbase-cluster-godc0 -- ls /mnt/data
test.txt
```