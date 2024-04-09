export LC_ALL = C.UTF-8

CONFIGURATION = main
CONSOLE = manager
ENVIRONMENT ?= regiocloud
USERNAME = dragon

OPENSTACK = openstack
TERRAFORM ?= tofu
export TF_CLI_ARGS ?= -no-color

PARALLELISM = 10
RESOURCE = openstack_networking_floatingip_v2.manager_floating_ip
STATE = errored.tfstate

VERSION_CEPH ?= quincy
VERSION_MANAGER ?= latest
VERSION_OPENSTACK ?= 2023.2

KOLLA_NAMESPACE ?= osism

RALLY ?= false
REFSTACK ?= false
IS_ZUUL ?= false

APPLY_PARAMS = -auto-approve -parallelism=$(PARALLELISM)

export PATH := ${PATH}:${PWD}/../venv/bin

ifneq (,$(wildcard ./local.env))
  include local.env
endif

export OS_CLOUD ?= $(ENVIRONMENT)

export TF_VAR_cloud_provider=$(ENVIRONMENT)
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

reset:
	@rm -rf .terraform/providers

init:
	@if [ ! -d .terraform/providers ]; then $(TERRAFORM) init -upgrade; fi

	@if [ ! -f backend.tf ]; then \
		$(TERRAFORM) workspace select -or-create ${ENVIRONMENT}; \
	fi


	@rm -f *.auto.tfvars
	@cp environments/$(ENVIRONMENT).tfvars $(ENVIRONMENT).auto.tfvars
	@echo "cloud_provider = \"$(OS_CLOUD)\"" >> $(ENVIRONMENT).auto.tfvars
	@echo "ceph_version = \"$(VERSION_CEPH)\"" >> $(ENVIRONMENT).auto.tfvars
	@echo "manager_version = \"$(VERSION_MANAGER)\"" >> $(ENVIRONMENT).auto.tfvars
	@echo "openstack_version = \"$(VERSION_OPENSTACK)\"" >> $(ENVIRONMENT).auto.tfvars
	@echo "refstack = \"$(REFSTACK)\"" >> $(ENVIRONMENT).auto.tfvars
	@echo "is_zuul = \"$(IS_ZUUL)\"" >> $(ENVIRONMENT).auto.tfvars

	@rm -f *_custom.tf
	@for custom in `grep '^# *customisation:' "environments/${ENVIRONMENT}.tfvars" | sed 's/^# *customisation://'`; do \
		cp -p customisations/$${custom}_custom.tf .; \
	done

	@rm -f *_override.tf
	@for over in `grep '^# *override:' "environments/${ENVIRONMENT}.tfvars" | sed 's/^# *override://'`; do \
		cp -p overrides/$${over}_override.tf .; \
	done

	@$(TERRAFORM) fmt

validate: init
	@$(TERRAFORM) validate $(PARAMS)

attach: init
	@$(TERRAFORM) import $(RESOURCE) $(PARAMS)

detach: init
	@$(TERRAFORM) state rm $(RESOURCE) $(PARAMS)

state-push: init
	@$(TERRAFORM) state push $(STATE)

dry-run: init
	@$(TERRAFORM) plan $(PARAMS)

create: init
	@touch .deploy.$(ENVIRONMENT)
	@echo "configuration_version = \"$(CONFIGURATION)\"" >> $(ENVIRONMENT).auto.tfvars
	@$(TERRAFORM) apply $(APPLY_PARAMS) $(PARAMS)

deploy: .MANAGER_ADDRESS.$(ENVIRONMENT) .id_rsa.$(ENVIRONMENT)
	@. ./.MANAGER_ADDRESS.$(ENVIRONMENT); \
	ssh -o StrictHostKeyChecking=no -i .id_rsa.$(ENVIRONMENT) $(USERNAME)@$$MANAGER_ADDRESS "/opt/configuration/scripts/deploy.sh"

