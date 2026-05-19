#!/usr/bin/env bash
set -e

source /opt/configuration/scripts/include.sh
source /opt/manager-vars.sh
source /opt/configuration/scripts/manager-version.sh

OPENSTACK_VERSION=$(docker inspect --format '{{ index .Config.Labels "de.osism.release.openstack" }}' kolla-ansible)

# In OpenStack 2024.1 the default Keystone policy does not grant the manager
# role permission for user/project/role CRUD. Write a policy.yaml overlay that
# backports the 2024.2 defaults for those operations. The file persists so that
# subsequent osism apply keystone runs continue to use the same overrides.
# 2024.2+ includes these grants in the built-in policy; no overlay needed.
KEYSTONE_POLICY=/opt/configuration/environments/kolla/files/overlays/keystone/policy.yaml
if [[ $OPENSTACK_VERSION == "2024.1" ]]; then
    mkdir -p "$(dirname "$KEYSTONE_POLICY")"
    cat > "$KEYSTONE_POLICY" << 'EOF'
"identity:create_project": "rule:admin_required or (role:manager and domain_id:%(target.project.domain_id)s)"
"identity:create_user": "rule:admin_required or (role:manager and domain_id:%(target.user.domain_id)s)"
"identity:create_grant": "rule:admin_required or (role:manager and domain_id:%(target.project.domain_id)s)"
"identity:list_roles": "rule:admin_required or role:manager"
"identity:get_role": "rule:admin_required or role:manager"
"identity:list_role_assignments": "rule:admin_required or role:manager"
EOF
fi
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
