#!/usr/bin/env bash

if [[ $CEPH_STACK == "ceph-ansible" ]]; then
    docker exec -t ceph-ansible mv /ansible/ara.env /ansible/ara.env.disabled || true
fi
docker exec -t kolla-ansible mv /ansible/ara.env /ansible/ara.env.disabled || true
docker exec -t osism-ansible mv /ansible/ara.env /ansible/ara.env.disabled || true
