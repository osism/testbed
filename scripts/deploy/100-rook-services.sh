#!/usr/bin/env bash
set -e

source /opt/configuration/scripts/include.sh
source /opt/configuration/scripts/manager-version.sh

# check/deploy kubernetes
if command -v kubectl &> /dev/null; then
    K8S_READY_COUNT=$(kubectl get nodes | grep -c Ready)
    if [[ $K8S_READY_COUNT == 0 ]]; then
        /opt/configuration/scripts/deploy/500-kubernetes.sh
    fi
else
    /opt/configuration/scripts/deploy/500-kubernetes.sh
fi

# Make sure that no partitions are present
osism apply --environment custom wipe-partitions
osism apply facts

osism apply rook-operator
osism apply rook
osism apply rook-fetch-keys

echo "cephclient_install_type: rook" >> /opt/configuration/environments/infrastructure/configuration.yml
osism apply cephclient

CEPH_FSID=$(ceph fsid)
sed -i "s#ceph_cluster_fsid: .*#ceph_cluster_fsid: ${CEPH_FSID}#g" /opt/configuration/environments/configuration.yml
sed -i "s#fsid: .*#fsid: ${CEPH_FSID}#g" /opt/configuration/environments/ceph/configuration.yml

CEPH_MONS=$(kubectl --namespace rook-ceph get configmap rook-ceph-mon-endpoints -o jsonpath='{.data.data}' | sed 's/.=//g')
for fp in $(find /opt/configuration -name ceph.conf); do
    sed -i "s#fsid = .*#fsid = ${CEPH_FSID}#g" $fp
    sed -i "s#mon host = .*#mon host = ${CEPH_MONS}#g" $fp
done

CEPH_RGW_ADDRESS=$(kubectl get services -n rook-ceph rook-ceph-loadbalancer-rgw -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "ceph_rgw_hosts: [{host: rook, ip: $CEPH_RGW_ADDRESS, port: 80}]" >> /opt/configuration/environments/kolla/configuration.yml

# don't append "AUTH_%(project_id)s" to swift endpoint urls, rook implemented it without
sed --in-place --expression "s#^\(ceph_rgw_swift_account_in_url: \).*#\1false#g" /opt/configuration/environments/kolla/configuration.yml

CEPH_DASHBOARD_ADDRESS=$(kubectl get services -n rook-ceph rook-ceph-loadbalancer-dashboard -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "ceph_dashboard_address: $CEPH_DASHBOARD_ADDRESS" >> /opt/configuration/environments/kolla/configuration.yml

# workaround for https://github.com/osism/issues/issues/1141
ceph mgr module enable rook
ceph orch set backend rook
