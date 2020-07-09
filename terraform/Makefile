# Makefile

ENVIRONMENT = betacloud

NEED_OSCLOUD := $(shell test -z "$$OS_PASSWORD" -a -z "$$OS_CLOUD" && echo 1 || echo 0)
ifeq ($(NEED_OSCLOUD),1)
  OS_CLOUD=$(ENVIRONMENT)
  OPENSTACK=openstack --os-cloud $(OS_CLOUD)
else
  OPENSTACK=openstack
endif

init:
	@if [ ! -d .terraform/plugins ]; then \
		terraform init; \
	fi

	@if [ -d "terraform.tfstate.d/${ENVIRONMENT}" ]; then \
		terraform workspace select ${ENVIRONMENT}; \
	else \
		terraform workspace new ${ENVIRONMENT}; \
	fi

dry-run: init
	@terraform plan -var-file="environment-$(ENVIRONMENT).tfvars" $(PARAMS)

deploy: init
	@touch .deploy.$(ENVIRONMENT)
	@terraform apply -auto-approve -var-file="environment-$(ENVIRONMENT).tfvars" $(PARAMS)

deploy-infra: init
	@touch .deploy.$(ENVIRONMENT)
	@terraform apply -auto-approve -var-file="environment-$(ENVIRONMENT).tfvars" -var 'deploy_infrastructure=true' $(PARAMS)

deploy-ceph: init
	@touch .deploy.$(ENVIRONMENT)
	@terraform apply -auto-approve -var-file="environment-$(ENVIRONMENT).tfvars" -var 'deploy_ceph=true' $(PARAMS)

deploy-openstack: init
	@touch .deploy.$(ENVIRONMENT)
	@terraform apply -auto-approve -var-file="environment-$(ENVIRONMENT).tfvars" -var 'deploy_infrastructure=true' -var 'deploy_ceph=true' -var 'deploy_openstack=true' $(PARAMS)

show: init
	@terraform show

clean: init
	@terraform destroy -auto-approve -var-file="environment-$(ENVIRONMENT).tfvars" $(PARAMS)
	@rm -f .deploy.$(ENVIRONMENT) .MANAGER_ADDRESS.$(ENVIRONMENT)
	@rm -f .id_rsa.$(ENVIRONMENT)
	@terraform workspace select default
	@terraform workspace delete $(ENVIRONMENT)

list: init
	@terraform state list

ssh: .MANAGER_ADDRESS.$(ENVIRONMENT) .id_rsa.$(ENVIRONMENT)
	@source ./.MANAGER_ADDRESS.$(ENVIRONMENT); \
	ssh -i .id_rsa.$(ENVIRONMENT) dragon@$$MANAGER_ADDRESS

sshuttle: .MANAGER_ADDRESS.$(ENVIRONMENT) .id_rsa.$(ENVIRONMENT)
	@source ./.MANAGER_ADDRESS.$(ENVIRONMENT); \
	sshuttle --ssh-cmd "ssh -i .id_rsa.$(ENVIRONMENT) " -r dragon@$$MANAGER_ADDRESS 192.168.40.0/24 192.168.50.0/24 192.168.90.0/24 192.168.100.0/24

console: .deploy.$(ENVIRONMENT)
	@$(OPENSTACK) console log show testbed-manager

.deploy.$(ENVIRONMENT): init
	@STAT=$$(terraform state list); \
	if test -n "$$STAT"; then touch .deploy.$(ENVIRONMENT); else echo "use make deploy or deploy-infra or ...."; exit 1; fi

.MANAGER_ADDRESS.$(ENVIRONMENT): .deploy.$(ENVIRONMENT)
	@MANAGER_ADDRESS=$$(terraform output manager_address); \
	echo "MANAGER_ADDRESS=$$MANAGER_ADDRESS" > $@;

.id_rsa.$(ENVIRONMENT): .deploy.$(ENVIRONMENT)
	@PRIVATE_KEY=$$(terraform output private_key); \
	echo "$$PRIVATE_KEY" > $@; \
        chmod 0600 $@

watch: .id_rsa.$(ENVIRONMENT) .MANAGER_ADDRESS.$(ENVIRONMENT)
	@source ./.MANAGER_ADDRESS.$(ENVIRONMENT); \
	DISP=0; \
	if test "$$COLORTERM" = "1"; then \
	  GREEN=$$(echo -e "\e[0;32m"); GREENBOLD=$$(echo -e "\e[1;32m"); BOLD=$$(echo -e "\e[0;1m"); RED=$$(echo -e "\e[0;31m"); YELLOW=$$(echo -e "\e[0;33m"); NORM=$$(echo -e "\e[0;0m"); \
	fi; \
	while true; do \
		LEN=$$(ssh -o StrictHostKeyChecking=no -i .id_rsa.$(ENVIRONMENT) ubuntu@$$MANAGER_ADDRESS sudo wc -l /var/log/cloud-init-output.log 2>/dev/null); \
		LEN=$${LEN%% *}; \
		if test -n "$$LEN" -a "$$LEN" != "$$DISP"; then \
		  OUT=$$(ssh -o StrictHostKeyChecking=no -i .id_rsa.$(ENVIRONMENT) ubuntu@$$MANAGER_ADDRESS sudo tail -n $$((LEN-DISP)) /var/log/cloud-init-output.log 2>/dev/null); \
		  echo -e "$$OUT" | sed -e "s/^\(TASK.*\)$$/$$BOLD\1$$NORM/" -e "s/^\(PLAY.*\)$$/$$GREEN\1$$NORM/" -e "s/^\(The system is finally up.*\)$$/$$GREENBOLD\1$$NORM/" -e "s/\(FAILED\)/$$RED\1$$NORM/g" -e "s/\(failed=[1-9][0-9]*\|unreachable=[1-9][0-9]*\)/$$RED\1$$NORM/g" -e "s/\(warn\|WARN\|RETRYING\)/$$YELLOW\1$$NORM/" -e "s/\(ok:\|ok=[0-9]*\)/$$GREEN\1$$NORM/"; \
		  if echo "$$OUT" | grep '^The system is finally up' >/dev/null 2>&1; then break; fi; \
		  DISP=$$LEN; \
		  sleep 5; \
		fi; \
	done;
	#@$(OPENSTACK) server list

PHONY: clean console sshuttle ssh dry-run list deploy deploy-infra deploy-ceph deploy-openstack watch
