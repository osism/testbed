export LC_ALL = C.UTF-8

CONFIGURATION ?= main

ENVIRONMENT ?= the_environment
CLOUD ?= $(ENVIRONMENT)

IMAGE_USERNAME ?= ubuntu

CEPH_STACK ?= ceph-ansible
DEPLOY_MODE ?= manager

VERSION_CEPH ?= reef
VERSION_MANAGER ?= latest
VERSION_OPENSTACK ?= 2024.2

# renovate: datasource=github-releases depName=opentofu/opentofu
TOFU_VERSION ?= 1.10.6
TERRAFORM ?= tofu
TERRAFORM_BLUEPRINT ?= testbed-default

venv = . venv/bin/activate
export PATH := ${PATH}:${PWD}/venv/bin

.PHONY: help
help:  ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: setup
setup: ## Prepare the repository.
	@${venv}; contrib/setup-testbed.py \
	  --environment $(ENVIRONMENT) \
	  --cloud $(CLOUD) \

.PHONY: clean
clean: setup ## Destroy infrastructure with OpenTofu.
	make -C terraform \
	  CLOUD=$(CLOUD) \
	  ENVIRONMENT=$(ENVIRONMENT) \
	  TERRAFORM=$(TERRAFORM) \
	  clean

.PHONY: wipe-local-install
wipe-local-install: ## Wipe the software dependencies in `venv`.
	rm -rf venv .src

.PHONY: create
create: prepare ## Create required infrastructure with OpenTofu.
	@${venv}; contrib/setup-testbed.py \
	  --environment $(ENVIRONMENT) \
	  --cloud $(CLOUD)
	make -C terraform \
	  CEPH_STACK=$(CEPH_STACK) \
	  CLOUD=$(CLOUD) \
	  CONFIGURATION=$(CONFIGURATION) \
	  ENVIRONMENT=$(ENVIRONMENT) \
	  IMAGE_USERNAME=$(IMAGE_USERNAME) \
	  TERRAFORM=$(TERRAFORM) \
	  VERSION_CEPH=$(VERSION_CEPH) \
	  VERSION_MANAGER=$(VERSION_MANAGER) \
	  VERSION_OPENSTACK=$(VERSION_OPENSTACK) \
	  create

.PHONY: login
login: setup ## Log in on the manager.
	@make -C terraform \
	  CLOUD=$(CLOUD) \
	  ENVIRONMENT=$(ENVIRONMENT) \
	  login

.PHONY: vpn-wireguard
vpn-wireguard: setup ## Establish a wireguard vpn tunnel.
	@make -C terraform \
	  CLOUD=$(CLOUD) \
	  ENVIRONMENT=$(ENVIRONMENT) \
	  vpn-wireguard

.PHONY: vpn-wireguard-config
vpn-wireguard-config: setup ## Get the configuration for the wireguard vpn tunnel.
	@make -C terraform \
	  CLOUD=$(CLOUD) \
	  ENVIRONMENT=$(ENVIRONMENT) \
	  vpn-wireguard-config

.PHONY: vpn-sshuttle
vpn-sshuttle: setup ## Establish a sshuttle vpn tunnel.
	@make -C terraform \
	  CLOUD=$(CLOUD) \
	  ENVIRONMENT=$(ENVIRONMENT) \
	  vpn-sshuttle

.PHONY: bootstrap
bootstrap: setup create ## Bootstrap everything.
	${venv} ; ansible-playbook playbooks/deploy.yml \
	  -i ansible/localhost_inventory.yaml \
	  -e ansible_galaxy=ansible-galaxy \
	  -e ansible_playbook=ansible-playbook \
	  -e basepath="$(PWD)" \
	  -e testbed_cloud=$(CLOUD) \
	  -e repo_path="$(PWD)/.src/$(shell . venv/bin/activate && contrib/setup-testbed.py --query "repository_server")" \
	  -e manual_create=true \
	  -e manual_deploy=true \
	  -e ceph_version=$(VERSION_CEPH) \
	  -e manager_version=$(VERSION_MANAGER) \
	  -e openstack_version=$(VERSION_OPENSTACK) \
	  -e ceph_stack=$(CEPH_STACK) \
	  -e deploy_mode=$(DEPLOY_MODE)

.PHONY: manager
manager: setup bootstrap ## Deploy only the manager service.
	make -C terraform \
	  CLOUD=$(CLOUD) \
	  ENVIRONMENT=$(ENVIRONMENT) \
	  TERRAFORM=$(TERRAFORM) \
	  deploy-manager

.PHONY: baremetal
baremetal: DEPLOY_MODE = baremetal
baremetal: setup manager ## Deploy only baremetal services.
	make -C terraform \
	  CLOUD=$(CLOUD) \
	  ENVIRONMENT=$(ENVIRONMENT) \
	  TERRAFORM=$(TERRAFORM) \
	  deploy-baremetal

.PHONY: ceph
ceph: setup manager ## Deploy only ceph services.
	make -C terraform \
	  CLOUD=$(CLOUD) \
	  ENVIRONMENT=$(ENVIRONMENT) \
	  deploy-ceph

.PHONY: deploy
deploy: setup bootstrap ## Deploy everything and then check it.
	make -C terraform \
	  CLOUD=$(CLOUD) \
	  ENVIRONMENT=$(ENVIRONMENT) \
	  TERRAFORM=$(TERRAFORM) \
	  deploy
	make -C terraform \
	  CLOUD=$(CLOUD) \
	  ENVIRONMENT=$(ENVIRONMENT) \
	  TERRAFORM=$(TERRAFORM) \
	  bootstrap
	make -C terraform \
	  CLOUD=$(CLOUD) \
	  ENVIRONMENT=$(ENVIRONMENT) \
	  TERRAFORM=$(TERRAFORM) \
	  check

.PHONY: prepare
prepare: deps ## Run local preperations.
	${venv}; ansible-playbook -i localhost, ansible/check-local-versions.yml
	@${venv}; contrib/setup-testbed.py --prepare

.PHONY: sync
sync: venv/bin/activate
	@${venv} && gilt overlay && gilt overlay

venv/bin/activate: Makefile
	@which python3 > /dev/null || { echo "Missing requirement: python3" >&2; exit 1; }
	@which jq > /dev/null || { echo "Missing requirement: jq" >&2; exit 1; }
	@python3 -m venv venv --prompt testbed || { echo "Unable to create venv" >&2; exit 1; }
	@${venv} && pip3 install -r requirements.txt
	touch venv/bin/activate

venv/bin/tofu: venv/bin/activate
	$(eval OS := $(shell uname | tr '[:upper:]' '[:lower:]'))
	$(eval ARCH := $(shell uname -m | sed -e 's/aarch64/arm64/' -e 's/x86_64/amd64/'))
	@echo Downloading opentofu version ${TOFU_VERSION}
	curl -s -L --output venv/bin/tofu.zip \
		"https://github.com/opentofu/opentofu/releases/download/v${TOFU_VERSION}/tofu_${TOFU_VERSION}_${OS}_${ARCH}.zip"
	rm -f venv/bin/tofu
	unzip -d venv/bin/ venv/bin/tofu.zip tofu
	chmod +x venv/bin/tofu
	rm -f venv/bin/tofu.zip
	tofu version
	touch venv/bin/tofu

.PHONY: deps
deps: venv/bin/tofu venv/bin/activate ## Install software preconditions to `venv`.
