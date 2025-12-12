export LC_ALL = C.UTF-8

CONFIGURATION = main
CONSOLE = manager
ENVIRONMENT ?= regiocloud
CLOUD ?= $(ENVIRONMENT)
USERNAME = dragon
IMAGE_USERNAME = ubuntu

OPENSTACK = openstack
TERRAFORM ?= tofu
export TF_CLI_ARGS ?= -no-color

PARALLELISM = 10
RESOURCE = openstack_networking_floatingip_v2.manager_floating_ip
STATE = errored.tfstate

CEPH_STACK ?= ceph-ansible
DEPLOY_MODE ?= manager
KOLLA_NAMESPACE ?= kolla
TEMPEST ?= false

VERSION_CEPH ?= reef
VERSION_MANAGER ?= latest
VERSION_OPENSTACK ?= 2024.2

APPLY_PARAMS = -auto-approve -parallelism=$(PARALLELISM)

export PATH := ${PATH}:${PWD}/../venv/bin

ifneq (,$(wildcard ./local.env))
  include local.env
endif

export OS_CLOUD ?= $(CLOUD)

export TF_VAR_cloud_provider=$(CLOUD)
ifneq (,$(wildcard terraformrc))
  export TF_CLI_CONFIG_FILE ?= terraformrc
endif

ifneq (,$(wildcard ./backend.env))
  include backend.env
endif

ifeq ($(shell uname -s), Linux)
  OPEN_CMD := xdg-open
else
  OPEN_CMD := open
endif

.PHONY: reset
reset:
	@rm -rf .terraform/providers

.PHONY: init
init:
	@if [ ! -d .terraform/providers ]; then $(TERRAFORM) init -upgrade; fi

	@if [ ! -f backend.tf ]; then \
		$(TERRAFORM) workspace select -or-create ${CLOUD}; \
	fi

	@rm -f *.auto.tfvars
	@cp environments/$(ENVIRONMENT).tfvars $(CLOUD).auto.tfvars
	@echo "ceph_stack = \"$(CEPH_STACK)\"" >> $(CLOUD).auto.tfvars
	@echo "cloud_provider = \"$(OS_CLOUD)\"" >> $(CLOUD).auto.tfvars
	@echo "deploy_mode= \"$(DEPLOY_MODE)\"" >> $(CLOUD).auto.tfvars
	@echo "image_node_user = \"$(IMAGE_USERNAME)\"" >> $(CLOUD).auto.tfvars
	@echo "image_user = \"$(IMAGE_USERNAME)\"" >> $(CLOUD).auto.tfvars
	@echo "manager_version = \"$(VERSION_MANAGER)\"" >> $(CLOUD).auto.tfvars
	@echo "tempest = \"$(TEMPEST)\"" >> $(CLOUD).auto.tfvars
	@if [ "$(VERSION_MANAGER)" != "latest" ] && \
	   [ "$$(../contrib/semver2.sh $(VERSION_MANAGER) 10.0.0-0)" -ge 0 ]; then \
	    BASE_URL="https://raw.githubusercontent.com/osism/release/main/$(VERSION_MANAGER)/base.yml"; \
	    BASE_CONTENT=$$(curl -sf "$$BASE_URL") || { echo "ERROR: Failed to fetch $$BASE_URL - release $(VERSION_MANAGER) may not exist on osism/release"; exit 1; }; \
	    RELEASE_CEPH=$$(echo "$$BASE_CONTENT" | grep "^ceph_version:" | sed 's/ceph_version:[[:space:]]*//;s/"//g'); \
	    RELEASE_OS=$$(echo "$$BASE_CONTENT" | grep "^openstack_version:" | sed 's/openstack_version:[[:space:]]*//;s/"//g'); \
	    echo "ceph_version = \"$$RELEASE_CEPH\"" >> $(CLOUD).auto.tfvars; \
	    echo "openstack_version = \"$$RELEASE_OS\"" >> $(CLOUD).auto.tfvars; \
	else \
	    echo "ceph_version = \"$(VERSION_CEPH)\"" >> $(CLOUD).auto.tfvars; \
	    echo "openstack_version = \"$(VERSION_OPENSTACK)\"" >> $(CLOUD).auto.tfvars; \
	fi

	@rm -f *_custom.tf
	@for custom in `grep '^# *customisation:' "environments/${ENVIRONMENT}.tfvars" | sed 's/^# *customisation://'`; do \
		cp -p customisations/$${custom}_custom.tf .; \
	done

	@rm -f *_override.tf
	@for over in `grep '^# *override:' "environments/${ENVIRONMENT}.tfvars" | sed 's/^# *override://'`; do \
		cp -p overrides/$${over}_override.tf .; \
	done

	@$(TERRAFORM) fmt

