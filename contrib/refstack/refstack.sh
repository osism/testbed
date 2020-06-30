#!/usr/bin/env bash

INTERACTIVE=false osism-run openstack bootstrap-basic
INTERACTIVE=false osism-run openstack bootstrap-refstack

# NOTE: create RGW user accounts
for username in refstack-0 refstack-1 refstack-2; do
    openstack --os-cloud $username container list
done

# NOTE: enable quota management on RGW user accounts
for username in $(radosgw-admin user list | grep \\$ | awk -F\" '{ print $2 }'); do
    radosgw-admin quota enable --uid "$username" --quota-scope=user
done

sudo mkdir -p /opt/refstack
sudo chown dragon: /opt/refstack

git clone https://opendev.org/osf/refstack-client.git /opt/refstack/client

pushd /opt/refstack/client
./setup_env
popd

GUIDELINE=${1:-2019.11}
TARGET=${2:-platform}

# NOTE: AccountQuotasNegativeTest.test_user_modify_quota and AccountQuotasTest.test_upload_valid_object
#       are not working with Ceph RGW

curl -s "https://refstack.openstack.org/api/v1/guidelines/$GUIDELINE/tests?target=$TARGET&type=required,advisory&alias=true&flag=true" \
    > /opt/refstack/test-list.txt

source /opt/refstack/client/.venv/bin/activate
/opt/refstack/client/refstack-client test -c /opt/configuration/contrib/refstack/tempest.conf --test-list /opt/refstack/test-list.txt -v -r osism
