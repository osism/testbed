#!/usr/bin/env bash

docker exec -t ceph-ansible mv /ansible/ara.env /ansible/ara.env.disabled
docker exec -t kolla-ansible mv /ansible/ara.env /ansible/ara.env.disabled
docker exec -t osism-ansible mv /ansible/ara.env /ansible/ara.env.disabled
