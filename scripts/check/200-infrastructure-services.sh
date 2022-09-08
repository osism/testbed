#!/usr/bin/env bash
set -x
set -e

source /opt/manager-vars.sh

packages='libmonitoring-plugin-perl libwww-perl libjson-perl monitoring-plugins mysql-client'
if ! dpkg -s $packages >/dev/null 2>&1; then
  sudo apt-get install -y $packages >/dev/null 2>&1
fi

pushd /opt/configuration/contrib > /dev/null

echo
echo "# Status of Elasticsearch"
echo

bash nagios-plugins/check_elasticsearch -H api-int.testbed.osism.xyz -s

echo
echo "# Status of MariaDB"
echo

bash nagios-plugins/check_galera_cluster -u root -p password -H api-int.testbed.osism.xyz -c 1

if [[ "$DEPLOY_MONITORING" == "true" ]]; then
    echo
    echo "# Status of Prometheus"
    echo

    curl -s https://api-int.testbed.osism.xyz:9091/-/healthy
    curl -s https://api-int.testbed.osism.xyz:9091/-/ready
fi

echo
echo "# Status of RabbitMQ"
echo

perl nagios-plugins/check_rabbitmq_cluster --ssl 1 -H api-int.testbed.osism.xyz -u openstack -p BO6yGAAq9eqA7IKqeBdtAEO7aJuNu4zfbhtnRo8Y

echo
echo "# Status of Redis"
echo

/usr/lib/nagios/plugins/check_tcp -H 192.168.16.10 -p 6379 -A -E -s 'AUTH QHNA1SZRlOKzLADhUd5ZDgpHfQe6dNfr3bwEdY24\r\nPING\r\nINFO replication\r\nQUIT\r\n' -e 'PONG' -e 'role:master' -e 'slave0:ip=192.168.16.1' -e',port=6379' -j

popd > /dev/null
