#!/usr/bin/env bash

for name in ceph-ansible kolla-ansible osism-ansible osism-kubernetes; do
    [[ ! -z "$(docker ps -a | grep $name )" ]] && docker exec -t $name bash -c "mv /ansible/ara.env /ansible/ara.env.disabled 2>/dev/null" || echo "ARA in $name already disabled."
done
