#!/usr/bin/env bash

prepare() {
    openstack --os-cloud admin domain create scs-test-domain-a
    openstack --os-cloud admin domain create scs-test-domain-b

    openstack --os-cloud admin user create --domain scs-test-domain-b \
        --password "password" scs-test-domain-b-manager
    openstack --os-cloud admin user create --domain scs-test-domain-a \
        --password "password" scs-test-domain-a-manager

    openstack --os-cloud admin role add --user scs-test-domain-a-manager \
        --domain scs-test-domain-a manager
    openstack --os-cloud admin role add --user scs-test-domain-b-manager \
        --domain scs-test-domain-b manager
}

run() {
    pushd /tmp

    if [[ ! -e domain-manager-check.py ]]; then
        curl -q -o domain-manager-check.py https://raw.githubusercontent.com/SovereignCloudStack/standards/refs/heads/main/Tests/iam/domain-manager/domain-manager-check.py
    fi

    cat > clouds.yaml << EOF
clouds:
  domain-manager:
    auth:
      auth_url: ${KEYSTONE_AUTH_URL:-https://api.testbed.osism.xyz:5000/v3}
    cacert: /etc/ssl/certs/ca-certificates.crt
    identity_api_version: 3
EOF

    cat > domain-manager-test.yaml << 'EOF'
domains:
  - name: "scs-test-domain-a"
    manager:
      username: "scs-test-domain-a-manager"
      password: "password"
    member_role: "member"
  - name: "scs-test-domain-b"
    manager:
      username: "scs-test-domain-b-manager"
      password: "password"
    member_role: "member"
EOF

    uv run --with openstacksdk python domain-manager-check.py --os-cloud domain-manager
    uv run --with openstacksdk python domain-manager-check.py --os-cloud domain-manager --cleanup-only

    popd
}

cleanup() {
    openstack --os-cloud admin role remove --user scs-test-domain-a-manager \
        --domain scs-test-domain-a manager
    openstack --os-cloud admin role remove --user scs-test-domain-b-manager \
        --domain scs-test-domain-b manager

    openstack --os-cloud admin user delete --domain scs-test-domain-a \
        scs-test-domain-a-manager
    openstack --os-cloud admin user delete --domain scs-test-domain-b \
        scs-test-domain-b-manager

    openstack --os-cloud admin domain set --disable scs-test-domain-a
    openstack --os-cloud admin domain set --disable scs-test-domain-b
    openstack --os-cloud admin domain delete scs-test-domain-a
    openstack --os-cloud admin domain delete scs-test-domain-b
}

case "${1}" in
    prepare)
        prepare
        ;;
    run)
        run
        ;;
    cleanup)
        cleanup
        ;;
    *)
        prepare
        run
        cleanup
        ;;
esac
