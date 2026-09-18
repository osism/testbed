#!/usr/bin/env bash
#
# Deploy Ceph with cephadm instead of ceph-ansible.
#
# The core cluster -- bootstrap, host registration, configuration, the MON, MGR
# and crash daemons, the OSDs, the OpenStack pools and their keys -- is deployed
# by the cephadm plays, this script only sequences them.
#
# The preparation of the OSD devices is still done with
# scripts/prepare-ceph-configuration.sh, i.e. with the ceph-configure-lvm-volumes
# and ceph-create-lvm-devices plays. The LVM volumes created there are handed
# over to cephadm as explicit LVM paths, cephadm does not touch the raw block
# devices itself.
#
# The dashboard is applied by the cephadm-dashboard play in the sequence
# below. One part of the deployment still has no play and is therefore done in
# shell below: the MDS and RGW daemons together with the pools and the key
# that belong to them. That section is marked and is removed once the
# corresponding plays are available.
#
# The Ceph image and release are no longer selected here, the plays take them
# from the inventory (ceph_docker_registry, ceph_docker_image and
# ceph_docker_image_tag), i.e. from the same values ceph-ansible would use.
set -e
set -o pipefail

source /opt/configuration/scripts/include.sh

CONFIGURATION_DIRECTORY=/opt/configuration
CEPH_ENVIRONMENT=${CEPH_ENVIRONMENT:-ceph}
CEPH_CONFIGURATION_FILE=$CONFIGURATION_DIRECTORY/environments/$CEPH_ENVIRONMENT/configuration.yml

PYTHON=/opt/venv/bin/python3
[[ -x $PYTHON ]] || PYTHON=$(command -v python3)

##########################################################
# helpers
#
# All helpers below are used by the retained MDS/RGW section only.

# Read a single parameter from the Ceph environment configuration. Booleans are
# normalised to true/false so that they can be used in shell comparisons.
ceph_config() {
    "$PYTHON" -c '
import sys, yaml

with open(sys.argv[3]) as fp:
    data = yaml.safe_load(fp) or {}

value = data.get(sys.argv[1], sys.argv[2])
if isinstance(value, bool):
    value = str(value).lower()
print(value)
' "$1" "$2" "$CEPH_CONFIGURATION_FILE"
}

get_hosts() {
    osism get hosts -l "$1" | awk 'NR>3 && /\|/ { print $2 }'
}

join_hosts() {
    echo "$1" | paste -sd, -
}

count_hosts() {
    echo $1 | wc -w | tr -d ' '
}

# A replica count larger than the number of OSD hosts can never become
# active+clean with the default host failure domain.
#
# This clamp is testbed-only and deliberate, not drift. Neither ceph-ansible
# nor the cephadm-pools play lowers a configured size -- doing so silently
# would change the durability the operator asked for. It applies here only to
# the CephFS and RGW pools created below, which cephadm-pools does not manage
# (it loops osism/defaults' openstack_pools), so the two policies never meet on
# the same pool. It exists so a testbed with fewer OSD hosts than the default
# size of 3 still reaches HEALTH_OK. When the CephFS/RGW plays land, that play
# owns the policy and this goes with the bash around it.
limit_size() {
    local size="$1"
    local maximum="$2"

    if [[ $size -gt $maximum ]]; then
        echo "$maximum"
    else
        echo "$size"
    fi
}

running_daemons() {
    ceph orch ps --daemon-type "$1" --format json 2>/dev/null | "$PYTHON" -c '
import json, sys

try:
    daemons = json.load(sys.stdin)
except ValueError:
    daemons = []
print(len([x for x in daemons if x.get("status_desc") == "running"]))
'
}

wait_for_daemons() {
    local daemon_type="$1"
    local expected="$2"
    local attempt=0

    echo "Waiting for $expected running $daemon_type daemon(s)."
    until [[ $(running_daemons "$daemon_type") -ge $expected ]]; do
        if (( ++attempt > 90 )); then
            echo "Timeout while waiting for $expected running $daemon_type daemon(s)."
            return 1
        fi
        sleep 10
    done
}