.PHONY: validate
validate: init
	@$(TERRAFORM) validate $(PARAMS)

.PHONY: attach
attach: init
	@$(TERRAFORM) import $(RESOURCE) $(PARAMS)

.PHONY: detach
detach: init
	@$(TERRAFORM) state rm $(RESOURCE) $(PARAMS)

.PHONY: state-push
state-push: init
	@$(TERRAFORM) state push $(STATE)

.PHONY: dry-run
dry-run: init
	@$(TERRAFORM) plan $(PARAMS)

.PHONY: create
create: init
	@touch .deploy.$(CLOUD)
	@echo "configuration_version = \"$(CONFIGURATION)\"" >> $(CLOUD).auto.tfvars
	@$(TERRAFORM) apply $(APPLY_PARAMS) $(PARAMS)

.PHONY: deploy
deploy: .MANAGER_ADDRESS.$(CLOUD) .id_rsa.$(CLOUD)
	@. ./.MANAGER_ADDRESS.$(CLOUD); \
	ssh -o StrictHostKeyChecking=no -i .id_rsa.$(CLOUD) $(USERNAME)@$$MANAGER_ADDRESS "/opt/configuration/scripts/deploy.sh"

.PHONY: deploy-ceph
deploy-ceph: .MANAGER_ADDRESS.$(CLOUD) .id_rsa.$(CLOUD)
	@. ./.MANAGER_ADDRESS.$(CLOUD); \
	ssh -o StrictHostKeyChecking=no -i .id_rsa.$(CLOUD) $(USERNAME)@$$MANAGER_ADDRESS "/opt/configuration/scripts/deploy-ceph.sh"

.PHONY: deploy-manager
deploy-manager: .MANAGER_ADDRESS.$(CLOUD) .id_rsa.$(CLOUD)
	@. ./.MANAGER_ADDRESS.$(CLOUD); \
	ssh -o StrictHostKeyChecking=no -i .id_rsa.$(CLOUD) $(USERNAME)@$$MANAGER_ADDRESS "/opt/configuration/scripts/deploy-manager.sh"

.PHONY: deploy-baremetal
deploy-baremetal: .MANAGER_ADDRESS.$(CLOUD) .id_rsa.$(CLOUD)
	@. ./.MANAGER_ADDRESS.$(CLOUD); \
	ssh -o StrictHostKeyChecking=no -i .id_rsa.$(CLOUD) $(USERNAME)@$$MANAGER_ADDRESS "/opt/configuration/scripts/deploy-baremetal.sh"

.PHONY: upgrade
upgrade: .MANAGER_ADDRESS.$(CLOUD) .id_rsa.$(CLOUD)
	@. ./.MANAGER_ADDRESS.$(CLOUD); \
	ssh -o StrictHostKeyChecking=no -i .id_rsa.$(CLOUD) $(USERNAME)@$$MANAGER_ADDRESS "/opt/configuration/scripts/upgrade.sh $(VERSION_MANAGER) $(VERSION_CEPH) $(VERSION_OPENSTACK) $(KOLLA_NAMESPACE)"

.PHONY: upgrade-ceph
upgrade-ceph: .MANAGER_ADDRESS.$(CLOUD) .id_rsa.$(CLOUD)
	@. ./.MANAGER_ADDRESS.$(CLOUD); \
	ssh -o StrictHostKeyChecking=no -i .id_rsa.$(CLOUD) $(USERNAME)@$$MANAGER_ADDRESS "/opt/configuration/scripts/upgrade-ceph.sh $(VERSION_MANAGER) $(VERSION_CEPH)"

.PHONY: check
check: .MANAGER_ADDRESS.$(CLOUD) .id_rsa.$(CLOUD)
	@. ./.MANAGER_ADDRESS.$(CLOUD); \
	ssh -o StrictHostKeyChecking=no -i .id_rsa.$(CLOUD) $(USERNAME)@$$MANAGER_ADDRESS /opt/configuration/scripts/check.sh

