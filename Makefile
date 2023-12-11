export LC_ALL = C.UTF-8

ENVIRONMENT ?= the_environment

VERSION_CEPH ?= quincy
VERSION_MANAGER ?= latest
VERSION_OPENSTACK ?= 2023.1

TERRAFORM ?= terraform
TERRAFORM_BLUEPRINT ?= testbed-default

venv = . venv/bin/activate
export PATH := ${PATH}:${PWD}/venv/bin

help:  ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

clean: ## Destroy infrastructure with Terraform.
	@contrib/setup-testbed.py --environment_check $(ENVIRONMENT)
	make -C terraform \
	  ENVIRONMENT=$(ENVIRONMENT) \
	  TERRAFORM=$(TERRAFORM) \
	  clean

clean_local:
	rm -rf venv .src

create: prepare ## Create required infrastructure with Terraform.
	@contrib/setup-testbed.py --environment_check $(ENVIRONMENT)
	make -C terraform \
	  ENVIRONMENT=$(ENVIRONMENT) \
	  TERRAFORM=$(TERRAFORM) \
	  VERSION_CEPH=$(VERSION_CEPH) \
	  VERSION_MANAGER=$(VERSION_MANAGER) \
	  VERSION_OPENSTACK=$(VERSION_OPENSTACK) \
	  create

login: ## Log in on the manager.
	@contrib/setup-testbed.py --environment_check $(ENVIRONMENT)
	@make -C terraform \
	  ENVIRONMENT=$(ENVIRONMENT) \
	  login

bootstrap: create ## Bootstrap everything.
	@contrib/setup-testbed.py --environment_check $(ENVIRONMENT)
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

manager: bootstrap ## Deploy only the manager service.
	@contrib/setup-testbed.py --environment_check $(ENVIRONMENT)
	make -C terraform \
	  ENVIRONMENT=$(ENVIRONMENT) \
	  TERRAFORM=$(TERRAFORM) \
	  deploy-manager

identity: manager ## Deploy only identity services.
	@contrib/setup-testbed.py --environment_check $(ENVIRONMENT)
	make -C terraform \
	  ENVIRONMENT=$(ENVIRONMENT) \
	  TERRAFORM=$(TERRAFORM) \
	  deploy-identity

ceph: manager ## Deploy only ceph services.
	@contrib/setup-testbed.py --environment_check $(ENVIRONMENT)
	make -C terraform \
	  ENVIRONMENT=$(ENVIRONMENT) \
	  deploy-ceph

deploy: bootstrap ## Deploy everything and then check it.
	@contrib/setup-testbed.py --environment_check $(ENVIRONMENT)
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

prepare: deps
	${venv}; ansible-playbook -i localhost, ansible/check-local-versions.yml
	@contrib/setup-testbed.py --prepare

venv/bin/activate: Makefile
	@which python3 > /dev/null || { echo "Missing requirement: python3" >&2; exit 1; }
	@which jq > /dev/null || { echo "Missing requirement: jq" >&2; exit 1; }
	virtualenv --version > /dev/null || { echo "Missing requirement: virtualenv -- aborting" >&2; exit 1; }
	[ -e venv/bin/python ] || virtualenv -p $$(which python3) venv > /dev/null
	@${venv} && pip3 install -r requirements.txt
	touch venv/bin/activate


deps: venv/bin/activate

phony: bootstrap clean clean_local create deploy identity login manager prepare ceph deps venv/bin/activate
