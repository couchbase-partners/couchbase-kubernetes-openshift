TERRAFORM_DIR=contrib/aws-terraform
SSH=ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no

verify:
	true

terraform_plan:
	cd $(TERRAFORM_DIR) && terraform plan

terraform_apply:
	cd $(TERRAFORM_DIR) && terraform apply

terraform_output:
	$(eval TERRAFORM_OUTPUT = $(shell cd $(TERRAFORM_DIR); terraform output -json))

terraform_destroy:
	cd $(TERRAFORM_DIR) && terraform destroy

master_ip: terraform_output
	$(eval MASTER_IP = $(shell echo '$(TERRAFORM_OUTPUT)' | jq -r ".master_ip.value[0]"))

ssh_import_image: master_ip
	$(SSH) centos@$(MASTER_IP) sudo bash < download_import_image.sh

ssh_templates: master_ip
	## only needed for the root image
	#$(SSH) centos@$(MASTER_IP) sudo oc patch scc restricted -p "'{\"runAsUser\":{\"type\": \"RunAsAny\"}}'"
	#$(SSH) centos@$(MASTER_IP) sudo oc patch scc restricted -p "'{\"requiredDropCapabilities\":[\"KILL\", \"MKNOD\", \"SYS_CHROOT\"]}'"
	cat templates/couchbase-single-node-persistent.yaml | sed "s/###B64_INIT_COUCHBASE###/$(shell base64 -w 0 templates/init-couchbase.sh)/g" | $(SSH) centos@$(MASTER_IP) sudo oc apply --namespace=openshift -f -
	$(eval REGISTRY_IP = $(shell $(SSH) centos@$(MASTER_IP) sudo kubectl get svc docker-registry -o jsonpath={.spec.clusterIP}))
	cat templates/couchbase-petset-persistent.yaml | sed "s/###REGISTRY_IP###/$(REGISTRY_IP)/g" | $(SSH) centos@$(MASTER_IP) sudo oc apply --namespace=openshift -f -
	cat templates/couchbase-petset-ephemeral.yaml | sed "s/###REGISTRY_IP###/$(REGISTRY_IP)/g" | $(SSH) centos@$(MASTER_IP) sudo oc apply --namespace=openshift -f -
	
ssh_project: master_ip
	$(SSH) centos@$(MASTER_IP) sudo oc new-project couchbase
	$(SSH) centos@$(MASTER_IP) sudo oc policy add-role-to-user edit system:serviceaccount:couchbase:default -n couchbase
	$(SSH) centos@$(MASTER_IP) sudo oc policy add-role-to-user admin admin -n couchbase
ansible_update:
	pass
