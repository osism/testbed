#!/usr/bin/env bash

packages='libmonitoring-plugin-perl libwww-perl libjson-perl'
if ! dpkg -s $packages >/dev/null 2>&1; then
  sudo apt-get install -y $packages
fi

echo Elasticsearch   $(bash nagios-plugins/check_elasticsearch -H api-int.osism.local)
echo
echo MariaDB         $(bash nagios-plugins/check_galera_cluster -u root -p qNpdZmkKuUKBK3D5nZ08KMZ5MnYrGEe2hzH6XC0i -H api-int.osism.local)
echo
echo RabbitMQ        $(perl nagios-plugins/check_rabbitmq_cluster -H api-int.osism.local -u openstack -p BO6yGAAq9eqA7IKqeBdtAEO7aJuNu4zfbhtnRo8Y)
