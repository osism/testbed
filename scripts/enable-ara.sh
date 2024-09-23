#!/usr/bin/env bash

for name in ceph-ansible kolla-ansible osism-ansible osism-kubernetes; do
    [[ ! -z "$(docker ps -a | grep $name )" ]] && docker exec -t $name bash -c "mv /ansible/ara.env.disabled /ansible/ara.env  2>/dev/null" || echo "ARA in $name already enabled."
done