create_pool() {
    local name="$1"
    local pg_num="$2"
    local size="$3"
    local min_size="$4"
    local rule="$5"
    local application="$6"
    local pools

    pools=$'\n'$(ceph osd pool ls)$'\n'
    if [[ $pools != *$'\n'$name$'\n'* ]]; then
        ceph osd pool create "$name" "$pg_num" "$pg_num" replicated "$rule"
    fi

    ceph osd pool set "$name" size "$size"
    # A min_size of 0 means "let Ceph decide", it cannot be set explicitly.
    if [[ $min_size -gt 0 ]]; then
        ceph osd pool set "$name" min_size "$min_size"
    fi
    ceph osd pool set "$name" pg_autoscale_mode "$POOL_PG_AUTOSCALE_MODE"
    ceph osd pool application enable "$name" "$application" --yes-i-really-mean-it
}

# Write a client keyring to /etc/ceph on all MON nodes. cephadm keeps the
# keyrings in the MON store only, but the copy-ceph-keys play collects them
# from /etc/ceph on the first MON node.
export_key() {
    local entity="$1"
    local keyring
    local node

    keyring=$(ceph auth get "$entity")
    for node in $CEPH_MON_HOSTS; do
        ssh "$node" "sudo mkdir -p /etc/ceph"
        echo "$keyring" | ssh "$node" "sudo tee /etc/ceph/ceph.$entity.keyring > /dev/null"
        ssh "$node" "sudo chmod 0600 /etc/ceph/ceph.$entity.keyring"
    done
}

echo
echo "# DEPLOY CEPH SERVICES WITH CEPHADM"
echo

##########################################################
# prepare the OSD devices

echo
echo "## Prepare the Ceph configuration"
echo

sh -c '/opt/configuration/scripts/prepare-ceph-configuration.sh'

##########################################################
# deploy the core cluster

echo
echo "## Deploy the core cluster"
echo

# cephadm-bootstrap installs cephadm on the Ceph hosts and bootstraps the
# cluster with the dedicated Ceph key from /opt/ansible/secrets/id_rsa.ceph
# (environments/secrets.yml, inventory/group_vars/ceph.yml). cephclient follows
# immediately, the remaining plays drive the orchestrator through it.
osism apply cephadm-bootstrap
osism apply cephclient
osism apply cephadm-hosts
osism apply cephadm-config
osism apply cephadm-mons
osism apply cephadm-osds
osism apply cephadm-pools
osism apply copy-ceph-keys
osism apply cephadm-dashboard

##########################################################
# deploy the MDS and RGW daemons
#
# RETAINED: the cephadm plays deploy the core cluster only. The CephFS and RGW
# pools, the manila key and the two daemon types below are not covered by them
# and are therefore still created here. This section goes away with the plays
# that take them over.

ENABLE_CEPH_MDS=$(ceph_config enable_ceph_mds false)
ENABLE_CEPH_RGW=$(ceph_config enable_ceph_rgw false)

