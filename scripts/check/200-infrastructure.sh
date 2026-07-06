#!/usr/bin/env bash
set -x
set -e

source /opt/manager-vars.sh
source /opt/configuration/scripts/include.sh

packages='libmonitoring-plugin-perl libwww-perl libjson-perl monitoring-plugins-basic mariadb-client'

if ! dpkg -s $packages >/dev/null 2>&1; then
    sudo apt-get install -y $packages >/dev/null 2>&1
fi

pushd /opt/configuration/contrib > /dev/null

failures=0

run_check() {
    local name="$1"

    shift

    if ! "$@"; then
        echo
        echo "ERROR: $name check failed"
        failures=$((failures + 1))
    fi
}

echo
echo "# Status of Elasticsearch"
echo

run_check "Elasticsearch" bash nagios-plugins/check_elasticsearch -H api-int.testbed.osism.xyz -s

echo
echo "# Status of MariaDB"
echo

if [[ $(semver $MANAGER_VERSION 10.0.0-0) -ge 0 || $MANAGER_VERSION == "latest" ]]; then
    run_check "MariaDB" osism status database
else
    MARIADB_USER=root_shard_0
    run_check "MariaDB" bash nagios-plugins/check_galera_cluster -u $MARIADB_USER -p password -H api-int.testbed.osism.xyz -c 1
fi

echo
echo "# Status of Prometheus"
echo

run_check "Prometheus healthy" curl -s https://api-int.testbed.osism.xyz:9091/-/healthy
run_check "Prometheus ready" curl -s https://api-int.testbed.osism.xyz:9091/-/ready

echo
echo "# Status of RabbitMQ"
echo

if [[ $(semver $MANAGER_VERSION 10.0.0-0) -ge 0 || $MANAGER_VERSION == "latest" ]]; then
    run_check "RabbitMQ" osism status messaging
else
    run_check "RabbitMQ" perl nagios-plugins/check_rabbitmq_cluster --ssl 1 -H api-int.testbed.osism.xyz -u openstack -p password
fi

# The key-value store switched from redis to valkey at OpenStack 2025.2. Select
# the active service (same as deploy/upgrade) and read its master password from
# secrets.yml so the check tracks the deployed service instead of a hardcoded
# redis-era password.
key_value_store=$(valkey_or_redis)
key_value_store_password=$(awk -v k="${key_value_store}_master_password:" '$1 == k {print $2}' /opt/configuration/environments/kolla/secrets.yml)

echo
echo "# Status of ${key_value_store^}"
echo

run_check "${key_value_store^}" /usr/lib/nagios/plugins/check_tcp -H 192.168.16.10 -p 6379 -A -E -s "AUTH ${key_value_store_password}\r\nPING\r\nINFO replication\r\nQUIT\r\n" -e 'PONG' -e 'role:master' -e 'slave0:ip=192.168.16.1' -e',port=6379' -j

popd > /dev/null

if [[ $failures -gt 0 ]]; then
    echo
    echo "ERROR: $failures infrastructure status check(s) failed"
    exit 1
fi

echo
echo "# Create backup of MariaDB database"
echo

# mariabackup in the kolla mariadb-server:10.11.x image does not recognise
# the server version string produced by MariaDB 10.11.10 builds
# (e.g. '10.11.10-MariaDB-ubu2204-log'), causing the backup to fail with
# "Unsupported server version". Skip the backup check for 8.x; it works
# correctly on 9.0.0+ which uses MariaDB 11.x kolla images.
if [[ $(semver $MANAGER_VERSION 9.0.0) -ge 0 || $MANAGER_VERSION == "latest" ]]; then
    osism apply mariadb_backup -e mariadb_backup_type=full
fi

# Disabled because of https://bugs.launchpad.net/kolla/+bug/2111620
# Can be re-enabled after backport of https://review.opendev.org/c/openstack/kolla/+/950948
# and the release of OSISM 9.1.1.
#
# osism apply mariadb_backup -e mariadb_backup_type=incremental
