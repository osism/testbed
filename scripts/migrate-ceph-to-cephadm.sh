#!/usr/bin/env bash
#
# Migrate the Ceph cluster from ceph-ansible to cephadm by following the
# cephadm migration guide of the OSISM documentation
# (docs/guides/migration-guide/cephadm/index.md), step by step. Each function
# is one step or part of a step of the guide, named as the guide names it.
#
# The script does what the guide says and nothing more: no fixes or retries
# the guide does not describe. Where the guide describes a wait in prose,
# the script waits with a time limit and fails with the step's name.
# A failure here is either a cluster problem or a defect of the guide.
#
# Deviations, because of the testbed only:
#   * The testbed's configuration already carries the dedicated cephadm SSH
#     key; of "The cephadm SSH key", only its two checks run.
#   * At the end, CEPH_STACK=cephadm is written to /opt/manager-vars.sh, so
#     that later testbed scripts take the cephadm path.
#
# STEP_FROM (default 0, the prerequisites) runs the steps from the given one
# on, e.g. STEP_FROM=5.5 starts at the crash daemons. It is meant for
# development and for resuming by hand; the upgrade lane never sets it.
#
# Never print a key: no set -x, and ceph auth ls only through the guide's
# entity filter.

set -e
set -o pipefail

STEP_FROM=${STEP_FROM:-0}
SECRETS=/opt/ansible/secrets
IMAGE_FILE=/home/dragon/migrate-ceph-image.txt

log() {
    echo
    echo "## $*"
    echo
}

fail() {
    echo "ERROR: $*" >&2
    exit 1
}

# Sets the variable named $2 to the hosts of inventory group $1, as the guide
# lists them. Not a $(...) on purpose: an empty list or a failing osism has to
# end the script, and an exit inside a command substitution ends only the
# subshell, leaving a loop over nothing that passes.
nodes_of() {
    local _hosts
    _hosts=$(osism get hosts -l "$1" | awk 'NR>3 && /\|/ {print $2}') || fail "osism get hosts -l $1 failed"
    [[ -n $_hosts ]] || fail "no hosts in inventory group $1"
    printf -v "$2" '%s' "$_hosts"
}

# Runs a script on every host of a group, one after the other, with the
# host's name in front of each line of output.
on_nodes() {
    local group=$1 script=$2 node nodes
    nodes_of "$group" nodes
    for node in $nodes; do
        # || return: under "on_nodes ... || fail" set -e is off in here.
        ssh -o StrictHostKeyChecking=no "$node" bash -s <<<"$script" 2>&1 | sed "s/^/$node: /" || return 1
    done
}

# Polls a command every 10 s until it succeeds; fails after the timeout.
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

# Runs a step if it is not before STEP_FROM.
run_step() {
    local id=$1 func=$2
    if [[ $(printf '%s\n%s\n' "$STEP_FROM" "$id" | sort -V | head -n1) == "$STEP_FROM" ]]; then
        "$func"
    else
        echo "skipping $id ($func): STEP_FROM=$STEP_FROM"
    fi
}

ceph_json() {
    ceph "$@" -f json 2>/dev/null
}

all_pgs_active_clean() {
    ceph_json pg stat | python3 -c '
import json, sys
s = json.load(sys.stdin)
s = s.get("pg_summary", s)
total = s["num_pgs"]
clean = sum(x["num"] for x in s["num_pg_by_state"] if x["name"] == "active+clean")
sys.exit(0 if total and clean == total else 1)'
}

health_ok() {
    [[ $(ceph health 2>/dev/null) == HEALTH_OK* ]]
}

# The migration starts from a cluster managed by ceph-ansible. A cluster that
# is already managed by cephadm fails: this run would test nothing.
preconditions() {
    if ceph orch status 2>/dev/null | grep -qx 'Backend: cephadm'; then
        fail "the cluster is already managed by cephadm; this script migrates a ceph-ansible cluster"
    fi
}

prerequisites() {
    log "Prerequisites"
    ceph -s
    health_ok || fail "Prerequisites: ceph -s does not report HEALTH_OK"
    ceph_json versions | python3 -c '
import json, re, sys
for v in json.load(sys.stdin)["overall"]:
    major = int(re.search(r"ceph version (\d+)\.", v).group(1))
    if major < 15:
        sys.exit("Prerequisites: %s is older than Octopus (15.2.x)" % v)'
    on_nodes ceph 'command -v python3 >/dev/null && dpkg -s lvm2 >/dev/null && echo "python3, lvm2: ok"'
    ssh_key_checks
}