if [[ $ENABLE_CEPH_MDS == "true" || $ENABLE_CEPH_RGW == "true" ]]; then
    CEPH_FS_NAME=$(ceph_config cephfs cephfs)

    RGW_ZONE=$(ceph_config rgw_zone default)
    RGW_FRONTEND_PORT=$(ceph_config radosgw_frontend_port 8081)
    RGW_SERVICE_ID="${RGW_ZONE}.${RGW_ZONE}"

    # Defaults of the ceph-ansible based deployment, see osism/defaults.
    CEPHFS_POOL_PG_NUM=$(ceph_config cephfs_pool_default_pg_num 16)
    CEPHFS_POOL_SIZE=$(ceph_config cephfs_pool_default_size 3)
    CEPHFS_POOL_MIN_SIZE=$(ceph_config cephfs_pool_default_min_size 0)
    CEPHFS_POOL_RULE=$(ceph_config cephfs_pool_default_rule_name replicated_rule)

    RGW_POOL_PG_NUM=$(ceph_config rgw_pool_default_pg_num 8)
    RGW_POOL_SIZE=$(ceph_config rgw_pool_default_size 3)
    RGW_POOL_RULE=$(ceph_config openstack_pool_default_rule_name replicated_rule)

    if [[ $(ceph_config openstack_pool_default_pg_autoscale_mode false) == "true" ]]; then
        POOL_PG_AUTOSCALE_MODE=on
    else
        POOL_PG_AUTOSCALE_MODE=off
    fi

    CEPH_MON_HOSTS=$(get_hosts ceph-mon)
    CEPH_OSD_HOSTS=$(get_hosts ceph-osd)
    CEPH_MDS_HOSTS=$(get_hosts ceph-mds)
    CEPH_RGW_HOSTS=$(get_hosts ceph-rgw)

    OSD_HOST_COUNT=$(count_hosts "$CEPH_OSD_HOSTS")

    CEPHFS_POOL_SIZE=$(limit_size "$CEPHFS_POOL_SIZE" "$OSD_HOST_COUNT")
    RGW_POOL_SIZE=$(limit_size "$RGW_POOL_SIZE" "$OSD_HOST_COUNT")
fi

if [[ $ENABLE_CEPH_MDS == "true" ]]; then
    echo
    echo "## Create the CephFS pools and the manila key"
    echo

    create_pool cephfs_data "$CEPHFS_POOL_PG_NUM" "$CEPHFS_POOL_SIZE" \
      "$CEPHFS_POOL_MIN_SIZE" "$CEPHFS_POOL_RULE" cephfs
    create_pool cephfs_metadata "$CEPHFS_POOL_PG_NUM" "$CEPHFS_POOL_SIZE" \
      "$CEPHFS_POOL_MIN_SIZE" "$CEPHFS_POOL_RULE" cephfs

    filesystems=$(ceph fs ls --format json)
    if [[ $filesystems != *"\"$CEPH_FS_NAME\""* ]]; then
        ceph fs new "$CEPH_FS_NAME" cephfs_metadata cephfs_data
    fi

    # The key and its capabilities match openstack_keys from osism/defaults.
    ceph auth get-or-create client.manila \
      mon "allow r" \
      mgr "allow rw" \
      osd "allow rw pool=cephfs_data" > /dev/null

    export_key client.manila
fi

if [[ $ENABLE_CEPH_RGW == "true" ]]; then
    echo
    echo "## Create the RGW pools"
    echo

    for pool in buckets.data buckets.index meta log control; do
        create_pool "${RGW_ZONE}.rgw.${pool}" "$RGW_POOL_PG_NUM" "$RGW_POOL_SIZE" \
          0 "$RGW_POOL_RULE" rgw
    done
fi

if [[ $ENABLE_CEPH_MDS == "true" && -n $CEPH_MDS_HOSTS ]]; then
    echo
    echo "## Deploy the MDS daemons"
    echo

    ceph orch apply mds "$CEPH_FS_NAME" --placement="$(join_hosts "$CEPH_MDS_HOSTS")"
    wait_for_daemons mds "$(count_hosts "$CEPH_MDS_HOSTS")"
fi

if [[ $ENABLE_CEPH_RGW == "true" && -n $CEPH_RGW_HOSTS ]]; then
    echo
    echo "## Deploy the RGW daemons"
    echo

    ceph orch apply rgw "$RGW_SERVICE_ID" \
      --placement="$(join_hosts "$CEPH_RGW_HOSTS")" \
      --port="$RGW_FRONTEND_PORT"
    wait_for_daemons rgw "$(count_hosts "$CEPH_RGW_HOSTS")"
fi

##########################################################
# summary

echo
echo "## Summary"
echo

ceph -s
ceph versions
ceph orch ls
ceph orch ps