.PHONY: tempest
tempest: .MANAGER_ADDRESS.$(CLOUD) .id_rsa.$(CLOUD)
	@. ./.MANAGER_ADDRESS.$(CLOUD); \
	ssh -o StrictHostKeyChecking=no -i .id_rsa.$(CLOUD) $(USERNAME)@$$MANAGER_ADDRESS /opt/configuration/scripts/check/302-openstack-with-tempest.sh

.PHONY: bootstrap
bootstrap: .MANAGER_ADDRESS.$(CLOUD) .id_rsa.$(CLOUD)
	@. ./.MANAGER_ADDRESS.$(CLOUD); \
	ssh -o StrictHostKeyChecking=no -i .id_rsa.$(CLOUD) $(USERNAME)@$$MANAGER_ADDRESS /opt/configuration/scripts/bootstrap.sh

.PHONY: graph
graph: init
	@$(TERRAFORM) graph

.PHONY: show
show: init
	@$(TERRAFORM) show

.PHONY: clean
clean: init
	@$(TERRAFORM) destroy $(APPLY_PARAMS) $(PARAMS)
	@rm -f .deploy.$(CLOUD) .MANAGER_ADDRESS.$(CLOUD)
	@rm -f .id_rsa.$(CLOUD)

	@if [ ! -f backend.tf ]; then \
		$(TERRAFORM) workspace select default; \
		$(TERRAFORM) workspace delete $(CLOUD) || true; \
	fi
	@rm -f wg-*.conf
	@rm -rf .terraform .terraform.lock.hcl

.PHONY: list
list: init
	@$(TERRAFORM) state list

.PHONY: ssh
ssh: .MANAGER_ADDRESS.$(CLOUD) .id_rsa.$(CLOUD)
	@. ./.MANAGER_ADDRESS.$(CLOUD); \
	ssh -o StrictHostKeyChecking=no -i .id_rsa.$(CLOUD) $(USERNAME)@$$MANAGER_ADDRESS

.PHONY: vpn-wireguard-config
vpn-wireguard-config: .MANAGER_ADDRESS.$(CLOUD) .id_rsa.$(CLOUD)
	@. ./.MANAGER_ADDRESS.$(CLOUD); \
	scp -o StrictHostKeyChecking=no -i .id_rsa.$(CLOUD) $(PARAMS) $(USERNAME)@$$MANAGER_ADDRESS:/home/dragon/wireguard-client.conf $(PWD)/wg-$(CLOUD).conf
	@echo Wireguard configuration saved in $(PWD)/wg-$(CLOUD).conf

.PHONY: vpn-wireguard
vpn-wireguard: .MANAGER_ADDRESS.$(CLOUD) .id_rsa.$(CLOUD) vpn-wireguard-config
	sudo wg-quick down $(PWD)/wg-$(CLOUD).conf || true
	sudo wg-quick up $(PWD)/wg-$(CLOUD).conf
	@$(OPEN_CMD) "https://osism.tech/docs/guides/other-guides/testbed#webinterfaces"
	@read -p "STOP?" CONT
	sudo wg-quick down $(PWD)/wg-$(CLOUD).conf

.PHONY: scp
scp: .MANAGER_ADDRESS.$(CLOUD) .id_rsa.$(CLOUD)
	@. ./.MANAGER_ADDRESS.$(CLOUD); \
	scp -o StrictHostKeyChecking=no -i .id_rsa.$(CLOUD) $(PARAMS) $(USERNAME)@$$MANAGER_ADDRESS:$(SOURCE) .

.PHONY: vpn-sshuttle
vpn-sshuttle: .MANAGER_ADDRESS.$(CLOUD) .id_rsa.$(CLOUD)
	@. ./.MANAGER_ADDRESS.$(CLOUD); \
	sshuttle --ssh-cmd "ssh -o StrictHostKeyChecking=no -i .id_rsa.$(CLOUD) " -r $(USERNAME)@$$MANAGER_ADDRESS 192.168.16.0/20 192.168.112.0/20

