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
	$(SSH) centos@$(MASTER_IP) sudo oc patch scc restricted -p "'{\"runAsUser\":{\"type\": \"RunAsAny\"}}'"
	$(SSH) centos@$(MASTER_IP) sudo oc patch scc restricted -p "'{\"requiredDropCapabilities\":[\"KILL\", \"MKNOD\", \"SYS_CHROOT\"]}'"
	cat templates/couchbase-single-node-persistent.yaml | sed "s/###B64_INIT_COUCHBASE###/$(shell base64 -w 0 templates/init-couchbase.sh)/g" | $(SSH) centos@$(MASTER_IP) sudo oc apply --namespace=openshift -f -
	cat templates/couchbase-petset-persistent.yaml | $(SSH) centos@$(MASTER_IP) sudo oc apply --namespace=openshift -f -

ansible_update:
	pass
