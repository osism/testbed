#!/usr/bin/env bash
set -e

source /opt/configuration/scripts/include.sh
source /opt/manager-vars.sh
source /opt/configuration/scripts/manager-version.sh

osism apply keystone
osism apply placement
osism apply neutron
osism apply nova

osism apply horizon
osism apply skyline
osism apply glance
osism apply cinder
osism apply barbican

# designate-manage pool update uses system-scoped auth in OpenStack 2024.1,
# which is incompatible with enforce_scope = True (global.conf). This was
# fixed in 2024.2. Temporarily override for 2024.1 deployments.
OPENSTACK_VERSION=$(docker inspect --format '{{ index .Config.Labels "de.osism.release.openstack" }}' kolla-ansible)
DESIGNATE_OVERLAY=/opt/configuration/environments/kolla/files/overlays/designate.conf
if [[ $OPENSTACK_VERSION == "2024.1" ]]; then
    printf '[oslo_policy]\nenforce_scope = False\nenforce_new_defaults = False\n' > "$DESIGNATE_OVERLAY"
fi
osism apply designate
if [[ $OPENSTACK_VERSION == "2024.1" ]]; then
    rm -f "$DESIGNATE_OVERLAY"
fi
osism apply octavia
osism apply ceilometer
osism apply aodh

osism apply kolla-ceph-rgw

if [[ "$TEMPEST" == "false" ]]; then
    sh -c '/opt/configuration/scripts/deploy/310-openstack-extended.sh'
fi
