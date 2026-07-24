#!/usr/bin/env bash
#
# Deploy Ceph with cephadm instead of ceph-ansible.
#
# The preparation of the OSD devices is still done with
# scripts/prepare-ceph-configuration.sh, i.e. with the ceph-configure-lvm-volumes
# and ceph-create-lvm-devices plays. The LVM volumes created there are handed
# over to cephadm as explicit LVM paths, cephadm does not touch the raw block
# devices itself.
#
# The used container image is the OSISM Ceph image
# (registry.osism.tech/osism/ceph-daemon). The release follows ceph_version from
# environments/manager/configuration.yml, i.e. the same image ceph-ansible would
# use. Both can be overwritten:
#
#   CEPH_IMAGE=registry.osism.tech/osism/ceph-daemon:squid \
#     /opt/configuration/scripts/deploy/100-ceph-with-cephadm.sh
#
# NOTE: The cephclient container on the manager is deployed with the release
#       from environments/manager/configuration.yml. When CEPH_IMAGE is set to
#       another release, set ceph_version there as well (or use
#       scripts/set-ceph-version.sh).
#
set -e
set -o pipefail

source /opt/configuration/scripts/include.sh
source /opt/configuration/scripts/manager-version.sh

CONFIGURATION_DIRECTORY=/opt/configuration
CEPH_ENVIRONMENT=${CEPH_ENVIRONMENT:-ceph}
CEPH_CONFIGURATION_FILE=$CONFIGURATION_DIRECTORY/environments/$CEPH_ENVIRONMENT/configuration.yml
CEPH_SECRETS_FILE=$CONFIGURATION_DIRECTORY/environments/$CEPH_ENVIRONMENT/secrets.yml

PYTHON=/opt/venv/bin/python3
[[ -x $PYTHON ]] || PYTHON=$(command -v python3)

##########################################################
# helpers

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

# Convert ceph_conf_overrides from the ceph-ansible configuration into
# "section<TAB>key<TAB>value" lines for the central configuration store.
ceph_conf_overrides() {
    "$PYTHON" -c '
import sys, yaml

with open(sys.argv[1]) as fp:
    configuration = yaml.safe_load(fp) or {}

secrets = {}
try:
    with open(sys.argv[2]) as fp:
        content = fp.read()
    if not content.lstrip().startswith("$ANSIBLE_VAULT"):
        secrets = yaml.safe_load(content) or {}
except OSError:
    pass

def resolve(value):
    if isinstance(value, bool):
        return str(value).lower()
    value = str(value)
    for name, secret in secrets.items():
        value = value.replace("{{ %s }}" % name, str(secret))
    return value

for section, parameters in (configuration.get("ceph_conf_overrides") or {}).items():
    # ceph-ansible templates one section per RGW daemon. cephadm keeps the
    # configuration centrally, a single client.rgw section covers all daemons.
    if section.startswith("client.rgw"):
        section = "client.rgw"
    for key, value in (parameters or {}).items():
        print("\t".join([section, key.replace(" ", "_"), resolve(value)]))
' "$CEPH_CONFIGURATION_FILE" "$CEPH_SECRETS_FILE"
}

# Convert the lvm_volumes prepared by ceph-configure-lvm-volumes into device
# specifications for "ceph orch daemon add osd".
osd_specifications() {
    "$PYTHON" -c '
import sys, yaml

with open(sys.argv[1]) as fp:
    data = yaml.safe_load(fp) or {}

encrypted = sys.argv[2] == "true"

for volume in data.get("lvm_volumes") or []:
    specification = ["data_devices=/dev/%s/%s" % (volume["data_vg"], volume["data"])]
    if volume.get("db") and volume.get("db_vg"):
        specification.append("db_devices=/dev/%s/%s" % (volume["db_vg"], volume["db"]))
    if volume.get("wal") and volume.get("wal_vg"):
        specification.append("wal_devices=/dev/%s/%s" % (volume["wal_vg"], volume["wal"]))
    if encrypted:
        specification.append("encrypted=true")
    print(",".join(specification))
' "$1" "$2"
}

get_hosts() {
    osism get hosts -l "$1" | awk 'NR>3 && /\|/ { print $2 }'
}

get_address() {
    getent hosts "$1" | awk 'NR == 1 { print $1 }'
}

