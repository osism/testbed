# Makefile
#
# Shortcuts to invoke OSISM testbed stack generation
#
# Pass STACKFILE=XXX to change the path to the template (default: stack.yml),
# Pass STACKNAME=XXX to change the name of the deployed stack (default: testbed),
# STACK_PARAMS= (e.g. --parameter XYZ=abs) if you want to pass parameter to heat
# TMPL_PARAMS= (e.g. -Dnumber_of_volumes=4) if you want to modify the stack
#  generation from the template.
# ENVIRONMENT= allows to override the default environment.yml file to be used.
#
# If you have not configured your OS_ environment such that openstack works without
# --os-cloud parameter, you can override teh testbed default by passing OS_CLOUD=.
#
# (c) Kurt Garloff <scs@garloff.de>, 3/2020, Apache2 License

STACKFILE = stack.yml
STACKNAME = testbed
ENVIRONMENT = environment.yml

TIMEOUT_DEPLOY = 45
TIMEOUT_DEPLOY_CEPH = 70
TIMEOUT_DEPLOY_INFRA = 70
TIMEOUT_DEPLOY_OPENSTACK = 150

NEED_OSCLOUD := $(shell test -z "$$OS_PASSWORD" -a -z "$$OS_CLOUD" && echo 1 || echo 0)
ifeq ($(NEED_OSCLOUD),1)
  OS_CLOUD=testbed
  OPENSTACK=openstack --os-cloud $(OS_CLOUD)
else
  OPENSTACK=openstack
endif

default: stack.yml stack-single.yml

stack.yml: stack.yml.j2
	jinja2 -o $@ $(TMPL_PARAMS) $^

stack-single.yml: stack.yml.j2
	jinja2 -o $@ $(TMPL_PARAMS) -Dnumber_of_nodes=0 $^

dry-run: $(STACKFILE) $(ENVIRONMENT)
	$(OPENSTACK) stack create --dry-run -t $< -e $(ENVIRONMENT) $(STACK_PARAMS) $(STACKNAME) -f json; echo

deploy: $(STACKFILE) $(ENVIRONMENT)
	@touch .deploy.$(STACKNAME)
	$(OPENSTACK) stack create --timeout $(TIMEOUT_DEPLOY) -t $< -e $(ENVIRONMENT) $(STACK_PARAMS) $(STACKNAME)

show:
	$(OPENSTACK) stack show $(STACKNAME)

create: deploy

deploy-infra: $(STACKFILE) $(ENVIRONMENT)
	@touch .deploy.$(STACKNAME)
	$(OPENSTACK) stack create --timeout $(TIMEOUT_DEPLOY_INFRA) -t $< -e $(ENVIRONMENT) $(STACK_PARAMS) --parameter deploy_infrastructure=true $(STACKNAME)

deploy-ceph: $(STACKFILE) $(ENVIRONMENT)
	@touch .deploy.$(STACKNAME)
	$(OPENSTACK) stack create --timeout $(TIMEOUT_DEPLOY_CEPH) -t $< -e $(ENVIRONMENT) $(STACK_PARAMS) --parameter deploy_ceph=true $(STACKNAME)

# do it all
deploy-openstack: $(STACKFILE) $(ENVIRONMENT)
	@touch .deploy.$(STACKNAME)
	$(OPENSTACK) stack create --timeout $(TIMEOUT_DEPLOY_OPENSTACK) -t $< -e $(ENVIRONMENT) $(STACK_PARAMS) --parameter deploy_infrastructure=true --parameter deploy_ceph=true --parameter deploy_openstack=true $(STACKNAME)

# this will not do kolla purges etc. so do this before manually if you have deployed infra, ceph or openstack
update: $(STACKFILE) $(ENVIRONMENT)
	@touch .deploy.$(STACKNAME)
	$(OPENSTACK) stack update -t $< -e $(ENVIRONMENT) $(STACK_PARAMS) $(STACKNAME)

# Cleanup
clean:
	$(OPENSTACK) stack delete -y $(STACKNAME)
	@rm -f .deploy.$(STACKNAME) .MANAGER_ADDRESS.$(STACKNAME)
	rm -f .id_rsa.$(STACKNAME)

clean-wait:
	$(OPENSTACK) stack delete -y --wait $(STACKNAME)
	@rm -f .deploy.$(STACKNAME) .MANAGER_ADDRESS.$(STACKNAME)
	rm -f .id_rsa.$(STACKNAME)

list:
	$(OPENSTACK) stack list

# To recover from stale cached ssh-key and MANAGER_ADDRESS
reset:
	@rm .deploy.$(STACKNAME)

