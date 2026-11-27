#!/usr/bin/env bash
#
# Upgrade a cephadm-managed Ceph cluster to the release the manager carries,
# by following the section "Ceph managed by cephadm" of the Ceph upgrade
# guide of the OSISM documentation (docs/guides/upgrade-guide/ceph/index.md),
# step by step.
#
# The script does what the guide says and nothing more. Where the guide
# describes a wait in prose, the script waits with a time limit and fails
# with the step's name.
#
# Deviation, because of the testbed only: the configuration edits of step 1
# are made in /opt/configuration directly; osism apply configuration would
# reset the testbed's checkout.
#
# CEPH_RELEASE (default tentacle) is the release to upgrade to.

set -e
set -o pipefail

CEPH_RELEASE=${CEPH_RELEASE:-tentacle}
CONFIGURATION=/opt/configuration

log() {
    echo
    echo "## $*"
    echo
}

fail() {
    echo "ERROR: $*" >&2
    exit 1
}

wait_until() {
    local timeout=$1 what=$2 deadline
    shift 2
    deadline=$((SECONDS + timeout))
    until "$@"; do
        if ((SECONDS >= deadline)); then
            echo "ERROR: $what: not reached after ${timeout}s" >&2
            return 1
        fi
        sleep 10
    done
}

ceph_json() {
    ceph "$@" -f json 2>/dev/null
}

# The single version all daemons run, e.g. 18.2.8; empty if they differ.
cluster_version() {
    ceph_json versions | python3 -c '
import json, re, sys
overall = list(json.load(sys.stdin)["overall"])
print(re.search(r"ceph version (\S+)", overall[0]).group(1) if len(overall) == 1 else "")'
}

before_you_start() {
    log "Before you start"
    ceph orch status | grep -qx 'Backend: cephadm' || fail "Before you start: the cluster is not managed by cephadm"
    ceph -s
    [[ $(ceph health 2>/dev/null) == HEALTH_OK* ]] || fail "Before you start: ceph -s does not report HEALTH_OK"
    local leftovers
    leftovers=$(ceph auth ls 2>/dev/null | grep -E '^(mds\.[^.]+|client\.crash|client\.rgw\..+\.rgw[0-9]+)$' || true)
    [[ -z $leftovers ]] || fail "Before you start: cephx entities left behind by the migration: $leftovers"
    local release
    release=$(grep manager_version "$CONFIGURATION/environments/manager/configuration.yml")
    echo "$release"
    [[ $release =~ manager_version:\ *(11\.|latest) ]] || fail "Before you start: the manager does not run OSISM 11"
}

step1() {
    log "Step 1: Set the Ceph release"
    local conf=$CONFIGURATION/environments/configuration.yml
    if grep -q '^ceph_version:' "$conf"; then
        sed -i "s/^ceph_version:.*/ceph_version: $CEPH_RELEASE/" "$conf"
    else
        echo "ceph_version: $CEPH_RELEASE" >> "$conf"
    fi
    grep '^ceph_version:' "$conf"
    local cephconf=$CONFIGURATION/environments/ceph/configuration.yml
    if [[ -e $cephconf ]] && grep -q 'rgw keystone api version' "$cephconf"; then
        sed -i '/rgw keystone api version/d' "$cephconf"
        echo "removed rgw keystone api version from $cephconf"
    fi
}

TARGET_IMAGE=
TARGET_VERSION=

step2() {
    log "Step 2: Determine the target image"
    local versions tag current base
    versions=$(docker exec osism-ansible grep -A5 '^ceph_image_versions:' /ansible/group_vars/all/versions.yml)
    echo "$versions"
    tag=$(awk -v r="$CEPH_RELEASE" '$1 == r":" {gsub(/["\047]/, "", $2); print $2}' <<<"$versions")
    [[ -n $tag ]] || fail "Step 2: no $CEPH_RELEASE image version in ceph_image_versions"
    current=$(ceph config dump -f json | python3 -c "import json,sys; print(next(e['value'] for e in json.load(sys.stdin) if e['section']=='global' and e['name']=='container_image'))")
    echo "container_image: $current"
    # "take only the registry and path from it"
    base=${current%%@*}
    base=${base%:*}
    [[ $base == */ceph-daemon ]] || fail "Step 2: unexpected container image '$current'"
    TARGET_IMAGE="$base:$tag"
    TARGET_VERSION=${tag%%-*}
    echo "CEPH_IMAGE=${TARGET_IMAGE}"
    ceph orch upgrade check --image "${TARGET_IMAGE}" | tee /tmp/upgrade-check.json
    grep -q "ceph version ${TARGET_VERSION} " /tmp/upgrade-check.json \
        || fail "Step 2: ceph orch upgrade check does not show the target version ${TARGET_VERSION}"
}

