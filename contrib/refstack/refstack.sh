#!/usr/bin/env bash

sudo mkdir -p /opt/refstack
sudo chown dragon: /opt/refstack

git clone https://github.com/openstack/refstack-client /opt/refstack/client

pushd /opt/refstack/client
./setup_env
popd

GUIDELINE=${1:-2019.11}

curl -s "https://refstack.openstack.org/api/v1/guidelines/$GUIDELINE/tests?target=compute&type=required,advisory&alias=true&flag=true" | \
    grep -v tempest.api.identity.v3.test_projects.IdentityV3ProjectsTest.test_list_projects_returns_only_authorized_projects | \
    grep -v "tempest.api.compute.servers.test_list_server_filters.ListServerFiltersTestJSON.test_list_servers_filtered_by_ip_regex" \
    > /opt/refstack/test-list.txt

source /opt/refstack/client/.venv/bin/activate
/opt/refstack/client/refstack-client test -c /opt/configuration/contrib/refstack/tempest.conf --test-list /opt/refstack/test-list.txt -v -r osism
