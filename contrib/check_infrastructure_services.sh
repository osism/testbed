#!/usr/bin/env bash

echo Elasticsearch
echo
bash nagios-plugins/check_elasticsearch -H api-int.osism.local

echo
echo MariaDB
echo
bash nagios-plugins/check_galera_cluster -u root -p qNpdZmkKuUKBK3D5nZ08KMZ5MnYrGEe2hzH6XC0i -H api-int.osism.local

echo
echo RabbitMQ
echo
perl nagios-plugins/check_rabbitmq_cluster -H api-int.osism.local -u openstack -p BO6yGAAq9eqA7IKqeBdtAEO7aJuNu4zfbhtnRo8Y
