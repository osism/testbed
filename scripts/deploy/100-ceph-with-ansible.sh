#!/usr/bin/env bash
set -e

source /opt/configuration/scripts/include.sh
source /opt/configuration/scripts/manager-version.sh

CEPH_VERSION=$(docker inspect --format '{{ index .Config.Labels "de.osism.release.ceph" }}' ceph-ansible)

sh -c '/opt/configuration/scripts/prepare-ceph-configuration.sh'

if [[ $CEPH_VERSION == "octopus" || $CEPH_VERSION == "pacific" || $CEPH_VERSION == "quincy" ]]; then
    # The rgw zone was added in ceph-ansible Reef
    sed -i '/  "client\.rgw\./{s#{{ rgw_zone }}\.##g}' /opt/configuration/environments/ceph/configuration.yml
    sed -i '/  "client\.rgw\./{s#{{ rgw_zone }}\.##g}' /opt/configuration/environments/ceph.test/configuration.yml
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