# Done when the status no longer reports an upgrade in progress. A Tentacle
# manager prints a sentence, a Reef or Squid manager JSON.
upgrade_done() {
    local status err
    err=$(mktemp)
    # stdout only: anything ceph writes to stderr would break the JSON below,
    # and a paused upgrade would go unnoticed until the time limit.
    if ! status=$(ceph orch upgrade status 2>"$err"); then
        # "ceph orch upgrade status fails for a moment while the managers fail
        # over, cephadm carries on. Run ceph orch upgrade status again"
        echo "ceph orch upgrade status failed, asking again: $(cat "$err")"
        rm -f "$err"
        return 1
    fi
    rm -f "$err"
    if grep -q 'There are no upgrades in progress' <<<"$status"; then
        return 0
    fi
    python3 -c '
import json, sys
s = json.loads(sys.argv[1])
if s.get("is_paused"):
    print("PAUSED: %s" % s.get("message"))
    sys.exit(2)
sys.exit(0 if s.get("in_progress") is False else 1)' "$status" && return 0
    case $? in
        2)
            ceph health detail
            fail "Step 3: the upgrade is paused; ceph health detail names the reason (UPGRADE_*)"
            ;;
    esac
    if ((SECONDS - LAST_PROGRESS >= 300)); then
        LAST_PROGRESS=$SECONDS
        echo "$status" | head -n 12
        ceph -s | grep -E 'health|osd:|progress' || true
    fi
    return 1
}

step3() {
    log "Step 3: Start the upgrade"
    ceph orch upgrade start --image "${TARGET_IMAGE}"
    LAST_PROGRESS=$SECONDS
    # "On a test cluster with 27 daemons the upgrade took about 35 minutes."
    wait_until 5400 "Step 3: ceph orch upgrade" upgrade_done
    ceph orch upgrade status
}

# The health checks step 4 names; AUTH_INSECURE_SERVICE_TICKETS shows as
# HEALTH_ERR for a few seconds after the upgrade and clears on its own.
health_as_step4() {
    ceph_json health detail | python3 -c '
import json, sys
allowed = {"AUTH_INSECURE_CLIENT_KEY_TYPE", "AUTH_INSECURE_KEYS_ALLOWED",
           "AUTH_INSECURE_KEYS_CREATABLE", "AUTH_INSECURE_ROTATING_SERVICE_KEY_TYPE"}
checks = set(json.load(sys.stdin).get("checks", {}))
other = checks - allowed
if other:
    print("waiting for: %s" % sorted(other))
sys.exit(0 if not other else 1)'
}

step4() {
    log "Step 4: Check the result"
    ceph versions
    [[ $(cluster_version) == "$TARGET_VERSION" ]] || fail "Step 4: not every daemon runs ${TARGET_VERSION}"
    wait_until 600 "Step 4: only the health warnings the guide names" health_as_step4
    ceph health detail
}

rgw_containers() {
    ceph orch ps --daemon-type rgw --refresh --format json | python3 -c "
import json, sys
for d in json.load(sys.stdin):
    print(d['daemon_name'], d.get('status_desc'), d.get('container_id'))"
}

rgw_replaced() {
    local name=$1 old=$2
    rgw_containers | awk -v n="$name" -v o="$old" '$1 == n && $2 == "running" && $3 != o {found=1} END {exit !found}'
}

step5() {
    log "Step 5: Remove rgw_keystone_api_version"
    if ceph config dump -f json | python3 -c "import json,sys; sys.exit(0 if any(e['name']=='rgw_keystone_api_version' for e in json.load(sys.stdin)) else 1)"; then
        ceph config rm client.rgw rgw_keystone_api_version
    else
        echo "the cluster does not set rgw_keystone_api_version"
    fi
    ceph orch ps --daemon-type rgw
    local list name status container
    list=$(rgw_containers)
    [[ -n $list ]] || fail "Step 5: no RGW daemons"
    while read -r name status container <&3; do
        echo "redeploying ${name} (container ${container})"
        ceph orch daemon redeploy "${name}"
        # "A daemon takes up to a minute and a half; if one is not running in a
        # new container after 10 minutes, ceph health detail shows why."
        if ! wait_until 600 "Step 5: ${name} running in a new container" rgw_replaced "${name}" "${container}"; then
            ceph health detail
            exit 1
        fi
    done 3<<<"$list"
    ceph orch ps --daemon-type rgw
}

step6() {
    log "Step 6: Update the Ceph client on the manager"
    osism apply cephclient
    local v
    v=$(ceph --version | awk '{print $3}')
    echo "ceph --version: $v"
    [[ $v == "$TARGET_VERSION" ]] || fail "Step 6: the manager's ceph client reports $v, not ${TARGET_VERSION}"
}

main() {
    before_you_start
    step1
    step2
    if [[ $(cluster_version) == "$TARGET_VERSION" ]]; then
        echo "Every daemon already runs ${TARGET_VERSION}: nothing to upgrade."
        return 0
    fi
    step3
    step4
    step5
    step6
    log "Ceph upgrade done"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
