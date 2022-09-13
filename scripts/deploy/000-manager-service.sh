#!/usr/bin/env bash
set -x
set -e

source /opt/manager-vars.sh
export INTERACTIVE=false

/opt/configuration/scripts/set-manager-version.sh $MANAGER_VERSION

# NOTE: For a stable release, the versions of Ceph and OpenStack to use
#       are set by the version of the stable release (set via the
#       manager_version parameter) and not by release names.

if [[ $MANAGER_VERSION == "latest" ]]; then
    /opt/configuration/scripts/set-ceph-version.sh $CEPH_VERSION
    /opt/configuration/scripts/set-openstack-version.sh $OPENSTACK_VERSION
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

# NOTE(berendt): wait for ara-server service
wait_for_container_healthy 60 manager-ara-server-1

# NOTE(berendt): wait for netbox service
wait_for_container_healthy 30 netbox-netbox-1

osism netbox import --vendors Arista
osism netbox import --vendors Other --no-library
osism netbox init
osism netbox manage 1000
osism netbox connect 1000 --state a