deploy-ceph: .MANAGER_ADDRESS.$(ENVIRONMENT) .id_rsa.$(ENVIRONMENT)
	@. ./.MANAGER_ADDRESS.$(ENVIRONMENT); \
	ssh -o StrictHostKeyChecking=no -i .id_rsa.$(ENVIRONMENT) $(USERNAME)@$$MANAGER_ADDRESS "/opt/configuration/scripts/deploy-ceph-services.sh"

deploy-manager: .MANAGER_ADDRESS.$(ENVIRONMENT) .id_rsa.$(ENVIRONMENT)
	@. ./.MANAGER_ADDRESS.$(ENVIRONMENT); \
	ssh -o StrictHostKeyChecking=no -i .id_rsa.$(ENVIRONMENT) $(USERNAME)@$$MANAGER_ADDRESS "/opt/configuration/scripts/deploy-manager.sh"

deploy-identity: .MANAGER_ADDRESS.$(ENVIRONMENT) .id_rsa.$(ENVIRONMENT)
	@. ./.MANAGER_ADDRESS.$(ENVIRONMENT); \
	ssh -o StrictHostKeyChecking=no -i .id_rsa.$(ENVIRONMENT) $(USERNAME)@$$MANAGER_ADDRESS "/opt/configuration/scripts/deploy-identity-services.sh"

upgrade: .MANAGER_ADDRESS.$(ENVIRONMENT) .id_rsa.$(ENVIRONMENT)
	@. ./.MANAGER_ADDRESS.$(ENVIRONMENT); \
	ssh -o StrictHostKeyChecking=no -i .id_rsa.$(ENVIRONMENT) $(USERNAME)@$$MANAGER_ADDRESS "/opt/configuration/scripts/upgrade.sh $(VERSION_MANAGER) $(VERSION_CEPH) $(VERSION_OPENSTACK) $(KOLLA_NAMESPACE)"

upgrade-ceph: .MANAGER_ADDRESS.$(ENVIRONMENT) .id_rsa.$(ENVIRONMENT)
	@. ./.MANAGER_ADDRESS.$(ENVIRONMENT); \
	ssh -o StrictHostKeyChecking=no -i .id_rsa.$(ENVIRONMENT) $(USERNAME)@$$MANAGER_ADDRESS "/opt/configuration/scripts/upgrade-ceph-services.sh $(VERSION_MANAGER) $(VERSION_CEPH)"

check: .MANAGER_ADDRESS.$(ENVIRONMENT) .id_rsa.$(ENVIRONMENT)
	@. ./.MANAGER_ADDRESS.$(ENVIRONMENT); \
	ssh -o StrictHostKeyChecking=no -i .id_rsa.$(ENVIRONMENT) $(USERNAME)@$$MANAGER_ADDRESS /opt/configuration/scripts/check.sh

rally: .MANAGER_ADDRESS.$(ENVIRONMENT) .id_rsa.$(ENVIRONMENT)
	@. ./.MANAGER_ADDRESS.$(ENVIRONMENT); \
	ssh -o StrictHostKeyChecking=no -i .id_rsa.$(ENVIRONMENT) $(USERNAME)@$$MANAGER_ADDRESS /opt/configuration/contrib/rally/rally.sh

refstack: .MANAGER_ADDRESS.$(ENVIRONMENT) .id_rsa.$(ENVIRONMENT)
	@. ./.MANAGER_ADDRESS.$(ENVIRONMENT); \
	ssh -o StrictHostKeyChecking=no -i .id_rsa.$(ENVIRONMENT) $(USERNAME)@$$MANAGER_ADDRESS /opt/configuration/scripts/check/301-openstack-refstack.sh

bootstrap: .MANAGER_ADDRESS.$(ENVIRONMENT) .id_rsa.$(ENVIRONMENT)
	@. ./.MANAGER_ADDRESS.$(ENVIRONMENT); \
	ssh -o StrictHostKeyChecking=no -i .id_rsa.$(ENVIRONMENT) $(USERNAME)@$$MANAGER_ADDRESS /opt/configuration/scripts/bootstrap.sh

