# Makefile

ENVIRONMENT = environment.tfvars
STACKNAME = testbed

NEED_OSCLOUD := $(shell test -z "$$OS_PASSWORD" -a -z "$$OS_CLOUD" && echo 1 || echo 0)
ifeq ($(NEED_OSCLOUD),1)
  OS_CLOUD=testbed
  OPENSTACK=openstack --os-cloud $(OS_CLOUD)
else
  OPENSTACK=openstack
endif

init:
	@terraform init

create: deploy

dry-run: init $(ENVIRONMENT)
	@terraform plan -var-file="$(ENVIRONMENT)" $(PARAMS)

deploy: init $(ENVIRONMENT)
	@touch .deploy.$(STACKNAME)
	@terraform apply -auto-approve -var-file="$(ENVIRONMENT)" $(PARAMS)

deploy-infra: init $(ENVIRONMENT)
	@touch .deploy.$(STACKNAME)
	@terraform apply -auto-approve -var-file="$(ENVIRONMENT)" -var 'deploy_infrastructure=true' $(PARAMS)

deploy-ceph: init $(ENVIRONMENT)
	@touch .deploy.$(STACKNAME)
	@terraform apply -auto-approve -var-file="$(ENVIRONMENT)" -var 'deploy_ceph=true' $(PARAMS)

deploy-openstack: init $(ENVIRONMENT)
	@touch .deploy.$(STACKNAME)
	@terraform apply -auto-approve -var-file="$(ENVIRONMENT)" -var 'deploy_infrastructure=true' -var 'deploy_ceph=true' -var 'deploy_openstack=true' $(PARAMS)

update: deploy

show:
	@terraform show

clean:
	@terraform destroy -auto-approve -var-file="$(ENVIRONMENT)" $(PARAMS)
	@rm -f .deploy.$(STACKNAME) .MANAGER_ADDRESS.$(STACKNAME)
	@rm -f .id_rsa.$(STACKNAME)
	@rm -f terraform.tfstate terraform.tfstate.backup

list:
	@terraform state list

ssh: .MANAGER_ADDRESS.$(STACKNAME) .id_rsa.$(STACKNAME)
	@source ./.MANAGER_ADDRESS.$(STACKNAME); \
	ssh -i .id_rsa.$(STACKNAME) dragon@$$MANAGER_ADDRESS

sshuttle: .MANAGER_ADDRESS.$(STACKNAME) .id_rsa.$(STACKNAME)
	@source ./.MANAGER_ADDRESS.$(STACKNAME); \
	sshuttle --ssh-cmd "ssh -i .id_rsa.$(STACKNAME) " -r dragon@$$MANAGER_ADDRESS 192.168.40.0/24 192.168.50.0/24 192.168.90.0/24 192.168.100.0/24

console: .deploy.$(STACKNAME)
	@$(OPENSTACK) console log show $(STACKNAME)-manager

.deploy.$(STACKNAME):
	@STAT=$$(terraform state list); \
	if test -n "$$STAT"; then touch .deploy.$(STACKNAME); else echo "use make deploy or deploy-infra or ...."; exit 1; fi

.MANAGER_ADDRESS.$(STACKNAME): .deploy.$(STACKNAME)
	@MANAGER_ADDRESS=$$(terraform output manager_address); \
	echo "MANAGER_ADDRESS=$$MANAGER_ADDRESS" > $@;

.id_rsa.$(STACKNAME): .deploy.$(STACKNAME)
	@PRIVATE_KEY=$$(terraform output private_key); \
	echo "$$PRIVATE_KEY" > $@; \
        chmod 0600 $@

watch: .id_rsa.$(STACKNAME) .MANAGER_ADDRESS.$(STACKNAME)
	@source ./.MANAGER_ADDRESS.$(STACKNAME); \
	DISP=0; \
	if test "$$COLORTERM" = "1"; then \
	  GREEN=$$(echo -e "\e[0;32m"); GREENBOLD=$$(echo -e "\e[1;32m"); BOLD=$$(echo -e "\e[0;1m"); RED=$$(echo -e "\e[0;31m"); YELLOW=$$(echo -e "\e[0;33m"); NORM=$$(echo -e "\e[0;0m"); \
	fi; \
	while true; do \
		LEN=$$(ssh -o StrictHostKeyChecking=no -i .id_rsa.$(STACKNAME) ubuntu@$$MANAGER_ADDRESS sudo wc -l /var/log/cloud-init-output.log 2>/dev/null); \
		LEN=$${LEN%% *}; \
		if test -n "$$LEN" -a "$$LEN" != "$$DISP"; then \
		  OUT=$$(ssh -o StrictHostKeyChecking=no -i .id_rsa.$(STACKNAME) ubuntu@$$MANAGER_ADDRESS sudo tail -n $$((LEN-DISP)) /var/log/cloud-init-output.log 2>/dev/null); \
		  echo -e "$$OUT" | sed -e "s/^\(TASK.*\)$$/$$BOLD\1$$NORM/" -e "s/^\(PLAY.*\)$$/$$GREEN\1$$NORM/" -e "s/^\(The system is finally up.*\)$$/$$GREENBOLD\1$$NORM/" -e "s/\(FAILED\)/$$RED\1$$NORM/g" -e "s/\(failed=[1-9][0-9]*\|unreachable=[1-9][0-9]*\)/$$RED\1$$NORM/g" -e "s/\(warn\|WARN\|RETRYING\)/$$YELLOW\1$$NORM/" -e "s/\(ok:\|ok=[0-9]*\)/$$GREEN\1$$NORM/"; \
		  if echo "$$OUT" | grep '^The system is finally up' >/dev/null 2>&1; then break; fi; \
		  DISP=$$LEN; \
		  sleep 5; \
		fi; \
	done;
	#@$(OPENSTACK) server list

PHONY: clean console sshuttle ssh dry-run list create deploy deploy-infra deploy-ceph deploy-openstack watch