ssh_key_checks() {
    log "Prerequisites: The cephadm SSH key, step 4 (checks)"
    if ! ssh-keygen -y -f "$SECRETS/id_rsa.ceph" >/dev/null; then
        fail "The cephadm SSH key: $SECRETS/id_rsa.ceph is not a usable private key"
    fi
    echo "key: ok"
    local node nodes
    nodes_of ceph nodes
    for node in $nodes; do
        if ! ssh -F /dev/null -i "$SECRETS/id_rsa.ceph" -o IdentitiesOnly=yes \
            -o BatchMode=yes -o StrictHostKeyChecking=no "dragon@${node}" true; then
            fail "The cephadm SSH key: the key does not log in to $node"
        fi
        echo "${node}: ok"
    done
}

step1() {
    log "Step 1: Verify cluster health"
    ceph -s
    ceph osd tree
    ceph df
    all_pgs_active_clean || fail "Step 1: not all PGs are active+clean"
    ceph_json osd tree | python3 -c '
import json, sys
bad = [n["name"] for n in json.load(sys.stdin)["nodes"]
       if n["type"] == "osd" and (n.get("status") != "up" or not n.get("reweight"))]
sys.exit("Step 1: OSDs not up or with REWEIGHT 0: %s" % bad if bad else 0)'
    ceph_json df | python3 -c '
import json, sys
used = json.load(sys.stdin)["stats"]["total_used_raw_ratio"]
sys.exit("Step 1: %%RAW USED is %.1f%%, not well below 85%%" % (used * 100) if used >= 0.85 else 0)'
}

step2() {
    log "Step 2: Install cephadm"
    ceph versions
    ceph_json versions | python3 -c '
import json, sys
overall = list(json.load(sys.stdin)["overall"])
if len(overall) != 1 or " reef " not in overall[0]:
    sys.exit("Step 2: this script follows the Reef (18.x) section; the cluster runs %s" % overall)'

    log "Step 2: Install cephadm — Reef (18.x)"
    # shellcheck disable=SC2016  # expanded on each node
    on_nodes ceph '
set -e
CEPH_RELEASE=$(docker exec $(docker ps --filter "name=ceph" --format "{{.Names}}" | head -1) ceph --version | awk "{print \$3}")
curl --fail --silent --remote-name --location https://raw.githubusercontent.com/ceph/ceph/v${CEPH_RELEASE}/src/cephadm/cephadm.py
sudo install -m 0755 -o root -g root cephadm.py /usr/sbin/cephadm
rm cephadm.py
sudo cephadm --help >/dev/null && echo "cephadm ${CEPH_RELEASE}: ok"'
}

step3() {
    log "Step 3: Prepare the cephadm configuration — cephadm prepare-host"
    on_nodes ceph 'sudo cephadm prepare-host 2>&1 | tail -n 3; sudo cephadm prepare-host 2>&1 | grep -q "Host looks OK"'

    log "Step 3: Prepare the cephadm configuration — container image"
    local mon_node ceph_image mons
    nodes_of ceph-mon mons
    mon_node=$(head -1 <<<"$mons")
    # shellcheck disable=SC2016  # expanded on the monitor node
    ceph_image=$(ssh "${mon_node}" "docker inspect \$(docker ps --filter 'name=ceph' --format '{{.Names}}' | head -1) --format '{{.Config.Image}}'")
    echo "Container image: ${ceph_image}"
    [[ $ceph_image == *ceph-daemon* ]] || fail "Step 3: unexpected container image '${ceph_image}'"
    # The RGW part of Step 5 chooses its command by "the container image Step 3
    # printed". cephadm replaces container_image with the image's digest once
    # it deploys services, so the printed value is kept here for that step.
    echo "${ceph_image}" > "$IMAGE_FILE"
    ceph config set global container_image "${ceph_image}"

    log "Step 3: Prepare the cephadm configuration — assimilate-conf"
    # shellcheck disable=SC2016  # expanded on the monitor node
    ssh "${mon_node}" 'docker exec ceph-crash-$(hostname) ceph config assimilate-conf -i /etc/ceph/ceph.conf'
}

