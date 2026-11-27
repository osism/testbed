#!/usr/bin/env bash
#
# Rotate the cephx keys of a cephadm-managed testbed, following the
# operations guide "cephx key rotation" (sections 1-5), and check the result
# with osism validate ceph-keys after each section.
#
# Run as the last step of a lane, when the job sets ceph_key_rotation: true.
#
# Never print a key. This script does not use set -x, and must not run
# ceph auth get/ls/export or print a keyring: Zuul logs are public.
#
# The keyrings copy-ceph-keys writes into /opt/configuration belong in the
# configuration repository (deploy guide, "Get ceph keys"). The testbed's
# .gitignore ignores them because every deployment mints new keys, so they
# are force-added and committed locally here, as an operator's repository
# would hold them. Nothing is pushed.
#
# A run that stops in the middle of a rotation leaves a pending key and fails.
# Redeploy such a testbed, or finish the rotation by hand as described in the
# guide's "If a step fails".

set -e
set -o pipefail

CONFIGURATION=/opt/configuration
ROTATE_PLAYBOOK=/ansible/ceph/cephadm-rotate-keys.yml

# Where copy-ceph-keys puts the keyrings (ansible-playbooks
# playbooks/manager/vars/ceph-keys.yml), relative to the checkout.
KEYRING_PATHS=(
    environments/infrastructure/files/ceph/ceph.client.admin.keyring
    environments/kolla/files/overlays/cinder/cinder-volume/ceph.client.cinder.keyring
    environments/kolla/files/overlays/cinder/cinder-backup/ceph.client.cinder.keyring
    environments/kolla/files/overlays/cinder/cinder-backup/ceph.client.cinder-backup.keyring
    environments/kolla/files/overlays/nova/ceph.client.cinder.keyring
    environments/kolla/files/overlays/nova/ceph.client.nova.keyring
    environments/kolla/files/overlays/glance/ceph.client.glance.keyring
    environments/kolla/files/overlays/gnocchi/ceph.client.gnocchi.keyring
    environments/kolla/files/overlays/manila/ceph.client.manila.keyring
)

# The report of the last validate_ceph_keys call.
VALIDATE_REPORT=

log() {
    echo
    echo "## $*"
    echo
}

rotate_keys() {
    osism apply cephadm-rotate-keys \
        -e "ceph_rotate_keys=$1" \
        -e ceph_rotate_keys_min_age=0
}

# Commits the keyrings that changed. With "required" as $2, nothing to
# commit is an error: a rotation that changes no keyring tested nothing.
commit_keyrings() {
    local message=$1 required=${2:-} path
    for path in "${KEYRING_PATHS[@]}"; do
        if [[ -e $CONFIGURATION/$path ]]; then
            git -C "$CONFIGURATION" add -f "$path"
        fi
    done
    if ! git -C "$CONFIGURATION" diff --cached --quiet; then
        git -C "$CONFIGURATION" \
            -c user.name=testbed -c user.email=testbed@testbed.osism.xyz \
            commit -q -m "$message"
        git -C "$CONFIGURATION" log --stat --format='%h %s' -1
    elif [[ $required == required ]]; then
        echo "ERROR: $message: no keyring in $CONFIGURATION changed" >&2
        return 1
    fi
}

# Runs the validator and returns its exit status. VALIDATE_REPORT is set to
# the report this invocation wrote, or empty if its output names none.
validate_ceph_keys() {
    local out rc=0
    out=$(mktemp)
    osism validate ceph-keys "$@" 2>&1 | tee "$out" || rc=$?
    VALIDATE_REPORT=$(grep -oE 'Report: [^ ]+-report\.json' "$out" | tail -n 1 | cut -d' ' -f2 || true)
    rm -f "$out"
    return $rc
}

# Prints the result of check $1 from the report of the last validate_ceph_keys.
report_check() {
    if [[ -z $VALIDATE_REPORT || ! -r $VALIDATE_REPORT ]]; then
        echo "ERROR: no validator report from the last run (got '$VALIDATE_REPORT')" >&2
        return 1
    fi
    python3 -c '
import json, sys
report = json.load(open(sys.argv[1]))
results = [t["result"] for t in report["validator_tests"] if t["name"] == sys.argv[2]]
if len(results) != 1:
    sys.exit("no single check named %s in %s" % (sys.argv[2], sys.argv[1]))
print(results[0])
' "$VALIDATE_REPORT" "$1"
}

