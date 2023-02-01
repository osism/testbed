#!/usr/bin/env bash
set -x
set -e

source /opt/manager-vars.sh
export INTERACTIVE=false

/opt/configuration/scripts/set-manager-version.sh $MANAGER_VERSION

# For a stable release, the versions of Ceph and OpenStack to use
# are set by the version of the stable release (set via the
# manager_version parameter) and not by release names.

if [[ $MANAGER_VERSION == "latest" ]]; then
    /opt/configuration/scripts/set-ceph-version.sh $CEPH_VERSION
    /opt/configuration/scripts/set-openstack-version.sh $OPENSTACK_VERSION
else
    # For stable releases, we use the images from quay.io and not
    # from harbor.services.osism.tech.

    sed -i "s/docker_registry_ansible: .*/docker_registry_ansible: quay.io/g" /opt/configuration/environments/manager/configuration.yml
fi

wait_for_container_healthy() {
    local max_attempts="$1"
    local name="$2"
    local attempt_num=1

    until [[ "$(/usr/bin/docker inspect -f '{{.State.Health.Status}}' $name)" == "healthy" ]]; do
        if (( attempt_num++ == max_attempts )); then
            return 1
        else
            sleep 5
        fi
    done
}

ansible-playbook -i testbed-manager.testbed.osism.xyz, /opt/configuration/ansible/manager-part-3.yml --vault-password-file /opt/configuration/environments/.vault_pass

cp /home/dragon/.ssh/id_rsa.pub /opt/ansible/secrets/id_rsa.operator.pub

# wait for ara-server service
wait_for_container_healthy 60 manager-ara-server-1

# wait for netbox service
wait_for_container_healthy 60 netbox-netbox-1

osism netbox import
osism netbox init
osism netbox manage 1000
osism netbox connect 1000 --state a

osism netbox disable --no-wait testbed-switch-0
osism netbox disable --no-wait testbed-switch-1
osism netbox disable --no-wait testbed-switch-2

osism apply sshconfig
osism apply known-hosts
