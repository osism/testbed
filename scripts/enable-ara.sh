#!/usr/bin/env bash

if [[ $CEPH_STACK == "ceph-ansible" ]]; then
    docker exec -t ceph-ansible mv /ansible/ara.env.disabled /ansible/ara.env || true
fi
docker exec -t kolla-ansible mv /ansible/ara.env.disabled /ansible/ara.env || true
docker exec -t osism-ansible mv /ansible/ara.env.disabled /ansible/ara.env || true