graph: init
	@$(TERRAFORM) graph

show: init
	@$(TERRAFORM) show

clean: init
	@$(TERRAFORM) destroy $(APPLY_PARAMS) $(PARAMS)
	@rm -f .deploy.$(ENVIRONMENT) .MANAGER_ADDRESS.$(ENVIRONMENT)
	@rm -f .id_rsa.$(ENVIRONMENT)

	@if [ ! -f backend.tf ]; then \
		$(TERRAFORM) workspace select default; \
		$(TERRAFORM) workspace delete $(ENVIRONMENT) || true; \
	fi
	@rm -f wg-*.conf
	@rm -rf .terraform .terraform.lock.hcl

list: init
	@$(TERRAFORM) state list

ssh: .MANAGER_ADDRESS.$(ENVIRONMENT) .id_rsa.$(ENVIRONMENT)
	@. ./.MANAGER_ADDRESS.$(ENVIRONMENT); \
	ssh -o StrictHostKeyChecking=no -i .id_rsa.$(ENVIRONMENT) $(USERNAME)@$$MANAGER_ADDRESS

vpn-wireguard-config: .MANAGER_ADDRESS.$(ENVIRONMENT) .id_rsa.$(ENVIRONMENT)
	@. ./.MANAGER_ADDRESS.$(ENVIRONMENT); \
	scp -o StrictHostKeyChecking=no -i .id_rsa.$(ENVIRONMENT) $(PARAMS) $(USERNAME)@$$MANAGER_ADDRESS:/home/dragon/wireguard-client.conf $(PWD)/wg-$(ENVIRONMENT).conf
	@echo Wireguard configuration saved in $(PWD)/wg-$(ENVIRONMENT).conf

vpn-wireguard: .MANAGER_ADDRESS.$(ENVIRONMENT) .id_rsa.$(ENVIRONMENT) vpn-wireguard-config
	sudo wg-quick down $(PWD)/wg-$(ENVIRONMENT).conf || true
	sudo wg-quick up $(PWD)/wg-$(ENVIRONMENT).conf
	@$(OPEN_CMD) "https://osism.tech/docs/guides/other-guides/testbed#webinterfaces"
	@read -p "STOP?" CONT
	sudo wg-quick down $(PWD)/wg-$(ENVIRONMENT).conf

scp: .MANAGER_ADDRESS.$(ENVIRONMENT) .id_rsa.$(ENVIRONMENT)
	@. ./.MANAGER_ADDRESS.$(ENVIRONMENT); \
	scp -o StrictHostKeyChecking=no -i .id_rsa.$(ENVIRONMENT) $(PARAMS) $(USERNAME)@$$MANAGER_ADDRESS:$(SOURCE) .

vpn-sshuttle: .MANAGER_ADDRESS.$(ENVIRONMENT) .id_rsa.$(ENVIRONMENT)
	@. ./.MANAGER_ADDRESS.$(ENVIRONMENT); \
	sshuttle --ssh-cmd "ssh -o StrictHostKeyChecking=no -i .id_rsa.$(ENVIRONMENT) " -r $(USERNAME)@$$MANAGER_ADDRESS 192.168.16.0/20 192.168.112.0/20

address: .MANAGER_ADDRESS.$(ENVIRONMENT) .id_rsa.$(ENVIRONMENT)
	@. ./.MANAGER_ADDRESS.$(ENVIRONMENT); \
	echo $$MANAGER_ADDRESS

console: .deploy.$(ENVIRONMENT)
	@$(OPENSTACK) console url show testbed-$(CONSOLE)

log: .deploy.$(ENVIRONMENT)
	@$(OPENSTACK) console log show testbed-$(CONSOLE)

