# Makefile
# Common operations
default: stack.yml stack-single.yml

STACKNAME = testbed

stack.yml: templates/stack.yml.j2
	jinja2 -o $@ $^

stack-single.yml: templates/stack.yml.j2
	jinja2 -o $@ -Dnumber_of_nodes=0 $^

deploy: stack.yml environment.yml
	@touch .deploy.$(STACKNAME)
	openstack stack create -t $< -e environment.yml $(STACK_PARAMS) $(STACKNAME)

deploy-infra: stack.yml environment.yml
	@touch .deploy.$(STACKNAME)
	openstack stack create -t $< -e environment.yml $(STACK_PARAMS) --parameter deploy_infrastructure=true $(STACKNAME)

deploy-infra-ceph: stack.yml environment.yml
	@touch .deploy.$(STACKNAME)
	openstack stack create -t $< -e environment.yml $(STACK_PARAMS) --parameter deploy_infrastructure=true --parameter deploy_ceph=true $(STACKNAME)

deploy-infra-ceph-openstack: stack.yml environment.yml
	@touch .deploy.$(STACKNAME)
	openstack stack create -t $< -e environment.yml $(STACK_PARAMS) --parameter deploy_infrastructure=true --parameter deploy_ceph=true --parameter deploy_openstack=true $(STACKNAME)

clean:
	openstack stack delete -y $(STACKNAME)
	@rm -f .deploy.$(STACKNAME) .MANAGER_ADDRESS.$(STACKNAME)
	rm -f ~/.ssh/id_rsa.$(STACKNAME)

watch: .deploy.$(STACKNAME)
	MGR_ADR=""; STAT=""; while true; do\
		date; openstack stack list; \
		SRV=$$(openstack server list -f value -c "Name" -c "Status" | grep testbed-manager | cut -d ' ' -f2); \
		openstack server list; \
		if test -z "$$MGR_ADR" -a "$$SRV" = "ACTIVE"; then \
			openstack stack output show $(STACKNAME) private_key -f value -c output_value > ~/.ssh/id_rsa.testbed; \
			chmod 0600 ~/.ssh/id_rsa.testbed; \
			MGR_ADR=$$(openstack stack output show $(STACKNAME) manager_address -f value -c output_value); \
			echo "MANAGER_ADDRESS=$$MGR_ADR" > .MANAGER_ADDRESS.$(STACKNAME); \
		fi; \
		if test -n "$$MGR_ADR"; then ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa.testbed ubuntu@$$MGR_ADR "sudo grep PLAY /var/log/cloud-init-output.log | grep -v 'PLAY \(\[\(Apply role\|Group hosts\|Gather facts\)\|RECAP\)' | tail -n3; sudo tail -n12 /var/log/cloud-init-output.log"; fi; \
		STAT=$$(openstack stack list -f value -c "Stack Name" -c "Stack Status" | grep $(STACKNAME) | cut -d' ' -f2); \
		if test "$$STAT" == "CREATE_COMPLETE"; then break; fi; \
		if test "$$STAT" == "CREATE_FAILED"; then openstack stack show $(STACKNAME) -f value -c "stack_status_reason"; break; fi; \
		echo; sleep 30; \
	done


.deploy.$(STACKNAME):
	STAT=$$(openstack stack list -f value -c "Stack Name" -c "Stack Status" | grep $(STACKNAME) | cut -d' ' -f2); \
	if test -n "$$STAT"; then touch .deploy.$(STACKNAME); else echo "use make deploy or deploy-infra or ...."; exit 1; fi

~/.ssh/id_rsa.$(STACKNAME): .deploy.$(STACKNAME)
	openstack stack output show $(STACKNAME) private_key -f value -c output_value > $@
	chmod 0600 $@

.MANAGER_ADDRESS.$(STACKNAME): .deploy.$(STACKNAME)
	@MANAGER_ADDRESS=$$(openstack stack output show $(STACKNAME) manager_address -f value -c output_value); \
	echo "MANAGER_ADDRESS=$$MANAGER_ADDRESS" > $@; \
	echo $$MANAGER_ADDRESS

sshuttle: ~/.ssh/id_rsa.$(STACKNAME) .MANAGER_ADDRESS.$(STACKNAME)
	eval $$(ssh-agent); ssh-add $<; \
	source ./.MANAGER_ADDRESS.$(STACKNAME); \
	sshuttle -r dragon@$$MANAGER_ADDRESS 192.168.40.0/24 192.168.50.0/24 192.168.90.0/24

ssh_manager: ~/.ssh/id_rsa.$(STACKNAME) .MANAGER_ADDRESS.$(STACKNAME)
	source ./.MANAGER_ADDRESS.$(STACKNAME); \
	ssh -i $< dragon@$$MANAGER_ADDRESS

.PHONY: clean watch sshuttle ssh_manager deploy deploy-infra deploy-infra-ceph deploy-infra-ceph-openstack
