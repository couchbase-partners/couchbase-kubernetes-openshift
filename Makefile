TERRAFORM_DIR=contrib/aws-terraform

verify:
	true

terraform_plan:
	cd $(TERRAFORM_DIR) && terraform plan

terraform_apply:
	cd $(TERRAFORM_DIR) && terraform apply

terraform_output:
	cd $(TERRAFORM_DIR) && terraform output -json


ansible_update:
	pass
