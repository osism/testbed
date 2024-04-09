export LC_ALL = C.UTF-8

ENVIRONMENT ?= the_environment

VERSION_CEPH ?= quincy
VERSION_MANAGER ?= latest
VERSION_OPENSTACK ?= 2023.2
# renovate: datasource=github-releases depName=opentofu/opentofu
TOFU_VERSION ?= 1.6.1

TERRAFORM ?= tofu
TERRAFORM_BLUEPRINT ?= testbed-default

venv = . venv/bin/activate
export PATH := ${PATH}:${PWD}/venv/bin

help:  ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

setup: ## Prepare the repository.
	@contrib/setup-testbed.py --environment_check $(ENVIRONMENT)

clean: setup ## Destroy infrastructure with OpenTofu.
	make -C terraform \
	  ENVIRONMENT=$(ENVIRONMENT) \
	  TERRAFORM=$(TERRAFORM) \
	  clean

wipe-local-install: ## Wipe the software dependencies in `venv`.
	rm -rf venv .src

create: prepare ## Create required infrastructure with OpenTofu.
	@contrib/setup-testbed.py --environment_check $(ENVIRONMENT)
	make -C terraform \
	  ENVIRONMENT=$(ENVIRONMENT) \
	  TERRAFORM=$(TERRAFORM) \
	  VERSION_CEPH=$(VERSION_CEPH) \
	  VERSION_MANAGER=$(VERSION_MANAGER) \
	  VERSION_OPENSTACK=$(VERSION_OPENSTACK) \
	  create

login: setup ## Log in on the manager.
	@make -C terraform \
	  ENVIRONMENT=$(ENVIRONMENT) \
	  login

vpn-wireguard: setup ## Establish a wireguard vpn tunnel.
	@make -C terraform \
	  ENVIRONMENT=$(ENVIRONMENT) \
	  vpn-wireguard

vpn-wireguard-config: setup ## Get the configuration for the wireguard vpn tunnel.
	@make -C terraform \
	  ENVIRONMENT=$(ENVIRONMENT) \
	  vpn-wireguard-config

vpn-sshuttle: setup ## Establish a sshuttle vpn tunnel.
	@make -C terraform \
	  ENVIRONMENT=$(ENVIRONMENT) \
	  vpn-sshuttle

bootstrap: setup create ## Bootstrap everything.
	${venv} ; ansible-playbook playbooks/deploy.yml \
	  -i ansible/localhost_inventory.yaml \
	  -e ansible_galaxy=ansible-galaxy \
	  -e ansible_playbook=ansible-playbook \
	  -e basepath="$(PWD)" \
	  -e cloud_env=$(ENVIRONMENT) \
	  -e repo_path="$(PWD)/.src/$(shell contrib/setup-testbed.py --query "repository_server")" \
	  -e manual_create=true \
	  -e manual_deploy=true \
	  -e version_ceph=$(VERSION_CEPH) \
	  -e version_manager=$(VERSION_MANAGER) \
	  -e version_openstack=$(VERSION_OPENSTACK)

manager: setup bootstrap ## Deploy only the manager service.
	make -C terraform \
	  ENVIRONMENT=$(ENVIRONMENT) \
	  TERRAFORM=$(TERRAFORM) \
	  deploy-manager

identity: setup manager ## Deploy only identity services.
	make -C terraform \
	  ENVIRONMENT=$(ENVIRONMENT) \
	  TERRAFORM=$(TERRAFORM) \
	  deploy-identity

ceph: setup manager ## Deploy only ceph services.
	make -C terraform \
	  ENVIRONMENT=$(ENVIRONMENT) \
	  deploy-ceph

deploy: setup bootstrap ## Deploy everything and then check it.
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

prepare: deps ## Run local preperations.
	${venv}; ansible-playbook -i localhost, ansible/check-local-versions.yml
	@contrib/setup-testbed.py --prepare

venv/bin/activate: Makefile
	@which python3 > /dev/null || { echo "Missing requirement: python3" >&2; exit 1; }
	@which jq > /dev/null || { echo "Missing requirement: jq" >&2; exit 1; }
	virtualenv --version > /dev/null || { echo "Missing requirement: virtualenv -- aborting" >&2; exit 1; }
	[ -e venv/bin/python ] || virtualenv -p $$(which python3) venv > /dev/null
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

deps: venv/bin/tofu venv/bin/activate ## Install software preconditions to `venv`.

phony: bootstrap clean clean-local create deploy identity login manager prepare ceph deps venv/bin/activate venv/bin/tofu vpn-sshuttle vpn-wireguard vpn-wireguard-config wipe-local-install
