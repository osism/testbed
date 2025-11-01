#!/usr/bin/env bash
set -e

source /opt/configuration/scripts/include.sh
source /opt/configuration/scripts/manager-version.sh

CEPH_VERSION=$(docker inspect --format '{{ index .Config.Labels "de.osism.release.ceph" }}' ceph-ansible)

sh -c '/opt/configuration/scripts/prepare-ceph-configuration.sh'

# The callback plugin is not included in the Pacific image. The plugin is no longer
# added there because the builds for Pacific are disabled. This callback plugin will
# therefore not be used during the deployment of Ceph.
if [[ $MANAGER_VERSION == "latest" && $CEPH_VERSION == "pacific" ]]; then
    sed -i "s/osism.commons.still_alive/community.general.yaml/" /opt/configuration/environments/ansible.cfg
fi

if [[ $CEPH_VERSION == "octopus" || $CEPH_VERSION == "pacific" || $CEPH_VERSION == "quincy" ]]; then
    # The rgw zone was added in ceph-ansible Reef
    sed -i '/  "client\.rgw\./{s#{{ rgw_zone }}\.##g}' environments/ceph/configuration.yml
    sed -i '/  "client\.rgw\./{s#{{ rgw_zone }}\.##g}' environments/ceph.test/configuration.yml
fi

if [[ $(semver $MANAGER_VERSION 5.0.0) -eq -1 && $MANAGER_VERSION != "latest" ]]; then
    osism apply ceph-base
    osism apply ceph-mdss
    osism apply ceph-rgws
    osism apply copy-ceph-keys
    osism apply cephclient
    osism apply ceph-bootstrap-dashboard
else
    osism apply ceph

    if [[ $(semver $MANAGER_VERSION 7.0.0) -ge 0 || $MANAGER_VERSION == "latest" ]]; then
        osism apply ceph-pools
    fi

    osism apply copy-ceph-keys
    osism apply cephclient
    osism apply ceph-bootstrap-dashboard
fi

# Once Ceph has been deployed, the callback plugin can be used again.
if [[ $MANAGER_VERSION == "latest" && $CEPH_VERSION == "pacific" ]]; then
    sed -i "s/community.general.yaml/osism.commons.still_alive/" /opt/configuration/environments/ansible.cfg
fi
