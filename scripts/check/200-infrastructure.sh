#!/usr/bin/env bash
set -x
set -e

source /opt/manager-vars.sh

# CentOS
if [[ -e /etc/redhat-release ]]; then
    exit 0
else
    # Ubuntu
    source /etc/os-release
    if [[ "$ID" == "ubuntu" ]]; then
        packages='libmonitoring-plugin-perl libwww-perl libjson-perl monitoring-plugins-basic mysql-client'
    # Debian
    elif [[ "$ID" == "debian" ]]; then
        packages='libmonitoring-plugin-perl libwww-perl libjson-perl monitoring-plugins-basic mariadb-client'
    fi

    if ! dpkg -s $packages >/dev/null 2>&1; then
        sudo apt-get install -y $packages >/dev/null 2>&1
    fi
fi

pushd /opt/configuration/contrib > /dev/null

echo
echo "# Status of Elasticsearch"
echo

bash nagios-plugins/check_elasticsearch -H api-int.testbed.osism.xyz -s

echo
echo "# Status of MariaDB"
echo

MARIADB_USER=root_shard_0
bash nagios-plugins/check_galera_cluster -u $MARIADB_USER -p password -H api-int.testbed.osism.xyz -c 1

echo
echo "# Status of Prometheus"
echo

curl -s https://api-int.testbed.osism.xyz:9091/-/healthy
curl -s https://api-int.testbed.osism.xyz:9091/-/ready

echo
echo "# Status of RabbitMQ"
echo

perl nagios-plugins/check_rabbitmq_cluster --ssl 1 -H api-int.testbed.osism.xyz -u openstack -p password

echo
echo "# Status of Redis"
echo

/usr/lib/nagios/plugins/check_tcp -H 192.168.16.10 -p 6379 -A -E -s 'AUTH QHNA1SZRlOKzLADhUd5ZDgpHfQe6dNfr3bwEdY24\r\nPING\r\nINFO replication\r\nQUIT\r\n' -e 'PONG' -e 'role:master' -e 'slave0:ip=192.168.16.1' -e',port=6379' -j

popd > /dev/null

echo
echo "# Create backup of MariaDB database"
echo

osism apply mariadb_backup -e mariadb_backup_type=full

# Disabled because of https://bugs.launchpad.net/kolla/+bug/2111620
# Can be re-enabled after backport of https://review.opendev.org/c/openstack/kolla/+/950948
# and the release of OSISM 9.1.1.
#
# osism apply mariadb_backup -e mariadb_backup_type=incremental