step4() {
    log "Step 4: Configure cephadm"
    ceph mgr module enable cephadm
    ceph orch set backend cephadm
    ceph cephadm set-user dragon
    cp "$SECRETS/id_rsa.ceph" /opt/cephclient/data/
    ssh-keygen -y -f "$SECRETS/id_rsa.ceph" > /opt/cephclient/data/id_rsa.ceph.pub
    ceph cephadm set-priv-key -i /data/id_rsa.ceph
    ceph cephadm set-pub-key -i /data/id_rsa.ceph.pub
    rm /opt/cephclient/data/id_rsa.ceph*

    local node nodes
    nodes_of ceph nodes
    for node in $nodes; do
        ceph orch host add "${node}" "$(getent hosts "${node}" | awk '{print $1}')"
    done
    ceph orch host ls
    local want have
    want=$(wc -l <<<"$nodes")
    have=$(ceph_json orch host ls | python3 -c 'import json, sys; print(len(json.load(sys.stdin)))')
    ((have == want)) || fail "Step 4: $have of $want hosts registered"
}

# Step 5, warning: "Verify cluster health with ceph -s after each step. Do not
# proceed if ceph -s reports HEALTH_ERR or degraded/unavailable PGs."
health_gate() {
    local what=$1
    ceph -s
    wait_until 600 "$what: cluster without HEALTH_ERR and all PGs active+clean" no_err_all_clean
}

no_err_all_clean() {
    [[ $(ceph health 2>/dev/null) != HEALTH_ERR* ]] && all_pgs_active_clean
}

# The legacy container image of the node, as the guide determines it.
# shellcheck disable=SC2016  # expanded on the node
NODE_CEPH_IMAGE='CEPH_IMAGE=$(docker inspect $(docker ps --filter "name=ceph" --format "{{.Names}}" | head -1) --format "{{.Config.Image}}")'

mons_in_quorum() {
    ceph_json quorum_status | python3 -c '
import json, sys
q = json.load(sys.stdin)
sys.exit(0 if len(q["quorum_names"]) == len(q["monmap"]["mons"]) else 1)'
}

# The adopted daemon itself runs under cephadm (ceph orch ps), not only a count
# that the old daemon's stale map entry could still satisfy.
daemon_running() {
    local type=$1 node=$2
    ceph_json orch ps --daemon-type "$type" --refresh | python3 -c '
import json, sys
sys.exit(0 if any(d.get("hostname") == sys.argv[1] and d.get("status_desc") == "running"
                  for d in json.load(sys.stdin)) else 1)' "$node"
}

mon_back() {
    daemon_running mon "$1" && mons_in_quorum
}

mgr_back() {
    daemon_running mgr "$1" && mgrs_available "$2"
}

mgrs_available() {
    local want=$1
    ceph_json mgr dump | python3 -c '
import json, sys
m = json.load(sys.stdin)
n = (1 if m.get("available") else 0) + len(m.get("standbys", []))
sys.exit(0 if n >= int(sys.argv[1]) else 1)' "$want"
}

# ceph orch ps lists every daemon of the type as running (the orchestrator's
# view lags: the guide says to run --refresh again a minute later).
orch_daemons_running() {
    local type=$1 want=$2
    ceph_json orch ps --daemon-type "$type" --refresh | python3 -c '
import json, sys
d = json.load(sys.stdin)
running = [x for x in d if x.get("status_desc") == "running"]
sys.exit(0 if len(running) >= int(sys.argv[1]) else 1)' "$want"
}

step5_mons() {
    log "Step 5: Adopt daemons — Adopting monitor daemons"
    local node mons
    nodes_of ceph-mon mons
    for node in $mons; do
        echo "== ${node}"
        # shellcheck disable=SC2016  # expanded on the node
        ssh -o StrictHostKeyChecking=no "${node}" bash -s <<<"set -e
CEPH_HOSTNAME=\$(hostname)
$NODE_CEPH_IMAGE
sudo cephadm --image \${CEPH_IMAGE} adopt --style legacy --skip-firewalld --name mon.\${CEPH_HOSTNAME}
sudo systemctl reset-failed ceph-mon@\${CEPH_HOSTNAME}.service 2>/dev/null || true"
        # "The monitor remains available throughout -- the other monitors
        # maintain quorum while one is being adopted": the adopted one has to be
        # back in quorum before the next is stopped.
        wait_until 300 "Adopting monitor daemons: mon.${node} back in quorum" mon_back "${node}"
        health_gate "Adopting monitor daemons: ${node}"
    done
}

