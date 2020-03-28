#!/usr/bin/env bash

docker exec -t manager_ceph-ansible_1 mv /ansible/ara.env /ansible/ara.env.disabled
docker exec -t manager_kolla-ansible_1 mv /ansible/ara.env /ansible/ara.env.disabled
docker exec -t manager_osism-ansible_1 mv /ansible/ara.env /ansible/ara.env.disabled
