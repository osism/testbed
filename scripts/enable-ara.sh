#!/usr/bin/env bash

docker exec -t ceph-ansible mv /ansible/ara.env.disabled /ansible/ara.env || true
docker exec -t kolla-ansible mv /ansible/ara.env.disabled /ansible/ara.env || true
docker exec -t osism-ansible mv /ansible/ara.env.disabled /ansible/ara.env || true