join_hosts() {
    echo "$1" | paste -sd, -
}

count_hosts() {
    echo $1 | wc -w | tr -d ' '
}

# A replica count larger than the number of OSD hosts can never become
# active+clean with the default host failure domain.
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

wait_for_orchestrator() {
    local attempt=0

    until ceph orch status --format json > /dev/null 2>&1; do
        if (( ++attempt > 60 )); then
            echo "Timeout while waiting for the orchestrator."
            return 1
        fi
        sleep 5
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

##########################################################
# parameters

CEPH_RELEASE=$(docker inspect --format '{{ index .Config.Labels "de.osism.release.ceph" }}' ceph-ansible)

if [[ -z ${CEPH_IMAGE:-} ]]; then
    CEPH_DOCKER_REGISTRY=$(awk -F': ' '/^ceph_docker_registry:/ { print $2 }' \
      "$CONFIGURATION_DIRECTORY/inventory/group_vars/all/registries.yml")
    CEPH_IMAGE_VERSION=$(docker exec ceph-ansible \
      awk -F': ' '/^ceph_image_version:/ { gsub(/"/, "", $2); print $2 }' \
      /ansible/group_vars/all/versions.yml 2>/dev/null || true)
    CEPH_IMAGE="${CEPH_DOCKER_REGISTRY:-registry.osism.tech}/osism/ceph-daemon:${CEPH_IMAGE_VERSION:-$CEPH_RELEASE}"
fi

CEPH_FSID=$(ceph_config fsid "")
CEPH_PUBLIC_NETWORK=$(ceph_config public_network "")
CEPH_CLUSTER_NETWORK=$(ceph_config cluster_network "$CEPH_PUBLIC_NETWORK")
CEPH_DMCRYPT=$(ceph_config dmcrypt false)
CEPH_FS_NAME=$(ceph_config cephfs cephfs)

ENABLE_CEPH_CRASH=$(ceph_config enable_ceph_crash true)
ENABLE_CEPH_MDS=$(ceph_config enable_ceph_mds false)
ENABLE_CEPH_RGW=$(ceph_config enable_ceph_rgw false)

RGW_ZONE=$(ceph_config rgw_zone default)
RGW_FRONTEND_PORT=$(ceph_config radosgw_frontend_port 8081)
RGW_SERVICE_ID="${RGW_ZONE}.${RGW_ZONE}"

DASHBOARD_PASSWORD=$(awk -F': ' '/^ceph_dashboard_password:/ { print $2 }' "$CEPH_SECRETS_FILE")

# Defaults of the ceph-ansible based deployment, see osism/defaults.
OPENSTACK_POOL_PG_NUM=$(ceph_config openstack_pool_default_pg_num 64)
OPENSTACK_POOL_SIZE=$(ceph_config openstack_pool_default_size 3)
OPENSTACK_POOL_MIN_SIZE=$(ceph_config openstack_pool_default_min_size 0)
OPENSTACK_POOL_RULE=$(ceph_config openstack_pool_default_rule_name replicated_rule)

CEPHFS_POOL_PG_NUM=$(ceph_config cephfs_pool_default_pg_num 16)
CEPHFS_POOL_SIZE=$(ceph_config cephfs_pool_default_size 3)
CEPHFS_POOL_MIN_SIZE=$(ceph_config cephfs_pool_default_min_size 0)
CEPHFS_POOL_RULE=$(ceph_config cephfs_pool_default_rule_name replicated_rule)

RGW_POOL_PG_NUM=$(ceph_config rgw_pool_default_pg_num 8)
RGW_POOL_SIZE=$(ceph_config rgw_pool_default_size 3)

if [[ $(ceph_config openstack_pool_default_pg_autoscale_mode false) == "true" ]]; then
    POOL_PG_AUTOSCALE_MODE=on
else
    POOL_PG_AUTOSCALE_MODE=off
fi

echo
echo "# DEPLOY CEPH SERVICES WITH CEPHADM"
echo
echo "Ceph release:     $CEPH_RELEASE"
echo "Ceph image:       $CEPH_IMAGE"
echo "Ceph clusterID:   $CEPH_FSID"
echo "Public network:   $CEPH_PUBLIC_NETWORK"
echo "Cluster network:  $CEPH_CLUSTER_NETWORK"
echo

##########################################################
# prepare the OSD devices

echo
echo "## Prepare the Ceph configuration"
echo

sh -c '/opt/configuration/scripts/prepare-ceph-configuration.sh'

##########################################################
# collect the inventory

echo
echo "## Collect the inventory"
echo

CEPH_HOSTS=$(get_hosts ceph)
CEPH_MON_HOSTS=$(get_hosts ceph-mon)
CEPH_MGR_HOSTS=$(get_hosts ceph-mgr)
CEPH_OSD_HOSTS=$(get_hosts ceph-osd)
CEPH_MDS_HOSTS=$(get_hosts ceph-mds)
CEPH_RGW_HOSTS=$(get_hosts ceph-rgw)

if [[ -z $CEPH_MON_HOSTS ]]; then
    echo "No hosts in the ceph-mon group, nothing to do."
    exit 1
fi

if [[ -z $CEPH_OSD_HOSTS ]]; then
    echo "No hosts in the ceph-osd group, nothing to do."
    exit 1
fi

BOOTSTRAP_HOST=${CEPH_MON_HOSTS%%$'\n'*}
BOOTSTRAP_ADDRESS=$(get_address "$BOOTSTRAP_HOST")

OSD_HOST_COUNT=$(count_hosts "$CEPH_OSD_HOSTS")

OPENSTACK_POOL_SIZE=$(limit_size "$OPENSTACK_POOL_SIZE" "$OSD_HOST_COUNT")
CEPHFS_POOL_SIZE=$(limit_size "$CEPHFS_POOL_SIZE" "$OSD_HOST_COUNT")
RGW_POOL_SIZE=$(limit_size "$RGW_POOL_SIZE" "$OSD_HOST_COUNT")

echo "MON hosts: $(join_hosts "$CEPH_MON_HOSTS")"
echo "MGR hosts: $(join_hosts "$CEPH_MGR_HOSTS")"
echo "OSD hosts: $(join_hosts "$CEPH_OSD_HOSTS")"
echo "MDS hosts: $(join_hosts "$CEPH_MDS_HOSTS")"
echo "RGW hosts: $(join_hosts "$CEPH_RGW_HOSTS")"
echo "Bootstrap: $BOOTSTRAP_HOST ($BOOTSTRAP_ADDRESS)"

##########################################################
# install cephadm

echo
echo "## Install cephadm"
echo

# cephadm is taken out of the OSISM Ceph image. That way the cephadm version
# always matches the deployed Ceph release and no additional package source is
# required on the nodes. As a side effect the image is already present on all
# nodes when the daemons are deployed later on.
for node in $CEPH_HOSTS; do
    echo "+ install cephadm on $node"
    ssh "$node" "docker run --rm --entrypoint /usr/bin/cat $CEPH_IMAGE /usr/sbin/cephadm > /tmp/cephadm"
    ssh "$node" "sudo install -m 0755 -o root -g root /tmp/cephadm /usr/sbin/cephadm && rm -f /tmp/cephadm"
    ssh "$node" "sudo cephadm prepare-host"
done

##########################################################
# bootstrap the cluster

echo
echo "## Bootstrap the cluster"
echo

if [[ -n $DASHBOARD_PASSWORD ]]; then
    DASHBOARD_ARGUMENTS="--initial-dashboard-user admin --initial-dashboard-password $DASHBOARD_PASSWORD --dashboard-password-noupdate"
else
    DASHBOARD_ARGUMENTS="--skip-dashboard"
fi

if ssh "$BOOTSTRAP_HOST" "test -d /var/lib/ceph/$CEPH_FSID"; then
    echo "Cluster $CEPH_FSID is already bootstrapped on $BOOTSTRAP_HOST."
else
    # The monitoring stack is skipped, its images are not mirrored by OSISM.
    ssh "$BOOTSTRAP_HOST" "sudo cephadm --image $CEPH_IMAGE bootstrap \
      --fsid $CEPH_FSID \
      --mon-ip $BOOTSTRAP_ADDRESS \
      --cluster-network $CEPH_CLUSTER_NETWORK \
      --ssh-user dragon \
      $DASHBOARD_ARGUMENTS \
      --skip-monitoring-stack \
      --skip-firewalld \
      --allow-overwrite"
fi

##########################################################
# make the ceph command available on the manager

echo
echo "## Deploy cephclient on the manager"
echo

mkdir -p "$CONFIGURATION_DIRECTORY/environments/infrastructure/files/ceph"
ssh "$BOOTSTRAP_HOST" "sudo cat /etc/ceph/ceph.client.admin.keyring" \
  > "$CONFIGURATION_DIRECTORY/environments/infrastructure/files/ceph/ceph.client.admin.keyring"

osism apply cephclient

wait_for_orchestrator

##########################################################
# configure the orchestrator

echo
echo "## Configure the orchestrator"
echo

# Use the operator user and the operator key of the OSISM deployment. The
# public key is already present on all nodes, no key distribution is required.
if [[ -e /opt/ansible/secrets/id_rsa.operator ]]; then
    OPERATOR_KEY=/opt/ansible/secrets/id_rsa.operator
else
    OPERATOR_KEY=/home/dragon/.ssh/id_rsa
fi

ceph cephadm set-user dragon

# The key is imported through /opt/cephclient/data, which is mounted as /data in
# the cephclient container. The container does not run as root, the files
# therefore have to belong to the user inside the container.
CEPHCLIENT_UID=$(docker exec cephclient id -u)
CEPHCLIENT_GID=$(docker exec cephclient id -g)

sudo install -m 0600 -o "$CEPHCLIENT_UID" -g "$CEPHCLIENT_GID" \
  "$OPERATOR_KEY" /opt/cephclient/data/id_rsa.operator
sudo install -m 0600 -o "$CEPHCLIENT_UID" -g "$CEPHCLIENT_GID" \
  "$OPERATOR_KEY.pub" /opt/cephclient/data/id_rsa.operator.pub

ceph cephadm set-priv-key -i /data/id_rsa.operator
ceph cephadm set-pub-key -i /data/id_rsa.operator.pub

sudo rm -f /opt/cephclient/data/id_rsa.operator /opt/cephclient/data/id_rsa.operator.pub

ceph config set global container_image "$CEPH_IMAGE"
ceph config set global public_network "$CEPH_PUBLIC_NETWORK"
ceph config set global cluster_network "$CEPH_CLUSTER_NETWORK"

# Take over the parameters from ceph_conf_overrides of the ceph-ansible
# configuration into the central configuration store.
while IFS=$'\t' read -r section key value; do
    [[ -n $section ]] || continue
    # The values are not logged, some of them are secrets.
    echo "+ ceph config set $section $key"
    ceph config set "$section" "$key" "$value" < /dev/null
done < <(ceph_conf_overrides)

ceph config set mgr mgr/dashboard/standby_behaviour "$(ceph_config ceph_dashboard_standby_behaviour error)"
ceph config set mgr mgr/dashboard/standby_error_status_code "$(ceph_config ceph_dashboard_standby_error_status_code 404)"

##########################################################
# register the hosts

echo
echo "## Register the hosts"
echo

for node in $CEPH_HOSTS; do
    echo "+ ceph orch host add $node $(get_address "$node")"
    ceph orch host add "$node" "$(get_address "$node")" || true
done

for node in $CEPH_MON_HOSTS; do
    # _admin makes cephadm maintain ceph.conf and the admin keyring in
    # /etc/ceph on the node. Both are used by the copy-ceph-keys play.
    ceph orch host label add "$node" _admin
done

ceph orch host ls

for node in $CEPH_HOSTS; do
    ceph cephadm check-host "$node"
done

##########################################################
# deploy the MON, MGR and crash daemons

echo
echo "## Deploy the MON, MGR and crash daemons"
echo

ceph orch apply mon --placement="$(join_hosts "$CEPH_MON_HOSTS")"
ceph orch apply mgr --placement="$(join_hosts "$CEPH_MGR_HOSTS")"

wait_for_daemons mon "$(count_hosts "$CEPH_MON_HOSTS")"
wait_for_daemons mgr "$(count_hosts "$CEPH_MGR_HOSTS")"

if [[ $ENABLE_CEPH_CRASH == "true" ]]; then
    ceph orch apply crash --placement="$(join_hosts "$CEPH_HOSTS")"
fi

##########################################################
# deploy the OSD daemons

echo
echo "## Deploy the OSD daemons"
echo

# The LVM volumes have been created by the ceph-create-lvm-devices play. They
# are passed to cephadm as explicit paths, cephadm therefore neither has to
# discover nor to partition the block devices itself.
for node in $CEPH_OSD_HOSTS; do
    lvm_configuration=$CONFIGURATION_DIRECTORY/inventory/host_vars/$node/ceph-lvm-configuration.yml

    if [[ ! -e $lvm_configuration ]]; then
        echo "No LVM configuration available for $node, no OSDs are created there."
        continue
    fi

    while read -r specification; do
        [[ -n $specification ]] || continue
        echo "+ ceph orch daemon add osd $node:$specification"
        ceph orch daemon add osd "$node:$specification" < /dev/null
    done < <(osd_specifications "$lvm_configuration" "$CEPH_DMCRYPT")
done

ceph osd tree

##########################################################
# create the pools

echo
echo "## Create the pools"
echo

for pool in backups volumes images metrics vms; do
    create_pool "$pool" "$OPENSTACK_POOL_PG_NUM" "$OPENSTACK_POOL_SIZE" \
      "$OPENSTACK_POOL_MIN_SIZE" "$OPENSTACK_POOL_RULE" rbd
done

if [[ $ENABLE_CEPH_MDS == "true" ]]; then
    create_pool cephfs_data "$CEPHFS_POOL_PG_NUM" "$CEPHFS_POOL_SIZE" \
      "$CEPHFS_POOL_MIN_SIZE" "$CEPHFS_POOL_RULE" cephfs
    create_pool cephfs_metadata "$CEPHFS_POOL_PG_NUM" "$CEPHFS_POOL_SIZE" \
      "$CEPHFS_POOL_MIN_SIZE" "$CEPHFS_POOL_RULE" cephfs

    filesystems=$(ceph fs ls --format json)
    if [[ $filesystems != *"\"$CEPH_FS_NAME\""* ]]; then
        ceph fs new "$CEPH_FS_NAME" cephfs_metadata cephfs_data
    fi
fi

if [[ $ENABLE_CEPH_RGW == "true" ]]; then
    for pool in buckets.data buckets.index meta log control; do
        create_pool "${RGW_ZONE}.rgw.${pool}" "$RGW_POOL_PG_NUM" "$RGW_POOL_SIZE" \
          0 "$OPENSTACK_POOL_RULE" rgw
    done
fi

ceph osd pool ls detail

##########################################################
# create the keys

echo
echo "## Create the keys"
echo

# The keys and capabilities match openstack_keys from osism/defaults.
ceph auth get-or-create client.cinder-backup \
  mon "profile rbd" \
  osd "profile rbd pool=backups" > /dev/null

ceph auth get-or-create client.cinder \
  mon "profile rbd" \
  osd "profile rbd pool=volumes, profile rbd pool=vms, profile rbd pool=images" > /dev/null

ceph auth get-or-create client.glance \
  mon "profile rbd" \
  osd "profile rbd pool=volumes, profile rbd pool=images" > /dev/null

ceph auth get-or-create client.gnocchi \
  mon "profile rbd" \
  osd "profile rbd pool=metrics" > /dev/null

ceph auth get-or-create client.nova \
  mon "profile rbd" \
  osd "profile rbd pool=images, profile rbd pool=vms, profile rbd pool=volumes, profile rbd pool=backups" > /dev/null

if [[ $ENABLE_CEPH_MDS == "true" ]]; then
    ceph auth get-or-create client.manila \
      mon "allow r" \
      mgr "allow rw" \
      osd "allow rw pool=cephfs_data" > /dev/null
fi

# cephadm maintains the admin keyring on all hosts with the _admin label, it is
# written explicitly as well to not depend on the next orchestrator run.
for entity in client.admin client.cinder-backup client.cinder client.glance client.gnocchi client.nova; do
    export_key "$entity"
done

if [[ $ENABLE_CEPH_MDS == "true" ]]; then
    export_key client.manila
fi

##########################################################
# deploy the MDS and RGW daemons

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
# distribute the keys

echo
echo "## Distribute the keys"
echo

osism apply copy-ceph-keys

##########################################################
# summary

echo
echo "## Summary"
echo

ceph -s
ceph versions
ceph orch ls
ceph orch ps