.PHONY: address
address: .MANAGER_ADDRESS.$(CLOUD) .id_rsa.$(CLOUD)
	@. ./.MANAGER_ADDRESS.$(CLOUD); \
	echo $$MANAGER_ADDRESS

.PHONY: console
console: .deploy.$(CLOUD)
	@$(OPENSTACK) console url show testbed-$(CONSOLE)

.PHONY: log
log: .deploy.$(CLOUD)
	@$(OPENSTACK) console log show testbed-$(CONSOLE)

.deploy.$(CLOUD): init
	@STAT=$$($(TERRAFORM) state list); \
	if test -n "$$STAT"; then touch .deploy.$(CLOUD); else echo "use make deploy or deploy-identity or deploy-baremetal"; exit 1; fi

.MANAGER_ADDRESS.$(CLOUD): .deploy.$(CLOUD)
	@MANAGER_ADDRESS=$$($(TERRAFORM) output manager_address); \
	echo "MANAGER_ADDRESS=$$MANAGER_ADDRESS" > $@;

.id_rsa.$(CLOUD): .deploy.$(CLOUD)
	@PRIVATE_KEY=$$($(TERRAFORM) output private_key); \
	echo "$$PRIVATE_KEY" > $@; \
        chmod 0600 $@

.PHONY: watch
watch: .id_rsa.$(CLOUD) .MANAGER_ADDRESS.$(CLOUD)
	@. ./.MANAGER_ADDRESS.$(CLOUD); \
	DISP=0; \
	if test "$$COLORTERM" = "1"; then \
	  GREEN=$$(echo -e "\e[0;32m"); GREENBOLD=$$(echo -e "\e[1;32m"); BOLD=$$(echo -e "\e[0;1m"); RED=$$(echo -e "\e[0;31m"); YELLOW=$$(echo -e "\e[0;33m"); NORM=$$(echo -e "\e[0;0m"); \
	fi; \
	while true; do \
		LEN=$$(ssh -o StrictHostKeyChecking=no -i .id_rsa.$(CLOUD) $(IMAGE_USERNAME)@$$MANAGER_ADDRESS sudo wc -l /var/log/cloud-init-output.log 2>/dev/null); \
		LEN=$${LEN%% *}; \
		if test -n "$$LEN" -a "$$LEN" != "$$DISP"; then \
		  OUT=$$(ssh -o StrictHostKeyChecking=no -i .id_rsa.$(CLOUD) $(IMAGE_USERNAME)@$$MANAGER_ADDRESS sudo tail -n $$((LEN-DISP)) /var/log/cloud-init-output.log 2>/dev/null); \
		  echo "$$OUT" | sed -e "s/^\(TASK.*\)$$/$$BOLD\1$$NORM/" -e "s/^\(PLAY.*\)$$/$$GREEN\1$$NORM/" -e "s/^\(The system is finally up.*\)$$/$$GREENBOLD\1$$NORM/" -e "s/\(FAILED\)/$$RED\1$$NORM/g" -e "s/\(failed=[1-9][0-9]*\|unreachable=[1-9][0-9]*\)/$$RED\1$$NORM/g" -e "s/\(warn\|WARN\|RETRYING\)/$$YELLOW\1$$NORM/" -e "s/\(ok:\|ok=[0-9]*\)/$$GREEN\1$$NORM/"; \
		  if echo "$$OUT" | grep '^The system is finally up' >/dev/null 2>&1; then break; fi; \
		  DISP=$$LEN; \
		  sleep 5; \
		fi; \
	done;
	#@$(OPENSTACK) server list

.PHONY: ping
ping: .MANAGER_ADDRESS.$(CLOUD)
	@. ./.MANAGER_ADDRESS.$(CLOUD); \
	ping -c3 $$MANAGER_ADDRESS

.PHONY: openstack
openstack: init
	@$(OPENSTACK)

.PHONY: endpoints
endpoints: init
	@. ./.MANAGER_ADDRESS.$(CLOUD); \
	echo "| ARA        | http://$$MANAGER_ADDRESS:8120  |"; \
	echo "| phpMyAdmin | http://$$MANAGER_ADDRESS:8110  |";

.PHONY: coy
copy: scp

.PHONY: login
login: ssh

.PHONY: plan
plan: dry-run

.PHONY: push
push: state-push

.PHONY: tunnel
tunnel: sshuttle