# Set when running-guests fails before the rotation (see main): until section 5
# has migrated the instances, it keeps naming them.
GUESTS_MAY_FAIL=false

# validate_ceph_keys, except that while GUESTS_MAY_FAIL is true a failing
# running-guests is accepted if every other check passes.
validate_ok() {
    local check
    validate_ceph_keys "$@" && return 0
    [[ $GUESTS_MAY_FAIL == true ]] || return 1
    for check in pending-keys old-key-type monitor-copies checkout; do
        [[ $(report_check "$check") == passed ]] || return 1
    done
    echo "running-guests still names instances started before the libvirt restart; section 5 migrates them."
}

validate_until_pass() {
    local timeout=$1 deadline
    shift
    deadline=$((SECONDS + timeout))
    while true; do
        if validate_ok "$@"; then
            return 0
        fi
        if ((SECONDS >= deadline)); then
            echo "ERROR: osism validate ceph-keys still fails after ${timeout}s" >&2
            return 1
        fi
        sleep 60
    done
}

# Whether the monitors still allow the old key type aes.
old_cipher_allowed() {
    ceph mon dump 2>/dev/null | grep '^auth_allowed_ciphers' | grep -qw aes
}

# Whether the entity exists on the cluster: ceph exits 2 (ENOENT) for a
# missing one; any other error stops the script, so that it cannot pass for
# "absent". The key goes to /dev/null.
entity_exists() {
    local rc=0
    ceph auth get "$1" >/dev/null 2>&1 || rc=$?
    case $rc in
        0) return 0 ;;
        2) return 1 ;;
        *)
            echo "ERROR: ceph auth get $1 failed with rc $rc" >&2
            exit 1
            ;;
    esac
}

# Waits until "$@" prints $1. $2 is the timeout in seconds.
wait_for() {
    local want=$1 timeout=$2 got deadline
    shift 2
    deadline=$((SECONDS + timeout))
    while true; do
        got=$("$@" 2>/dev/null || true)
        if [[ $got == "$want" ]]; then
            return 0
        fi
        if [[ $got == error* ]] || ((SECONDS >= deadline)); then
            echo "ERROR: '$*' is '$got', expected '$want'" >&2
            return 1
        fi
        sleep 5
    done
}

# Waits until "$@" fails (the resource is gone). $1 is the timeout in seconds.
wait_gone() {
    local timeout=$1 deadline
    shift
    deadline=$((SECONDS + timeout))
    while "$@" >/dev/null 2>&1; do
        if ((SECONDS >= deadline)); then
            echo "ERROR: '$*' still exists after ${timeout}s" >&2
            return 1
        fi
        sleep 5
    done
}

# Section 1: delete the keys of OpenStack services that are not run, and
# collect the section-4 groups that remain in OPENSTACK_GROUPS.
OPENSTACK_GROUPS=()
delete_unused_service_keys() {
    local types binaries entity runs
    types=$(openstack --os-cloud admin service list -f value -c Type)
    binaries=$(openstack --os-cloud admin volume service list -f value -c Binary)
    for entity in client.glance client.cinder-backup client.gnocchi client.manila; do
        case $entity in
            client.glance) runs=$(grep -cx image <<<"$types" || true) ;;
            client.cinder-backup) runs=$(grep -cx cinder-backup <<<"$binaries" || true) ;;
            client.gnocchi) runs=$(grep -cx metric <<<"$types" || true) ;;
            client.manila) runs=$(grep -cxE 'share|sharev2' <<<"$types" || true) ;;
        esac
        if ! entity_exists "$entity"; then
            echo "$entity: not on the cluster, skipped"
        elif [[ $runs -eq 0 ]]; then
            echo "$entity: its service is not run, deleting the key"
            ceph auth del "$entity"
        else
            OPENSTACK_GROUPS+=("$entity")
        fi
    done
    echo "OpenStack groups to rotate: ${OPENSTACK_GROUPS[*]}"
}

