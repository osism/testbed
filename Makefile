ENVIRONMENT ?= betacloud

VERSION_CEPH ?= pacific
VERSION_MANAGER ?= latest
VERSION_OPENSTACK ?= yoga

clean:
	make -C terraform ENVIRONMENT=$(ENVIRONMENT) clean

create:
	make -C terraform ENVIRONMENT=$(ENVIRONMENT) VERSION_CEPH=$(VERSION_CEPH) VERSION_MANAGER=$(VERSION_MANAGER) VERSION_OPENSTACK=$(VERSION_OPENSTACK) create

login:
	make -C terraform ENVIRONMENT=$(ENVIRONMENT) login

deploy:
	ansible-playbook playbooks/deploy.yml \
	  -i ansible/localhost_inventory.yaml \
	  -e ansible_galaxy=ansible-galaxy \
	  -e ansible_playbook=ansible-playbook \
	  -e basepath="$(PWD)" \
	  -e cloud_env=$(ENVIRONMENT) \
	  -e repo_path="$(PWD)/.src/github.com"
	  -e manual_deploy=true \
	  -e version_ceph=$(VERSION_CEPH) \
	  -e version_manager=$(VERSION_MANAGER) \
	  -e version_openstack=$(VERSION_OPENSTACK)
	cd terraform && make ENVIRONMENT=$(ENVIRONMENT) deploy
	cd terraform && make ENVIRONMENT=$(ENVIRONMENT) check

prepare:
	mkdir -p .src/github.com/osism
	if [ ! -e .src/github.com/osism/testbed ]; then git clone https://github.com/osism/testbed .src/github.com/osism/testbed; fi
	if [ ! -e .src/github.com/osism/ansible-collection-commons ]; then git clone https://github.com/osism/ansible-collection-commons .src/github.com/osism/ansible-collection-commons; fi
	if [ ! -e .src/github.com/osism/ansible-collection-services ]; then git clone https://github.com/osism/ansible-collection-services .src/github.com/osism/ansible-collection-services; fi

phony: clean create deploy login prepare
