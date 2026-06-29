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
