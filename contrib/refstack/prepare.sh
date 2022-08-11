#!/usr/bin/env bash

PYTHON_VERSION=3.8

# NOTE: This is the version used in setup_env of refstack-client
TEMPEST_VERSION=29.0.0

INSTALL_LOG=/opt/refstack/refstack-install-$(date +%Y-%m-%d).log

sudo mkdir -p /opt/refstack
sudo chown dragon: /opt/refstack

INTERACTIVE=false osism apply --environment openstack bootstrap-refstack >>$INSTALL_LOG 2>&1

# NOTE: create RGW user accounts
for username in refstack-0 refstack-1 refstack-2 refstack-3 refstack-4; do
    openstack --os-cloud $username container list >>$INSTALL_LOG 2>&1
done

# NOTE: enable quota management on RGW user accounts
for username in $(radosgw-admin user list | grep \\$ | awk -F\" '{ print $2 }'); do
    radosgw-admin quota enable --uid "$username" --quota-scope=user >>$INSTALL_LOG 2>&1
done

git clone https://opendev.org/osf/refstack-client.git /opt/refstack/client >>$INSTALL_LOG 2>&1

if [[ ! -e /opt/refstack/client/.venv ]]; then
    pushd /opt/refstack/client >>$INSTALL_LOG 2>&1
    ./setup_env -p $PYTHON_VERSION -t $TEMPEST_VERSION >>$INSTALL_LOG 2>&1
    popd >>$INSTALL_LOG 2>&1

    # NOTE: Tempest with jsonschema > 4.0.0 does not work, therefore explicit downgrade to < 4.0.0
    #       AttributeError: module jsonschema has no attribute compat
    source /opt/refstack/client/.tempest/.venv/bin/activate
    pip3 install jsonschema==3.2.0 >>$INSTALL_LOG 2>&1

    pip3 install heat-tempest-plugin==1.4.0 >>$INSTALL_LOG 2>&1
    pip3 install designate-tempest-plugin==0.12.0  >>$INSTALL_LOG 2>&1
fi

GUIDELINE=${1:-2020.11}
TARGET=${2:-platform}

# platform or compute

curl -s "https://refstack.openstack.org/api/v1/guidelines/$GUIDELINE/tests?target=$TARGET&type=required,advisory&alias=true&flag=true" \
    > /opt/refstack/test-list.txt

# dns

curl -s "https://refstack.openstack.org/v1/guidelines/dns.${GUIDELINE}.json/tests?target=dns&type=required&alias=true&flag=false" \
    >> /opt/refstack/test-list.txt

# orchestration

curl -s "https://refstack.openstack.org/v1/guidelines/orchestration.${GUIDELINE}.json/tests?target=orchestration&type=required&alias=true&flag=false" \
    >> /opt/refstack/test-list.txt

# shared file system
# NOTE: Manila currently not functional, therefore not activated
# curl -s "https://refstack.openstack.org/v1/guidelines/shared_file_system.${GUIDELINE}.json/tests?target=shared_file_system&type=required&alias=true&flag=false" \
#    >> /opt/refstack/test-list.txt

# NOTE: inject testbed CA into the virtual python environments
for fp in $(find /opt/refstack/client -name cacert.pem); do
    cat /opt/configuration/environments/kolla/certificates/ca/testbed.crt >> $fp
done