step5_mgrs() {
    log "Step 5: Adopt daemons — Adopting manager daemons"
    local node want mgrs
    nodes_of ceph-mgr mgrs
    want=$(wc -l <<<"$mgrs")
    for node in $mgrs; do
        echo "== ${node}"
        ssh -o StrictHostKeyChecking=no "${node}" bash -s <<<"set -e
CEPH_HOSTNAME=\$(hostname)
$NODE_CEPH_IMAGE
sudo cephadm --image \${CEPH_IMAGE} adopt --style legacy --skip-firewalld --name mgr.\${CEPH_HOSTNAME}
sudo systemctl reset-failed ceph-mgr@\${CEPH_HOSTNAME}.service 2>/dev/null || true"
        # "adopting one at a time ensures the cluster always has an active
        # manager available": the adopted one is back before the next.
        wait_until 300 "Adopting manager daemons: mgr.${node} back" mgr_back "${node}" "$want"
        health_gate "Adopting manager daemons: ${node}"
    done
}

step5_verify() {
    log "Step 5: Adopt daemons — Verify monitors and managers"
    local mons mgrs
    nodes_of ceph-mon mons
    nodes_of ceph-mgr mgrs
    wait_until 300 "Verify monitors and managers: all mon daemons running" \
        orch_daemons_running mon "$(wc -l <<<"$mons")"
    wait_until 300 "Verify monitors and managers: all mgr daemons running" \
        orch_daemons_running mgr "$(wc -l <<<"$mgrs")"
    ceph orch ls --refresh
    ceph orch ps --daemon-type mon
    ceph orch ps --daemon-type mgr
}

# The two conditions of the OSD warning under which a node's OSDs may be
# adopted in one loop: at least 3 OSD nodes, and host-level failure domain.
osd_loop_allowed() {
    local osds
    nodes_of ceph-osd osds
    (($(wc -l <<<"$osds") >= 3)) || return 1
    ceph_json osd crush rule dump | python3 -c '
import json, sys
types = {s.get("type") for r in json.load(sys.stdin) for s in r["steps"] if s["op"].startswith("chooseleaf")}
sys.exit(0 if types == {"host"} else 1)'
}