# Glance may connect to Ceph only when it is used: download an image.
exercise_glance() {
    local image out
    image=$(openstack --os-cloud admin image list --status active -f value -c ID | awk 'NR == 1')
    if [[ -z $image ]]; then
        echo "ERROR: no active image to download" >&2
        return 1
    fi
    out=$(mktemp)
    openstack --os-cloud admin image save --file "$out" "$image"
    rm -f "$out"
}

# cinder-backup connects to Ceph only for a backup: make one. After a
# restart (the apply restarts it), cinder-backup reports its backend as not
# ready for 60-90 s (measured on the testbed, also right after a deploy),
# and the scheduler refuses backups with "Service not found for creating
# backup" until then. Only that error is retried, for at most 300 s: a
# backup driver that cannot use its key stays not ready and still fails.
exercise_cinder_backup() {
    local name=rotation-backup-check volume backup deadline backup_deadline status reason
    # IDs, not the name: a leftover of a failed run may carry the same name.
    volume=$(openstack --os-cloud admin volume create --size 1 -f value -c id "$name")
    wait_for available 300 openstack --os-cloud admin volume show -f value -c status "$volume"
    deadline=$((SECONDS + 300))
    while true; do
        backup=$(openstack --os-cloud admin volume backup create --name "$name" -f value -c id "$volume")
        backup_deadline=$((SECONDS + 600))
        status=creating
        while [[ $status != available && $status != error ]]; do
            if ((SECONDS >= backup_deadline)); then
                echo "ERROR: the backup is still '$status' after 600s" >&2
                return 1
            fi
            sleep 5
            status=$(openstack --os-cloud admin volume backup show -f value -c status "$backup")
        done
        [[ $status != available ]] || break
        reason=$(openstack --os-cloud admin volume backup show -f value -c fail_reason "$backup")
        if [[ $reason != "Service not found for creating backup." ]] || ((SECONDS >= deadline)); then
            echo "ERROR: the backup failed: $reason" >&2
            return 1
        fi
        echo "cinder-backup is not ready yet ($reason), retrying"
        openstack --os-cloud admin volume backup delete "$backup"
        wait_gone 300 openstack --os-cloud admin volume backup show "$backup"
        sleep 15
    done
    openstack --os-cloud admin volume backup delete "$backup"
    wait_gone 300 openstack --os-cloud admin volume backup show "$backup"
    openstack --os-cloud admin volume delete "$volume"
}

# Section 4, one group: stage, put the keyrings into the repository, apply,
# use the key, check.
rotate_group() {
    local entity=$1 timeout=600 service
    shift
    log "Rotate $entity"
    rotate_keys "$entity"
    commit_keyrings "Rotate the key of $entity" required
    for service in "$@"; do
        osism apply "$service"
    done
    case $entity in
        client.glance) exercise_glance ;;
        client.cinder-backup) exercise_cinder_backup ;;
        # The monitor-node copies are rewritten about ten minutes after the
        # commit (guide, section 4).
        client.admin) timeout=1200 ;;
    esac
    validate_until_pass "$timeout"
}

