export INTERACTIVE=false
export OSISM_APPLY_RETRY=1

wait_for_container_healthy() {
    local max_attempts="$1"
    local name="$2"
    local attempt_num=1

    until [[ "$(/usr/bin/docker inspect -f '{{.State.Health.Status}}' $name)" == "healthy" ]]; do
        if (( attempt_num++ == max_attempts )); then
            return 1
        else
            sleep 5
        fi
    done
}

sync_inventory() {
    # avoid overlaps with run_on_change
    sleep 10
    if [[ $(semver $MANAGER_VERSION 8.0.0) -ge 0 || $MANAGER_VERSION == "latest" ]]; then
        osism sync inventory
    else
        osism reconciler sync
    fi
}

# Move the manager service to MANAGER_VERSION, picking the entry point the
# target release actually ships.
#
# run.sh runs the manager play from the configuration repository and selects the
# osism/seed container by itself, but only from osism/generics v0.20260627.0 on.
# gilt.yml is pinned to the target release's generics_version by set-versions.py,
# so a release pinning an older generics delivers a run.sh that knows no
# container path and builds a local Ansible venv instead. Up to and including
# 10.1.0 (generics v0.20260615.0) that is every release, and all of them still
# ship the osism-update-manager wrapper, so use it there.
#
# ansible-collection-services#2154 removes that wrapper; the removal is in the
# collection from v0.20260806.0 on and no release pins it yet. Releases cut from
# here on carry both changes, so the newer branch is the one that stays.
update_manager() {
    if [[ $(semver $MANAGER_VERSION 10.1.0) -gt 0 || $MANAGER_VERSION == "latest" ]]; then
        /opt/configuration/environments/manager/run.sh manager
    else
        osism update manager
    fi
}

# Select the key-value store service for the active OpenStack release. Upstream
# kolla-ansible replaced redis with valkey at 2025.2; older releases still ship
# redis. The release is read from the kolla-ansible image label.
valkey_or_redis() {
    local openstack_version
    openstack_version=$(docker inspect --format '{{ index .Config.Labels "de.osism.release.openstack" }}' kolla-ansible 2>/dev/null)
    case "$openstack_version" in
        2023.*|2024.*|2025.1) echo redis ;;
        *) echo valkey ;;
    esac
}
