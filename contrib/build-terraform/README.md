# Build Terrafrom

Terraform to spin up a openshift rpm build instance

## Build custom OS rpms

### Connect to vm

```
ssh -A root@$(terraform output instance_ip)
```

### Trigger Build

```
git tag v1.4.0-jetstack1
vim .tito/packages/origin # change versiono tehre
make build-rpms
```
