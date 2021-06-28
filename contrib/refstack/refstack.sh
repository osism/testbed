#!/usr/bin/env bash

INSTALL_LOG=/opt/refstack/refstack-install-$(date +%Y-%m-%d).log

sudo mkdir -p /opt/refstack
sudo chown dragon: /opt/refstack

INTERACTIVE=false osism-run openstack bootstrap-basic >>$INSTALL_LOG 2>&1
INTERACTIVE=false osism-run openstack bootstrap-refstack >>$INSTALL_LOG 2>&1

# NOTE: create RGW user accounts
for username in refstack-0 refstack-1 refstack-2; do
    openstack --os-cloud $username container list >>$INSTALL_LOG 2>&1
done

# NOTE: enable quota management on RGW user accounts
for username in $(radosgw-admin user list | grep \\$ | awk -F\" '{ print $2 }'); do
    radosgw-admin quota enable --uid "$username" --quota-scope=user >>$INSTALL_LOG 2>&1
done

git clone https://opendev.org/osf/refstack-client.git /opt/refstack/client >>$INSTALL_LOG 2>&1

if [[ ! -e /opt/refstack/client/.venv ]]; then
    pushd /opt/refstack/client >>$INSTALL_LOG 2>&1
    ./setup_env >>$INSTALL_LOG 2>&1
    popd >>$INSTALL_LOG 2>&1
fi

GUIDELINE=${1:-2020.11}
TARGET=${2:-platform}

# NOTE: AccountQuotasNegativeTest.test_user_modify_quota and AccountQuotasTest.test_upload_valid_object
#       are not working with Ceph RGW

curl -s "https://refstack.openstack.org/api/v1/guidelines/$GUIDELINE/tests?target=$TARGET&type=required,advisory&alias=true&flag=true" \
    > /opt/refstack/test-list.txt

source /opt/refstack/client/.venv/bin/activate
/opt/refstack/client/refstack-client test -c /opt/configuration/contrib/refstack/tempest.conf --test-list /opt/refstack/test-list.txt -v -r osism