step5_osds() {
    log "Step 5: Adopt daemons — Adopting OSD daemons"
    ceph balancer status -f json | python3 -c "import json,sys; print(json.load(sys.stdin)['active'])" > /home/dragon/balancer_active.txt
    ceph osd set noout
    ceph osd set nodeep-scrub
    ceph balancer off

    local pool mode
    rm -f /home/dragon/autoscale_pools.txt
    for pool in $(ceph osd pool ls); do
        mode=$(ceph osd pool get "${pool}" pg_autoscale_mode -f json | python3 -c "import json,sys; print(json.load(sys.stdin)['pg_autoscale_mode'])")
        if [ "${mode}" = "on" ]; then
            echo "${pool}" >> /home/dragon/autoscale_pools.txt
            ceph osd pool set "${pool}" pg_autoscale_mode off
        fi
    done

    local per_osd=false node osd_id osd_ids
    if ! osd_loop_allowed; then
        echo "fewer than 3 OSD nodes or a failure domain other than host: adopting each OSD on its own"
        per_osd=true
    fi
    local osd_nodes
    nodes_of ceph-osd osd_nodes
    for node in $osd_nodes; do
        echo "== ${node}"
        osd_ids=$(ssh -o StrictHostKeyChecking=no "${node}" 'docker ps --filter "name=ceph-osd" --format "{{.Names}}"' | sed 's/ceph-osd-//')
        [[ -n $osd_ids ]] || fail "Adopting OSD daemons: no ceph-osd container on ${node}"
        for osd_id in $osd_ids; do
            ssh -o StrictHostKeyChecking=no "${node}" bash -s <<<"set -e
$NODE_CEPH_IMAGE
sudo cephadm --image \${CEPH_IMAGE} adopt --style legacy --skip-firewalld --name osd.${osd_id}
sudo systemctl reset-failed ceph-osd@${osd_id}.service 2>/dev/null || true"
            if [[ $per_osd == true ]]; then
                health_gate "Adopting OSD daemons: osd.${osd_id}"
            fi
        done
        # "After completing all OSDs on a node, wait until all PGs return to
        # active+clean before proceeding to the next node."
        health_gate "Adopting OSD daemons: ${node}"
    done

    wait_until 300 "Adopting OSD daemons: all OSD daemons running" \
        orch_daemons_running osd "$(ceph_json osd ls | python3 -c 'import json,sys; print(len(json.load(sys.stdin)))')"
    ceph orch ls --refresh
    ceph orch ps --daemon-type osd --refresh

    all_pgs_active_clean || fail "Adopting OSD daemons: not all PGs active+clean before removing the flags"
    ceph osd unset noout
    ceph osd unset nodeep-scrub
    if [ "$(cat /home/dragon/balancer_active.txt)" = "True" ]; then
        ceph balancer on
    fi
    rm /home/dragon/balancer_active.txt

    local failed=0
    if [ -f /home/dragon/autoscale_pools.txt ]; then
        while read -r pool <&3; do
            if ceph osd pool set "${pool}" pg_autoscale_mode on > /dev/null 2>&1; then
                echo "OK: ${pool}"
            else
                echo "FAILED: ${pool}"
                failed=1
            fi
        done 3< /home/dragon/autoscale_pools.txt
        # "Once all pools show OK, run: rm /home/dragon/autoscale_pools.txt"
        ((failed == 0)) || fail "Adopting OSD daemons: the PG autoscaler could not be re-enabled on every pool"
        rm /home/dragon/autoscale_pools.txt
    fi
}

step5_crash() {
    log "Step 5: Adopt daemons — Migrating crash daemons"
    # shellcheck disable=SC2016  # expanded on the node
    on_nodes ceph 'CEPH_HOSTNAME=$(hostname)
sudo systemctl stop ceph-crash@${CEPH_HOSTNAME}.service
sudo systemctl disable ceph-crash@${CEPH_HOSTNAME}.service'
    ceph orch apply crash
    local nodes
    nodes_of ceph nodes
    wait_until 300 "Migrating crash daemons: a crash daemon on every Ceph node" \
        orch_daemons_running crash "$(wc -l <<<"$nodes")"
    ceph orch ls
}

rgw_running_on() {
    ceph orch ps --daemon-type rgw --format json | python3 -c "
import json, sys
daemons = json.load(sys.stdin)
sys.exit(0 if any(d['hostname'] == '$1' and d.get('status_desc') == 'running' for d in daemons) else 1)
" 2>/dev/null
}