# The running instances and their floating IPs, recorded before the rotation.
EXPECTED_INSTANCES=()
declare -A EXPECTED_FIPS=()
record_instances() {
    local ip port server fips
    mapfile -t EXPECTED_INSTANCES < <(openstack --os-cloud admin server list \
        --all-projects --status ACTIVE -f value -c ID)
    if [[ ${#EXPECTED_INSTANCES[@]} -eq 0 ]]; then
        echo "ERROR: no running instance: section 5 would test nothing" >&2
        return 1
    fi
    # Only the floating IPs of the recorded instances: a floating IP on a
    # stopped server or a load balancer need not answer a ping. Listed
    # first, so that a failing list stops the script.
    fips=$(openstack --os-cloud admin floating ip list -f value -c "Floating IP Address" -c Port)
    # Read from fd 3: the commands in the loop would read stdin.
    while read -r ip port <&3; do
        [[ -n $port && $port != None ]] || continue
        server=$(openstack --os-cloud admin port show -f value -c device_id "$port")
        if [[ " ${EXPECTED_INSTANCES[*]} " == *" $server "* ]]; then
            EXPECTED_FIPS[$ip]=$server
        fi
    done 3<<<"$fips"
    echo "Running instances: ${EXPECTED_INSTANCES[*]}"
    echo "Floating IPs: ${!EXPECTED_FIPS[*]}"
}

migrate_all_instances() {
    local host
    for host in $(openstack --os-cloud admin compute service list --service nova-compute -f value -c Host); do
        osism manage compute migrate --yes --no-cold-migration "$host"
    done
}

# What running-guests of the last report asks for, one line each:
# "secrets <host>", "guest <uuid>", or "other <entity> <host>".
guest_failures() {
    python3 -c '
import json, re, sys
report = json.load(open(sys.argv[1]))
for t in report["validator_tests"]:
    if t["name"] != "running-guests":
        continue
    for row in t["data"] or []:
        if row["result"] != "failed":
            continue
        m = re.search(r"\(([0-9a-f-]{36})\)$", row["entity"])
        if row["entity"] == "secrets":
            print("secrets", row["location"])
        elif m:
            print("guest", m.group(1))
        else:
            print("other", row["entity"], row["location"])
' "$VALIDATE_REPORT"
}

# The number of passed guest rows of running-guests in the last report.
passed_guests() {
    python3 -c '
import json, re, sys
report = json.load(open(sys.argv[1]))
rows = [r for t in report["validator_tests"] if t["name"] == "running-guests" for r in t["data"] or []]
print(sum(1 for r in rows if r["result"] == "passed" and re.search(r"\([0-9a-f-]{36}\)$", r["entity"])))
' "$VALIDATE_REPORT"
}

# Section 5.
rotate_cinder_nova() {
    local round kind what where apply_nova
    log "Rotate client.cinder and client.nova"
    rotate_keys client.cinder,client.nova
    commit_keyrings "Rotate the keys of client.cinder and client.nova" required
    osism apply cinder
    osism apply nova
    migrate_all_instances
    for round in 1 2 3; do
        if validate_ceph_keys; then
            return 0
        fi
        [[ $(report_check running-guests) != skipped ]] || {
            echo "ERROR: running-guests was skipped: no compute hosts were checked" >&2
            return 1
        }
        log "Round $round: fix what running-guests names"
        apply_nova=false
        # Read from fd 3: osism would read stdin.
        while read -r kind what where <&3; do
            case $kind in
                secrets) apply_nova=true ;;
                guest) osism manage server migrate --yes "$what" ;;
                other) echo "ERROR: running-guests failed for $what on $where" >&2; return 1 ;;
            esac
        done 3< <(guest_failures)
        if [[ $apply_nova == true ]]; then
            osism apply nova
        fi
    done
    validate_ceph_keys
}

