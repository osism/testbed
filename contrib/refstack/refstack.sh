#!/usr/bin/env bash

INTERACTIVE=false osism-run openstack bootstrap-basic
INTERACTIVE=false osism-run openstack bootstrap-refstack

sudo mkdir -p /opt/refstack
sudo chown dragon: /opt/refstack

git clone https://github.com/openstack/refstack-client /opt/refstack/client

pushd /opt/refstack/client
./setup_env
popd

GUIDELINE=${1:-2019.11}
TARGET=${2:-platform}

# NOTE: AccountQuotasNegativeTest.test_user_modify_quota and AccountQuotasTest.test_upload_valid_object
#       are not working with Ceph RGW

curl -s "https://refstack.openstack.org/api/v1/guidelines/$GUIDELINE/tests?target=$TARGET&type=required,advisory&alias=true&flag=true" | \
    grep -v tempest.api.object_storage.test_account_quotas_negative.AccountQuotasNegativeTest.test_user_modify_quota | \
    grep -v tempest.api.object_storage.test_account_quotas.AccountQuotasTest.test_upload_valid_object | \
    grep -v tempest.api.identity.v3.test_projects.IdentityV3ProjectsTest.test_list_projects_returns_only_authorized_projects \
    > /opt/refstack/test-list.txt

source /opt/refstack/client/.venv/bin/activate
/opt/refstack/client/refstack-client test -c /opt/configuration/contrib/refstack/tempest.conf --test-list /opt/refstack/test-list.txt -v -r osism