step5_rgw() {
    log "Step 5: Adopt daemons — Migrating RGW daemons"
    local rgw_nodes
    nodes_of ceph-rgw rgw_nodes
    echo "$rgw_nodes"
    radosgw-admin realm list
    radosgw-admin zonegroup list
    radosgw-admin zone list

    local cephconf=/opt/configuration/environments/ceph/configuration.yml
    if python3 -c "import sys, yaml; sys.exit(0 if (yaml.safe_load(open('$cephconf')) or {}).get('radosgw_frontend_ssl_certificate') else 1)"; then
        fail "Migrating RGW daemons: radosgw_frontend_ssl_certificate is set; this script does not cover the guide's SSL variant"
    fi

    local rgw_port first legacy
    rgw_port=$(python3 -c "import yaml; print((yaml.safe_load(open('$cephconf')) or {}).get('radosgw_frontend_port', 8081))")
    first=$(echo "$rgw_nodes" | head -1)
    legacy=$(ssh -o StrictHostKeyChecking=no "$first" "sudo ss -ltnp | grep radosgw" || true)
    echo "$legacy"
    grep -q ":${rgw_port} " <<<"$legacy" \
        || fail "Migrating RGW daemons: the legacy RGW on $first does not listen on port ${rgw_port}"

    log "Step 5: Migrating RGW daemons — Copy the RGW configuration for the new daemons"
    local OLD k
    OLD=$(ceph config dump -f json | python3 -c "import json,sys; print(sorted({e['section'] for e in json.load(sys.stdin) if e['name']=='rgw_keystone_url'})[0])")
    echo "Copying from ${OLD}"
    while read -r k <&3; do
        ceph config set client.rgw "$k" "$(ceph config get "$OLD" "$k")"
    done 3< <(ceph config dump -f json | python3 -c "import json,sys; [print(e['name']) for e in json.load(sys.stdin) if e['section']=='$OLD' and e['name'] not in ('rgw_frontends','log_file')]")

    log "Step 5: Migrating RGW daemons — Deploy the new RGW daemons"
    local RGW_REALM RGW_ZONE RGW_SERVICE_ID RGW_PLACEMENT RGW_NETWORKS node image
    RGW_REALM=$(radosgw-admin realm list --format json | python3 -c "import json,sys; print(json.load(sys.stdin)['realms'][0])" 2>/dev/null || echo "default")
    RGW_ZONE=$(radosgw-admin zone list --format json | python3 -c "import json,sys; print(json.load(sys.stdin)['zones'][0])" 2>/dev/null || echo "default")
    RGW_SERVICE_ID="${RGW_REALM}.${RGW_ZONE}"
    RGW_PLACEMENT=$(echo "$rgw_nodes" | paste -sd,)
    [[ -s $IMAGE_FILE ]] || fail "Deploy the new RGW daemons: $IMAGE_FILE (the image Step 3 printed) is missing"
    image=$(cat "$IMAGE_FILE")
    echo "Container image printed in Step 3: ${image}"
    if [[ $image =~ -r[0-9]+$ ]]; then
        RGW_NETWORKS=$(for node in ${RGW_PLACEMENT//,/ }; do
            osism get hostvars "${node}" radosgw_address | awk -F'|' 'NR==4 {gsub(/[ \047]/, "", $4); print $4 ($4 ~ /:/ ? "/128" : "/32")}'
        done | paste -sd,),$(ceph config get mon public_network)
        echo "${RGW_NETWORKS}"
        # "check the printed RGW_NETWORKS: one address per RGW node, each
        # different, then the public network"
        python3 -c "
import sys
nets = sys.argv[1].split(',')
nodes = len(sys.argv[2].split(','))
addrs = nets[:nodes]
ok = len(nets) == nodes + 1 and len(set(addrs)) == nodes and all(a.endswith(('/32', '/128')) for a in addrs)
sys.exit(0 if ok else 'Deploy the new RGW daemons: RGW_NETWORKS is not one address per RGW node, then the public network')
" "${RGW_NETWORKS}" "${RGW_PLACEMENT}"
        ceph orch apply rgw "${RGW_SERVICE_ID}" --placement="${RGW_PLACEMENT}" --port="${rgw_port}" --networks="${RGW_NETWORKS}"
    else
        ceph orch apply rgw "${RGW_SERVICE_ID}" --placement="${RGW_PLACEMENT}" --port="${rgw_port}"
    fi

    for node in $rgw_nodes; do
        echo "Stopping legacy RGW daemon on ${node}..."
        ssh -o StrictHostKeyChecking=no "${node}" "sudo systemctl stop ceph-radosgw.target; sudo systemctl disable ceph-radosgw.target"
        echo "Waiting for new RGW daemon on ${node}..."
        # "up to about a minute per node"
        wait_until 600 "Deploy the new RGW daemons: new RGW daemon on ${node} running" rgw_running_on "${node}"
        echo "New RGW daemon on ${node} is running."
    done
    ceph orch ps --daemon-type rgw
    if [[ -n ${RGW_NETWORKS:-} ]]; then
        # "Deployed with --networks, the PORTS column shows each daemon's
        # address ... It must be the node's radosgw_address."
        wait_until 300 "Deploy the new RGW daemons: each daemon bound to its node's radosgw_address" \
            rgw_bound_to_radosgw_address "${RGW_PLACEMENT}"
    fi

    local d apis url bad=0
    for d in $(ceph orch ps --daemon-type rgw --format json | python3 -c "import json,sys; [print(x['daemon_name']) for x in json.load(sys.stdin)]"); do
        apis=$(ceph config show "client.${d}" rgw_enable_apis)
        url=$(ceph config show "client.${d}" rgw_keystone_url)
        echo "${d}: ${apis} | ${url}"
        # Ceph's defaults: "an API list starting with s3, s3website and an
        # empty Keystone URL"
        if [[ -z $url || $apis == s3,\ s3website* || $apis == s3,s3website* ]]; then
            bad=1
        fi
    done
    ((bad == 0)) || fail "Deploy the new RGW daemons: a new RGW daemon runs with Ceph's defaults, not the deployment's configuration"
}

rgw_bound_to_radosgw_address() {
    local node addr ports
    for node in ${1//,/ }; do
        addr=$(osism get hostvars "${node}" radosgw_address | awk -F'|' 'NR==4 {gsub(/[ \047]/, "", $4); print $4}')
        ports=$(ceph orch ps --daemon-type rgw --refresh --format json | python3 -c "
import json, sys
print(' '.join(p for d in json.load(sys.stdin) if d['hostname'] == '${node}' for p in (d.get('ports') and [d.get('ip') or '*'] or [])))")
        echo "${node}: daemon address ${ports:-none}, radosgw_address ${addr}"
        [[ $ports == "$addr" ]] || return 1
    done
}

step5_mds() {
    log "Step 5: Adopt daemons — Migrating MDS daemons"
    ceph fs ls
    local CEPHFS_NAME MDS_PLACEMENT node mds_nodes
    CEPHFS_NAME=$(ceph fs ls --format json | python3 -c "import json,sys; print(json.load(sys.stdin)[0]['name'])")
    nodes_of ceph-mds mds_nodes
    MDS_PLACEMENT=$(paste -sd, <<<"$mds_nodes")
    ceph orch apply mds "${CEPHFS_NAME}" --placement="${MDS_PLACEMENT}"
    echo "Waiting for new MDS daemons..."
    wait_until 600 "Migrating MDS daemons: new MDS daemons running" \
        orch_daemons_running mds "$(wc -l <<<"$mds_nodes")"
    echo "New MDS daemons are running."
    ceph orch ls --service-type mds
    for node in $mds_nodes; do
        echo "Stopping legacy MDS daemon on ${node}..."
        ssh -o StrictHostKeyChecking=no "${node}" "sudo systemctl stop ceph-mds@${node}.service; sudo systemctl disable ceph-mds@${node}.service"
    done
}

all_daemons_running() {
    ceph_json orch ps --refresh | python3 -c '
import json, sys
d = json.load(sys.stdin)
sys.exit(0 if d and all(x.get("status_desc") == "running" for x in d) else 1)'
}

step6() {
    log "Step 6: Verify the migration"
    # Stopped legacy daemons stay "stray" until the orchestrator updates its
    # view ("Run ceph orch ps --refresh and check ceph -s again a minute later").
    wait_until 600 "Step 6: HEALTH_OK" eval 'ceph orch ps --refresh >/dev/null 2>&1; health_ok'
    ceph -s
    ceph orch ls
    ceph orch ps
    wait_until 300 "Step 6: all daemons running in ceph orch ps" all_daemons_running
    ceph_json orch ls | python3 -c '
import json, sys
bad = [s["service_name"] for s in json.load(sys.stdin)
       if s["service_type"] in ("crash", "mds", "rgw") and s.get("unmanaged")]
sys.exit("Step 6: crash, MDS or RGW services without a placement: %s" % bad if bad else 0)'
    ceph versions
    ceph_json versions | python3 -c '
import json, sys
overall = json.load(sys.stdin)["overall"]
sys.exit("Step 6: more than one version: %s" % list(overall) if len(overall) != 1 else 0)'
}

step7() {
    log "Step 7: Clean up ceph-ansible artifacts — 1. legacy systemd units"
    local fsid
    fsid=$(ceph fsid)
    # shellcheck disable=SC2016  # expanded on the node
    on_nodes ceph 'set -e
for target in ceph-mon ceph-mgr ceph-osd ceph-mds ceph-radosgw; do
    sudo systemctl disable ${target}.target 2>/dev/null || true
done
sudo find /etc/systemd/system -type l -name "ceph-radosgw@*.service" -delete
sudo rm -f /etc/systemd/system/ceph-mon@.service \
           /etc/systemd/system/ceph-mgr@.service \
           /etc/systemd/system/ceph-osd@.service \
           /etc/systemd/system/ceph-mds@.service \
           /etc/systemd/system/ceph-radosgw@.service \
           /etc/systemd/system/ceph-crash@.service \
           /etc/systemd/system/ceph-mon.target \
           /etc/systemd/system/ceph-mgr.target \
           /etc/systemd/system/ceph-osd.target \
           /etc/systemd/system/ceph-mds.target \
           /etc/systemd/system/ceph-radosgw.target
sudo systemctl daemon-reload
dangling=$(sudo find /etc/systemd/system -xtype l -name "ceph*")
[ -z "$dangling" ] || { echo "dangling links: $dangling"; exit 1; }
systemctl list-unit-files "ceph*" --state=enabled'
    # "the second lists ceph.target and ceph-<FSID>.target"
    on_nodes ceph "systemctl list-unit-files 'ceph*' --state=enabled | grep -q '^ceph-${fsid}.target' && systemctl list-unit-files 'ceph*' --state=enabled | grep -q '^ceph.target'" \
        || fail "Step 7: ceph.target or ceph-${fsid}.target not enabled on every node"

    log "Step 7: Clean up ceph-ansible artifacts — 2. legacy MDS and RGW data directories"
    # shellcheck disable=SC2016  # expanded on the node
    on_nodes ceph "sudo sh -c 'rm -rf /var/lib/ceph/mds/ceph-\$(hostname) /var/lib/ceph/radosgw/ceph-rgw.*'"

    log "Step 7: Clean up ceph-ansible artifacts — 3. cephx entities of replaced daemons"
    local entities e
    # The guide's filter: entity names only, never a key line.
    entities=$(ceph auth ls 2>/dev/null | grep -E '^(mds\.|client\.rgw\.|client\.crash$)' || true)
    echo "$entities"
    ceph orch ps --daemon-type mds
    ceph orch ps --daemon-type rgw
    # The legacy names: mds.<host>, client.rgw.<zone>.<host>.rgw<n>, client.crash.
    for e in $(grep -E '^(mds\.[^.]+|client\.rgw\..+\.rgw[0-9]+|client\.crash)$' <<<"$entities" || true); do
        echo "ceph auth del $e"
        ceph auth del "$e"
    done

    log "Step 7: Clean up ceph-ansible artifacts — 4. configuration sections of the legacy RGW daemons"
    local section name
    while read -r section name <&3; do
        ceph config rm "${section}" "${name}"
    done 3< <(ceph config dump -f json | python3 -c "import json,re,sys; [print(e['section'], e['name']) for e in json.load(sys.stdin) if re.fullmatch(r'client\.rgw\..+\.rgw[0-9]+', e['section'])]")

    log "Step 7: Clean up ceph-ansible artifacts — stale crash keyring"
    on_nodes ceph 'sudo rm -f /etc/ceph/ceph.client.crash.keyring'
    rm -f "$IMAGE_FILE"
}

# Testbed bookkeeping, not part of the guide: later testbed scripts read the
# Ceph backend from CEPH_STACK.
finish() {
    log "Testbed: CEPH_STACK=cephadm"
    if grep -q '^export CEPH_STACK=' /opt/manager-vars.sh; then
        sudo sed -i 's/^export CEPH_STACK=.*/export CEPH_STACK=cephadm/' /opt/manager-vars.sh
    else
        echo "export CEPH_STACK=cephadm" | sudo tee -a /opt/manager-vars.sh >/dev/null
    fi
    grep '^export CEPH_STACK=' /opt/manager-vars.sh
}

main() {
    if [[ $STEP_FROM == 0 ]]; then
        preconditions
    fi
    run_step 0 prerequisites
    run_step 1 step1
    run_step 2 step2
    run_step 3 step3
    run_step 4 step4
    run_step 5.1 step5_mons
    run_step 5.2 step5_mgrs
    run_step 5.3 step5_verify
    run_step 5.4 step5_osds
    run_step 5.5 step5_crash
    run_step 5.6 step5_rgw
    run_step 5.7 step5_mds
    run_step 6 step6
    run_step 7 step7
    finish
    log "Migration done"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi