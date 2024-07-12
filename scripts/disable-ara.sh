#!/usr/bin/env bash

for name in ceph-ansible kolla-ansible osism-ansible osism-kubernetes; do
    [[ ! -z "$(docker ps -a | grep $name )" ]] && docker exec -t $name mv /ansible/ara.env /ansible/ara.env.disabled || echo "ARA in $name already disabled."
done