.deploy.$(ENVIRONMENT): init
	@STAT=$$($(TERRAFORM) state list); \
	if test -n "$$STAT"; then touch .deploy.$(ENVIRONMENT); else echo "use make deploy or deploy-identity"; exit 1; fi

.MANAGER_ADDRESS.$(ENVIRONMENT): .deploy.$(ENVIRONMENT)
	@MANAGER_ADDRESS=$$($(TERRAFORM) output manager_address); \
	echo "MANAGER_ADDRESS=$$MANAGER_ADDRESS" > $@;

.id_rsa.$(ENVIRONMENT): .deploy.$(ENVIRONMENT)
	@PRIVATE_KEY=$$($(TERRAFORM) output private_key); \
	echo "$$PRIVATE_KEY" > $@; \
        chmod 0600 $@

watch: .id_rsa.$(ENVIRONMENT) .MANAGER_ADDRESS.$(ENVIRONMENT)
	@. ./.MANAGER_ADDRESS.$(ENVIRONMENT); \
	DISP=0; \
	if test "$$COLORTERM" = "1"; then \
	  GREEN=$$(echo -e "\e[0;32m"); GREENBOLD=$$(echo -e "\e[1;32m"); BOLD=$$(echo -e "\e[0;1m"); RED=$$(echo -e "\e[0;31m"); YELLOW=$$(echo -e "\e[0;33m"); NORM=$$(echo -e "\e[0;0m"); \
	fi; \
	while true; do \
		LEN=$$(ssh -o StrictHostKeyChecking=no -i .id_rsa.$(ENVIRONMENT) ubuntu@$$MANAGER_ADDRESS sudo wc -l /var/log/cloud-init-output.log 2>/dev/null); \
		LEN=$${LEN%% *}; \
		if test -n "$$LEN" -a "$$LEN" != "$$DISP"; then \
		  OUT=$$(ssh -o StrictHostKeyChecking=no -i .id_rsa.$(ENVIRONMENT) ubuntu@$$MANAGER_ADDRESS sudo tail -n $$((LEN-DISP)) /var/log/cloud-init-output.log 2>/dev/null); \
		  echo "$$OUT" | sed -e "s/^\(TASK.*\)$$/$$BOLD\1$$NORM/" -e "s/^\(PLAY.*\)$$/$$GREEN\1$$NORM/" -e "s/^\(The system is finally up.*\)$$/$$GREENBOLD\1$$NORM/" -e "s/\(FAILED\)/$$RED\1$$NORM/g" -e "s/\(failed=[1-9][0-9]*\|unreachable=[1-9][0-9]*\)/$$RED\1$$NORM/g" -e "s/\(warn\|WARN\|RETRYING\)/$$YELLOW\1$$NORM/" -e "s/\(ok:\|ok=[0-9]*\)/$$GREEN\1$$NORM/"; \
		  if echo "$$OUT" | grep '^The system is finally up' >/dev/null 2>&1; then break; fi; \
		  DISP=$$LEN; \
		  sleep 5; \
		fi; \
	done;
	#@$(OPENSTACK) server list

ping: .MANAGER_ADDRESS.$(ENVIRONMENT)
	@. ./.MANAGER_ADDRESS.$(ENVIRONMENT); \
	ping -c3 $$MANAGER_ADDRESS

openstack: init
	@$(OPENSTACK)

endpoints: init
	@. ./.MANAGER_ADDRESS.$(ENVIRONMENT); \
	echo "| ARA        | http://$$MANAGER_ADDRESS:8120  |"; \
	echo "| phpMyAdmin | http://$$MANAGER_ADDRESS:8110  |";

copy: scp
login: ssh
plan: dry-run
push: state-push
tunnel: sshuttle

PHONY: clean console attach detach ssh dry-run list deploy deploy-identity deploy-manager upgrade watch openstack create log login scp copy address check rally refstack deploy-ceph upgrade-ceph bootstrap vpn-sshuttle vpn-wireguard
