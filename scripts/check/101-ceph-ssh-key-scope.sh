#!/usr/bin/env bash
set -x
set -e

source /opt/manager-vars.sh

# The dedicated cephadm SSH key is only worth having if it is scoped. Two
# things have to hold, and neither is visible without looking:
#
#   * the key is authorized on the Ceph hosts -- otherwise cephadm cannot
#     reach them, which surfaces later as an unrelated-looking failure;
#   * the key is authorized NOWHERE ELSE -- otherwise it is a second
#     fleet-wide key and the whole point of a dedicated one is gone.
#
# The second is the one nothing else catches. A key that leaks onto a
# non-Ceph host breaks nothing and is invisible on a running deployment,
# because authorizations already on disk outlive a wrong contract; it only
# shows up on a freshly provisioned host. The testbed provisions fresh hosts
# every run, which makes it the right place to assert it.
#
# The first is caught implicitly -- if operator_additional_authorized_keys
# ever replaced operator_authorized_keys instead of adding to it, the Ceph
# hosts would lose the deployment-wide keys and every later play would fail
# to reach them -- but it is asserted here too, so a failure names the cause
# instead of appearing as a broken SSH connection.

CEPH_KEY_FILE=/opt/ansible/secrets/id_rsa.ceph
CEPH_PUBKEY_FILE=/opt/ansible/secrets/id_rsa.ceph.pub

# Releases whose manager role has no `ceph` entry in private_keys never write
# the private half, and their operator role does not read
# operator_additional_authorized_keys either -- so on those there is nothing to
# check and the key is expected to be authorized nowhere.
#
# Probing for the file rather than comparing MANAGER_VERSION is deliberate. The
# property this check needs is "does this deployment's manager role know about
# the ceph key", and the file is that property directly; a version comparison
# would need a release number that does not exist yet when this lands, and would
# then have to be kept correct forever. This gate also disappears on its own once
# every deployable release writes the file.
if [[ ! -e $CEPH_KEY_FILE ]]; then
    echo "SKIP: $CEPH_KEY_FILE is absent -- this manager release predates the dedicated Ceph key"
    exit 0
fi

if [[ ! -e $CEPH_PUBKEY_FILE ]]; then
    echo "ERROR: $CEPH_PUBKEY_FILE is missing; the dedicated Ceph key was never staged"
    exit 1
fi

# Compare on the key material only. authorized_keys entries may carry options
# or a differing comment, and the operator role writes them through
# ansible.posix.authorized_key, which does not preserve the source formatting.
CEPH_PUBKEY=$(awk '{print $2}' "$CEPH_PUBKEY_FILE")

if [[ -z $CEPH_PUBKEY ]]; then
    echo "ERROR: could not read the key material from $CEPH_PUBKEY_FILE"
    exit 1
fi

authorized_on() {
    # Print the number of authorized_keys entries on $1 carrying the key.
    ssh -o StrictHostKeyChecking=no "$1" \
        "grep -c -F '$CEPH_PUBKEY' ~/.ssh/authorized_keys 2>/dev/null || true"
}

failures=0

# Resolve the Ceph hosts up front, and fail rather than check nothing.
#
# `set -e` does not cover this: the exit status of a command substitution in a
# `for` word list is discarded, so a failing `osism get hosts` would simply
# produce an empty list and the loop would run zero times. The manager check
# below would then pass -- the key is correctly absent there -- and the script
# would report success having verified nothing. `set -o pipefail` does not help
# either, for the same reason: the status is discarded whatever it is.
#
# The empty check is not only about the command failing. The awk contract below
# depends on the table layout of `osism get hosts` (skip the header, take the
# second column), so a change in that output produces an empty list from a
# successful command. Both causes have the same remedy: refuse to continue.
if ! ceph_hosts=$(osism get hosts -l ceph); then
    echo "ERROR: could not retrieve the Ceph host inventory"
    exit 1
fi

ceph_hosts=$(printf '%s\n' "$ceph_hosts" | awk 'NR>3 && /\|/ {print $2}')

if [[ -z $ceph_hosts ]]; then
    echo "ERROR: the Ceph host list is empty; expected the hosts of the ceph group"
    exit 1
fi

# Present on every Ceph host.
for node in $ceph_hosts; do
    count=$(authorized_on "$node")
    if [[ ${count:-0} -lt 1 ]]; then
        echo "ERROR: the dedicated Ceph key is NOT authorized on $node"
        failures=$((failures + 1))
    fi
done

# Absent everywhere else. The manager is always outside the ceph group
# (inventory/20-roles puts only ceph-control and ceph-resource in it), so it
# is a standing negative control that needs no special deployment shape.
for node in testbed-manager; do
    count=$(authorized_on "$node")
    if [[ ${count:-0} -ne 0 ]]; then
        echo "ERROR: the dedicated Ceph key leaked onto $node, which is not a Ceph host"
        failures=$((failures + 1))
    fi
done

if [[ $failures -gt 0 ]]; then
    echo
    echo "ERROR: $failures Ceph SSH key scope check(s) failed"
    exit 1
fi

echo "Ceph SSH key scope OK"
