export LC_ALL = C.UTF-8

ENVIRONMENT ?= regiocloud

VERSION_CEPH ?= quincy
VERSION_MANAGER ?= latest
VERSION_OPENSTACK ?= 2023.1

TERRAFORM ?= terraform
TERRAFORM_BLUEPRINT ?= testbed-default

variables:
	$(eval ANSIBLE_COLLECTION_COMMONS_PATH := $(shell yq '.repositories."ansible-collection-commons".path' playbooks/vars/repositories.yml))
	$(eval ANSIBLE_COLLECTION_COMMONS_REPO := $(shell yq '.repositories."ansible-collection-commons".repo' playbooks/vars/repositories.yml))
	$(eval ANSIBLE_COLLECTION_SERVICES_PATH := $(shell yq '.repositories."ansible-collection-service".path' playbooks/vars/repositories.yml))
	$(eval ANSIBLE_COLLECTION_SERVICES_REPO := $(shell yq '.repositories."ansible-collection-service".repo' playbooks/vars/repositories.yml))
	$(eval REPOSITORY_SERVER := $(shell yq '."repository_server"' playbooks/vars/repositories.yml))
	$(eval TERRAFORM_BASE_PATH := $(shell yq '.repositories."terraform-base".path' playbooks/vars/repositories.yml))
	$(eval TERRAFORM_BASE_REPO := $(shell yq '.repositories."terraform-base".repo' playbooks/vars/repositories.yml))
	$(eval TESTBED_PATH := $(shell yq '.repositories.testbed.path' playbooks/vars/repositories.yml))
	$(eval TESTBED_REPO := $(shell yq '.repositories.testbed.repo' playbooks/vars/repositories.yml))

venv = . venv/bin/activate

help:  ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

clean: ## Destroy infrastructure with Terraform.
	make -C terraform \
	  ENVIRONMENT=$(ENVIRONMENT) \
	  TERRAFORM=$(TERRAFORM) \
	  clean

create: prepare ## Create required infrastructure with Terraform.
	make -C terraform \
	  ENVIRONMENT=$(ENVIRONMENT) \
	  TERRAFORM=$(TERRAFORM) \
	  VERSION_CEPH=$(VERSION_CEPH) \
	  VERSION_MANAGER=$(VERSION_MANAGER) \
	  VERSION_OPENSTACK=$(VERSION_OPENSTACK) \
	  create

login: ## Log in on the manager.
	@make -C terraform \
	  ENVIRONMENT=$(ENVIRONMENT) \
	  login

bootstrap: create deps variables ## Bootstrap everything.
	${venv} ; ansible-playbook playbooks/deploy.yml \
	  -i ansible/localhost_inventory.yaml \
	  -e ansible_galaxy=ansible-galaxy \
	  -e ansible_playbook=ansible-playbook \
	  -e basepath="$(PWD)" \
	  -e cloud_env=$(ENVIRONMENT) \
	  -e repo_path="$(PWD)/.src/$(REPOSITORY_SERVER)" \
	  -e manual_create=true \
	  -e manual_deploy=true \
	  -e version_ceph=$(VERSION_CEPH) \
	  -e version_manager=$(VERSION_MANAGER) \
	  -e version_openstack=$(VERSION_OPENSTACK)

manager: bootstrap ## Deploy only the manager service.
	make -C terraform \
	  ENVIRONMENT=$(ENVIRONMENT) \
	  TERRAFORM=$(TERRAFORM) \
	  deploy-manager

identity: manager ## Deploy only identity services.
	make -C terraform \
	  ENVIRONMENT=$(ENVIRONMENT) \
	  TERRAFORM=$(TERRAFORM) \
	  deploy-identity

ceph: manager ## Deploy only ceph services.
	make -C terraform \
	  ENVIRONMENT=$(ENVIRONMENT) \
	  deploy-ceph

deploy: bootstrap ## Deploy everything and then check it.
	make -C terraform \
	  ENVIRONMENT=$(ENVIRONMENT) \
	  TERRAFORM=$(TERRAFORM) \
	  deploy
	make -C terraform \
	  ENVIRONMENT=$(ENVIRONMENT) \
	  TERRAFORM=$(TERRAFORM) \
	  bootstrap
	make -C terraform \
	  ENVIRONMENT=$(ENVIRONMENT) \
	  TERRAFORM=$(TERRAFORM) \
	  check

prepare: variables
	${venv} ; ansible-playbook -i localhost, ansible/check-local-versions.yml

	mkdir -p $$(dirname $(ANSIBLE_COLLECTION_COMMONS_PATH))
	mkdir -p $$(dirname $(ANSIBLE_COLLECTION_SERVICES_PATH))
	mkdir -p $$(dirname $(TERRAFORM_BASE_PATH))
	mkdir -p $$(dirname $(TESTBED_PATH))

	if [ ! -e .src/$(TESTBED_PATH) ]; then git clone $(TESTBED_REPO) .src/$(TESTBED_PATH); else git -C .src/$(TESTBED_PATH) pull; fi
	if [ ! -e .src/$(TERRAFORM_BASE_PATH) ]; then git clone $(TERRAFORM_BASE_REPO) .src/$(TERRAFORM_BASE_PATH); else git -C .src/$(TERRAFORM_BASE_PATH) pull; fi
	if [ ! -e .src/$(ANSIBLE_COLLECTION_COMMONS_PATH) ]; then git clone $(ANSIBLE_COLLECTION_COMMONS_REPO) .src/$(ANSIBLE_COLLECTION_COMMONS_PATH); else git -C .src/$(ANSIBLE_COLLECTION_COMMONS_PATH)  pull; fi
	if [ ! -e .src/$(ANSIBLE_COLLECTION_SERVICES_PATH) ]; then git clone $(ANSIBLE_COLLECTION_SERVICES_REPO) .src/$(ANSIBLE_COLLECTION_SERVICES_PATH); else git -C .src/$(ANSIBLE_COLLECTION_SERVICES_PATH) pull; fi

	rsync -avz .src/$(TERRAFORM_BASE_PATH)/$(TERRAFORM_BLUEPRINT)/ terraform

venv/bin/activate: Makefile
	@which python3 > /dev/null || { echo "Missing requirement: python3" >&2; exit 1; }
	@which jq > /dev/null || { echo "Missing requirement: jq" >&2; exit 1; }
	virtualenv --version > /dev/null || { echo "Missing requirement: virtualenv -- aborting" >&2; exit 1; }
	[ -e venv/bin/python ] || virtualenv -p $$(which python3) venv > /dev/null
	${venv} && pip3 install -r requirements.txt
	touch venv/bin/activate

venv/bin/tofu: venv/bin/activate
	$(eval TOFU_VERSION := 1.6.0-alpha2)
	$(eval OS := $(shell uname | tr '[:upper:]' '[:lower:]'))
	$(eval ARCH := $(shell uname -m | sed -e 's/aarch64/arm64/' -e 's/x86_64/amd64/'))
	curl -L --output venv/bin/tofu.zip \
		"https://github.com/opentofu/opentofu/releases/download/v${TOFU_VERSION}/tofu_${TOFU_VERSION}_${OS}_${ARCH}.zip"
	rm -f venv/bin/tofu
	unzip -d venv/bin/ venv/bin/tofu.zip tofu
	chmod +x venv/bin/tofu
	rm -f venv/bin/tofu.zip
	${venv} && tofu version

deps: venv/bin/tofu venv/bin/activate variables

phony: bootstrap clean create deploy identity login manager prepare ceph deps variables
