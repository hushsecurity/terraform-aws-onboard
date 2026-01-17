# Terraform Module Makefile
MODULE_NAME = terraform-hush-ecs

.PHONY: all
all: lint validate

.PHONY: clean
clean:
	@find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name "*.tfplan" -exec rm -f {} + 2>/dev/null || true
	@find . -type f -name "*.tfstate*" -exec rm -f {} + 2>/dev/null || true
	@rm -rf .tflintcache/

.PHONY: lint
lint:
	@tflint --init
	@tflint --recursive
	@terraform fmt -check=true -diff=true -recursive .

.PHONY: validate
validate:
	@terraform init -backend=false
	@terraform validate

.PHONY: format
format:
	@terraform fmt -recursive .
