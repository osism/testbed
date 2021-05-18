#!/usr/bin/env bash

packages='libmonitoring-plugin-perl libwww-perl libjson-perl monitoring-plugins mysql-client'
if ! dpkg -s $packages >/dev/null 2>&1; then
  sudo apt-get install -y $packages >/dev/null 2>&1
fi

pushd /opt/configuration/contrib > /dev/null

echo
echo "# Elasticsearch"
echo

bash nagios-plugins/check_elasticsearch -H api-int.osism.test

echo
echo "# MariaDB"
echo

bash nagios-plugins/check_galera_cluster -u root -p qNpdZmkKuUKBK3D5nZ08KMZ5MnYrGEe2hzH6XC0i -H api-int.osism.test -c 1

echo
echo "# RabbitMQ"
echo

perl nagios-plugins/check_rabbitmq_cluster -H api-int.osism.test -u openstack -p BO6yGAAq9eqA7IKqeBdtAEO7aJuNu4zfbhtnRo8Y

echo
echo "# Redis"
echo

/usr/lib/nagios/plugins/check_tcp -H 192.168.16.10 -p 6379 -A -E -s 'AUTH QHNA1SZRlOKzLADhUd5ZDgpHfQe6dNfr3bwEdY24\r\nPING\r\nINFO replication\r\nQUIT\r\n' -e 'PONG' -e 'role:master' -e 'slave0:ip=192.168.16.11,port=6379' -j

echo
echo "# Ceph"
echo

ceph -s

popd > /dev/null
