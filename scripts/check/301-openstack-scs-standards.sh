#!/usr/bin/env bash

CLOUD_NAME="scs-standards"
STANDARDS_DIR="/tmp/scs-standards"
TESTS_DIR="$STANDARDS_DIR/Tests"

DOMAIN_NAME="scs-standards"
PROJECT_NAME="scs-standards"
USER_NAME="scs-standards"
USER_PASSWORD="password"

prepare() {
    openstack --os-cloud admin domain create "$DOMAIN_NAME"
    openstack --os-cloud admin project create --domain "$DOMAIN_NAME" "$PROJECT_NAME"
    openstack --os-cloud admin user create --domain "$DOMAIN_NAME" \
        --password "$USER_PASSWORD" "$USER_NAME"
    openstack --os-cloud admin role add --user "$USER_NAME" --user-domain "$DOMAIN_NAME" \
        --project "$PROJECT_NAME" --project-domain "$DOMAIN_NAME" member

    if [[ ! -d "$STANDARDS_DIR" ]]; then
        git clone https://github.com/SovereignCloudStack/standards "$STANDARDS_DIR"
    fi

    pushd "$TESTS_DIR"
    uv venv
    uv pip install -r iaas/requirements.txt
    sed -i '1s|#!/usr/bin/env python3|#!'"$TESTS_DIR"'/.venv/bin/python|' iaas/openstack_test.py
    popd

    cat > "$TESTS_DIR/clouds.yaml" << EOF
clouds:
  $CLOUD_NAME:
    auth:
      auth_url: ${KEYSTONE_AUTH_URL:-https://api.testbed.osism.xyz:5000/v3}
      username: $USER_NAME
      password: $USER_PASSWORD
      project_name: $PROJECT_NAME
      project_domain_name: $DOMAIN_NAME
      user_domain_name: $DOMAIN_NAME
    cacert: /etc/ssl/certs/ca-certificates.crt
    identity_api_version: 3
EOF
}

run() {
    pushd "$TESTS_DIR"
    uv run python scs-compliance-check.py -s "$CLOUD_NAME" -a os_cloud="$CLOUD_NAME" scs-compatible-iaas.yaml
    popd
}

cleanup() {
    openstack --os-cloud admin user delete --domain "$DOMAIN_NAME" "$USER_NAME"
    openstack --os-cloud admin project delete --domain "$DOMAIN_NAME" "$PROJECT_NAME"
    openstack --os-cloud admin domain set --disable "$DOMAIN_NAME"
    openstack --os-cloud admin domain delete "$DOMAIN_NAME"

    rm -rf "$STANDARDS_DIR"
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
