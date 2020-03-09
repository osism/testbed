# Makefile
# Shortcuts to invoke OSISM testbed stack generation
# Pass STACKNAME=XXX to change the name of the deployed stack (default: testbed),
# STACK_PARAMS= (e.g. --parameter XYZ=abs) if you want to pass parameter to heat
# TMPL_PARAMS= (e.g. -Dnumber_of_volumes=4) if you want to modify the stack
#  generation from the template.
# 
# (c) Kurt Garloff <scs@garloff.de>, 3/2020, Apache2 License

STACKNAME = testbed

default: stack.yml stack-single.yml

stack.yml: templates/stack.yml.j2
	jinja2 -o $@ $(TMPL_PARAMS) $^

stack-single.yml: templates/stack.yml.j2
	jinja2 -o $@ $(TMPL_PARAMS) -Dnumber_of_nodes=0 $^

dry-run: stack.yml environment.yml
	openstack stack create --dry-run -t $< -e environment.yml $(STACK_PARAMS) $(STACKNAME)

deploy: stack.yml environment.yml
	@touch .deploy.$(STACKNAME)
	openstack stack create --timeout 3000 -t $< -e environment.yml $(STACK_PARAMS) $(STACKNAME)

deploy-infra: stack.yml environment.yml
	@touch .deploy.$(STACKNAME)
	openstack stack create --timeout 4800 -t $< -e environment.yml $(STACK_PARAMS) --parameter deploy_infrastructure=true $(STACKNAME)

deploy-infra-ceph: stack.yml environment.yml
	@touch .deploy.$(STACKNAME)
	openstack stack create --timeout 6600 -t $< -e environment.yml $(STACK_PARAMS) --parameter deploy_infrastructure=true --parameter deploy_ceph=true $(STACKNAME)

deploy-infra-ceph-openstack: stack.yml environment.yml
	@touch .deploy.$(STACKNAME)
	openstack stack create --timeout 9000 -t $< -e environment.yml $(STACK_PARAMS) --parameter deploy_infrastructure=true --parameter deploy_ceph=true --parameter deploy_openstack=true $(STACKNAME)

update: stack.yml environment.yml
	@touch .deploy.$(STACKNAME)
	openstack stack update -t $< -e environment.yml $(STACK_PARAMS) $(STACKNAME)

# Cleanup
clean:
	openstack stack delete -y $(STACKNAME)
	@rm -f .deploy.$(STACKNAME) .MANAGER_ADDRESS.$(STACKNAME)
	rm -f ~/.ssh/id_rsa.$(STACKNAME)

clean-wait:
	openstack stack delete -y --wait $(STACKNAME)
	@rm -f .deploy.$(STACKNAME) .MANAGER_ADDRESS.$(STACKNAME)
	rm -f ~/.ssh/id_rsa.$(STACKNAME)

# To recover from stale ssh-key and MANAGER_ADDRESS
reset:
	@rm .deploy.$(STACKNAME)

# Watch the creation of the stack
watch: .deploy.$(STACKNAME)
	MGR_ADR=""; STAT=""; while true; do\
		date; openstack stack list; \
		SRV=$$(openstack server list -f value -c "Name" -c "Status" | grep testbed-manager | cut -d ' ' -f2); \
		openstack server list; \
		if test -z "$$MGR_ADR" -a "$$SRV" = "ACTIVE"; then \
			openstack stack output show $(STACKNAME) private_key -f value -c output_value > ~/.ssh/id_rsa.$(STACKNAME); \
			chmod 0600 ~/.ssh/id_rsa.$(STACKNAME); \
			MGR_ADR=$$(openstack stack output show $(STACKNAME) manager_address -f value -c output_value); \
			echo "MANAGER_ADDRESS=$$MGR_ADR" > .MANAGER_ADDRESS.$(STACKNAME); \
		fi; \
		if test -n "$$MGR_ADR"; then ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa.$(STACKNAME) ubuntu@$$MGR_ADR "sudo grep PLAY /var/log/cloud-init-output.log | grep -v 'PLAY \(\[\(Group hosts\|Gather facts\)\|RECAP\)' | tail -n3; sudo tail -n12 /var/log/cloud-init-output.log"; fi; \
		STAT=$$(openstack stack list -f value -c "Stack Name" -c "Stack Status" | grep $(STACKNAME) | cut -d' ' -f2); \
		if test "$$STAT" == "CREATE_COMPLETE"; then break; fi; \
		if test "$$STAT" == "CREATE_FAILED"; then openstack stack show $(STACKNAME) -f value -c "stack_status_reason"; break; fi; \
		echo; sleep 30; \
	done

# Look for stack
.deploy.$(STACKNAME):
	STAT=$$(openstack stack list -f value -c "Stack Name" -c "Stack Status" | grep $(STACKNAME) | cut -d' ' -f2); \
	if test -n "$$STAT"; then touch .deploy.$(STACKNAME); else echo "use make deploy or deploy-infra or ...."; exit 1; fi

# Get output
~/.ssh/id_rsa.$(STACKNAME): .deploy.$(STACKNAME)
	openstack stack output show $(STACKNAME) private_key -f value -c output_value > $@
	chmod 0600 $@

.MANAGER_ADDRESS.$(STACKNAME): .deploy.$(STACKNAME)
	@MANAGER_ADDRESS=$$(openstack stack output show $(STACKNAME) manager_address -f value -c output_value); \
	echo "MANAGER_ADDRESS=$$MANAGER_ADDRESS" > $@; \
	echo $$MANAGER_ADDRESS

# Convenience: sshuttle invocation
sshuttle: ~/.ssh/id_rsa.$(STACKNAME) .MANAGER_ADDRESS.$(STACKNAME)
	source ./.MANAGER_ADDRESS.$(STACKNAME); \
	sshuttle --ssh-cmd "ssh -i $<" -r dragon@$$MANAGER_ADDRESS 192.168.40.0/24 192.168.50.0/24 192.168.90.0/24

ssh_manager: ~/.ssh/id_rsa.$(STACKNAME) .MANAGER_ADDRESS.$(STACKNAME)
	source ./.MANAGER_ADDRESS.$(STACKNAME); \
	ssh -i $< dragon@$$MANAGER_ADDRESS

# avoid confusing make by non-file targets
.PHONY: clean clean-wait reset watch sshuttle ssh_manager dry-run deploy deploy-infra deploy-infra-ceph deploy-infra-ceph-openstack