# Watch the creation of the stack
watch: .deploy.$(STACKNAME)
	@DISP=0; \
	if test "$$COLORTERM" = "1"; then \
	  GREEN=$$(echo -e "\e[0;32m"); GREENBOLD=$$(echo -e "\e[1;32m"); BOLD=$$(echo -e "\e[0;1m"); RED=$$(echo -e "\e[0;31m"); YELLOW=$$(echo -e "\e[0;33m"); NORM=$$(echo -e "\e[0;0m"); \
	fi; \
	MGR_ADR=""; STAT=""; while true; do\
		date; $(OPENSTACK) stack list; \
		SRV=$$($(OPENSTACK) server list -f value -c "Name" -c "Status" | grep $(STACKNAME)-manager | cut -d ' ' -f2); \
		$(OPENSTACK) server list; \
		if test -z "$$MGR_ADR" -a "$$SRV" = "ACTIVE"; then \
			$(OPENSTACK) stack output show $(STACKNAME) private_key -f value -c output_value > .id_rsa.$(STACKNAME); \
			chmod 0600 .id_rsa.$(STACKNAME); \
			MGR_ADR=$$($(OPENSTACK) stack output show $(STACKNAME) manager_address -f value -c output_value); \
			echo "MANAGER_ADDRESS=$$MGR_ADR" > .MANAGER_ADDRESS.$(STACKNAME); \
		fi; \
		if test -n "$$MGR_ADR"; then \
			LEN=$$(ssh -o StrictHostKeyChecking=no -i .id_rsa.$(STACKNAME) ubuntu@$$MGR_ADR sudo wc -l /var/log/cloud-init-output.log 2>/dev/null); \
			LEN=$${LEN%% *}; \
			if test -n "$$LEN" -a "$$LEN" != "$$DISP"; then \
			  OUT=$$(ssh -o StrictHostKeyChecking=no -i .id_rsa.$(STACKNAME) ubuntu@$$MGR_ADR sudo tail -n $$((LEN-DISP)) /var/log/cloud-init-output.log 2>/dev/null); \
			  echo -e "$$OUT" | sed -e "s/^\(TASK.*\)$$/$$BOLD\1$$NORM/" -e "s/^\(PLAY.*\)$$/$$GREEN\1$$NORM/" -e "s/^\(The system is finally up.*\)$$/$$GREENBOLD\1$$NORM/" -e "s/\(FAILED\)/$$RED\1$$NORM/g" -e "s/\(failed=[1-9][0-9]*\|unreachable=[1-9][0-9]*\)/$$RED\1$$NORM/g" -e "s/\(warn\|WARN\|RETRYING\)/$$YELLOW\1$$NORM/" -e "s/\(ok:\|ok=[0-9]*\)/$$GREEN\1$$NORM/"; \
			  DISP=$$LEN; \
			fi; \
		fi; \
		STAT=$$($(OPENSTACK) stack list -f value -c "Stack Name" -c "Stack Status" | grep $(STACKNAME) | cut -d' ' -f2); \
		if test "$$STAT" == "CREATE_COMPLETE"; then break; fi; \
		if test "$$STAT" == "CREATE_FAILED"; then $(OPENSTACK) stack show $(STACKNAME) -f value -c "stack_status_reason"; break; fi; \
		sleep 10; \
	done

# Look for stack
.deploy.$(STACKNAME):
	STAT=$$($(OPENSTACK) stack list -f value -c "Stack Name" -c "Stack Status" | grep $(STACKNAME) | cut -d' ' -f2); \
	if test -n "$$STAT"; then touch .deploy.$(STACKNAME); else echo "use make deploy or deploy-infra or ...."; exit 1; fi

# Get output
.id_rsa.$(STACKNAME): .deploy.$(STACKNAME)
	$(OPENSTACK) stack output show $(STACKNAME) private_key -f value -c output_value > $@
	chmod 0600 $@

.MANAGER_ADDRESS.$(STACKNAME): .deploy.$(STACKNAME)
	@MANAGER_ADDRESS=$$($(OPENSTACK) stack output show $(STACKNAME) manager_address -f value -c output_value); \
	echo "MANAGER_ADDRESS=$$MANAGER_ADDRESS" > $@; \
	echo $$MANAGER_ADDRESS

# Convenience: sshuttle invocation
sshuttle: .id_rsa.$(STACKNAME) .MANAGER_ADDRESS.$(STACKNAME)
	source ./.MANAGER_ADDRESS.$(STACKNAME); \
	sshuttle --ssh-cmd "ssh -i $<" -r dragon@$$MANAGER_ADDRESS 192.168.40.0/24 192.168.50.0/24 192.168.90.0/24 192.168.100.0/24

ssh: .id_rsa.$(STACKNAME) .MANAGER_ADDRESS.$(STACKNAME)
	source ./.MANAGER_ADDRESS.$(STACKNAME); \
	ssh -i $< dragon@$$MANAGER_ADDRESS

console: .deploy.$(STACKNAME)
	$(OPENSTACK) console log show $(STACKNAME)-manager

# avoid confusing make by non-file targets
.PHONY: clean clean-wait console reset watch sshuttle ssh dry-run list create deploy deploy-infra deploy-ceph deploy-openstack