# The instances survived: still there, still reachable, and a new volume
# attaches (uses client.cinder and client.nova anew).
check_instances() {
    local id ip port volume name=rotation-check
    log "Check the instances"
    for id in "${EXPECTED_INSTANCES[@]}"; do
        wait_for ACTIVE 60 openstack --os-cloud admin server show -f value -c status "$id"
    done
    for ip in "${!EXPECTED_FIPS[@]}"; do
        port=$(openstack --os-cloud admin floating ip show -f value -c port_id "$ip")
        if [[ $(openstack --os-cloud admin port show -f value -c device_id "$port") != "${EXPECTED_FIPS[$ip]}" ]]; then
            echo "ERROR: floating IP $ip is no longer on server ${EXPECTED_FIPS[$ip]}" >&2
            return 1
        fi
        ping -c3 "$ip"
    done
    id=${EXPECTED_INSTANCES[0]}
    # The ID, not the name: a leftover of a failed run may carry the same name.
    volume=$(openstack --os-cloud admin volume create --size 1 -f value -c id "$name")
    wait_for available 300 openstack --os-cloud admin volume show -f value -c status "$volume"
    openstack --os-cloud admin server add volume "$id" "$volume"
    wait_for in-use 300 openstack --os-cloud admin volume show -f value -c status "$volume"
    openstack --os-cloud admin server remove volume "$id" "$volume"
    wait_for available 300 openstack --os-cloud admin volume show -f value -c status "$volume"
    openstack --os-cloud admin volume delete "$volume"

    validate_ceph_keys
    if [[ $(report_check running-guests) != passed ]]; then
        echo "ERROR: running-guests did not pass" >&2
        return 1
    fi
    if (($(passed_guests) < ${#EXPECTED_INSTANCES[@]})); then
        echo "ERROR: running-guests compared $(passed_guests) instances, ${#EXPECTED_INSTANCES[@]} were running" >&2
        return 1
    fi
}


preconditions() {
    local probe rc=0
    probe=$(docker exec osism-ansible sh -c \
        "if [ -e $ROTATE_PLAYBOOK ]; then echo present; else echo absent; fi" 2>&1) || rc=$?
    if [[ $rc -eq 0 && $probe == absent ]]; then
        echo "SKIP: cephadm-rotate-keys is not available in this manager release"
        exit 0
    fi
    if [[ $rc -ne 0 || $probe != present ]]; then
        echo "ERROR: cannot tell whether $ROTATE_PLAYBOOK exists in osism-ansible (rc $rc): $probe" >&2
        exit 1
    fi

    # Ask the cluster, not CEPH_STACK: that is fixed when the testbed is
    # created and stays ceph-ansible on a cluster migrated to cephadm.
    if ! ceph orch status 2>/dev/null | grep -qx 'Backend: cephadm'; then
        echo "ERROR: the rotation needs a cluster managed by cephadm:" >&2
        ceph orch status >&2 || true
        exit 1
    fi

    if ! git -C "$CONFIGURATION" rev-parse --git-dir >/dev/null 2>&1; then
        echo "ERROR: $CONFIGURATION is not a git checkout" >&2
        exit 1
    fi
}

main() {
    log "Preconditions"
    preconditions

    log "Cluster before the rotation"
    ceph versions
    ceph mon dump 2>/dev/null | grep '^auth_'
    ceph health detail

    log "Persist the keyrings of the deployment"
    commit_keyrings "Persist the Ceph keyrings of the deployment"

    log "Validate the keys of the deployment"
    if ! validate_ceph_keys; then
        # running-guests may fail here: a restart of the nova_libvirt container
        # without a key change, as an OSISM upgrade does, makes it name instances
        # that started before it (cephx key validation guide), and section 5
        # live-migrates every instance anyway. Every other check has to pass.
        local check
        for check in pending-keys old-key-type monitor-copies checkout; do
            if [[ $(report_check "$check") != passed ]]; then
                echo "ERROR: $check failed before the rotation" >&2
                exit 1
            fi
        done
        echo "running-guests failed before the rotation; section 5 migrates every instance."
        GUESTS_MAY_FAIL=true
    fi

    log "Record the running instances"
    record_instances

    # Upgrade guide "Move to the aes256k key type", step 1. Tested only by
    # hand (re-allowing aes on an aes256k-only cluster) until a lane starts
    # from aes keys.
    local migrate_cipher=false
    if old_cipher_allowed; then
        log "The monitors allow the old key type aes: move to aes256k"
        ceph mon set auth_preferred_cipher aes256k
        ceph config set mon mon_auth_allow_insecure_key false
        migrate_cipher=true
    else
        echo "Only aes256k is allowed, the key type stays as it is."
    fi

    log "Section 1: keys of services that are not run"
    delete_unused_service_keys

    log "Section 2: keys that never leave Ceph"
    rotate_keys crash,rgw,bootstrap
    rotate_keys lockbox
    validate_until_pass 600

    log "Section 4: keys of the OpenStack services and client.admin"
    local entity
    for entity in "${OPENSTACK_GROUPS[@]}"; do
        case $entity in
            client.glance) rotate_group "$entity" glance ;;
            client.cinder-backup) rotate_group "$entity" cinder ;;
            client.gnocchi) rotate_group "$entity" gnocchi ;;
            client.manila) rotate_group "$entity" manila ;;
        esac
    done
    rotate_group client.admin cephclient

    log "Section 5: client.cinder and client.nova"
    rotate_cinder_nova

    check_instances

    # Upgrade guide, step 3.
    if [[ $migrate_cipher == true ]]; then
        log "Disallow the old key type aes"
        validate_ceph_keys -e ceph_validate_strict=true
        ceph mon set auth_allowed_ciphers aes256k
        ceph mon dump 2>/dev/null | grep '^auth_'
        ceph health detail
    fi

    log "cephx key rotation done"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
