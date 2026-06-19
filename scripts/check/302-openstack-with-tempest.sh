#!/usr/bin/env bash
set -x
set -e
set -o pipefail

source /opt/manager-vars.sh

CEPH_VERSION=$(docker inspect --format '{{ index .Config.Labels "de.osism.release.ceph" }}' ceph-ansible 2>/dev/null || true)

echo
echo "# Tempest"
echo

if [[ ! -e /opt/tempest ]]; then
    osism apply tempest --skip-tags run-tempest

    sed -i "/log_dir =/d" /opt/tempest/etc/tempest.conf
    sed -i "/log_file =/d" /opt/tempest/etc/tempest.conf

    if [[ "${OPENSTACK_MINIMAL:-false}" == "true" ]]; then
        sed -i 's/tempest_roles = creator,/tempest_roles = /' /opt/tempest/etc/tempest.conf
    fi

    # Ceph RGW before Reef does not fully implement Swift temp URL and
    # container metadata removal semantics. Exclude those tests at setup
    # time so they do not count as failures; Reef and later pass them.
    if [[ $CEPH_VERSION == "octopus" || $CEPH_VERSION == "pacific" || $CEPH_VERSION == "quincy" ]]; then
        cat >> /opt/tempest/exclude.lst << 'EOF'
tempest.api.object_storage.test_container_services.ContainerTest.test_create_container_with_remove_metadata_key
tempest.api.object_storage.test_container_services.ContainerTest.test_create_container_with_remove_metadata_value
tempest.api.object_storage.test_object_temp_url.ObjectTempUrlTest.test_get_object_using_temp_url
tempest.api.object_storage.test_object_temp_url.ObjectTempUrlTest.test_get_object_using_temp_url_key_2
tempest.api.object_storage.test_object_temp_url.ObjectTempUrlTest.test_get_object_using_temp_url_with_inline_query_parameter
tempest.api.object_storage.test_object_temp_url.ObjectTempUrlTest.test_head_object_using_temp_url
tempest.api.object_storage.test_object_temp_url.ObjectTempUrlTest.test_put_object_using_temp_url
EOF
    fi

    # tempest 46.3.0 added a prefix-scoped TempURL test (temp_url_prefix=),
    # validated against Swift (tempest Launchpad bug 2142680:
    # https://bugs.launchpad.net/tempest/+bug/2142680). It is not portable to
    # RGW: it signs a hardcoded "/v1/<account>/..." path, but the request hits
    # the storage URL, which RGW serves under rgw_swift_url_prefix ("/swift"),
    # so RGW validates against "/swift/v1/..." and the signature never matches
    # (403). The other ObjectTempUrl tests pass because they sign the real
    # request path (urlparse(base_url).path), not a hardcoded one. Behaviour is
    # the same on Reef (18.2.8) and Squid (19.2.4) and depends on the /swift
    # prefix, not the Ceph release; exclude unconditionally until tempest (or
    # RGW, in rgw_swift_auth.cc PrefixableSignatureHelper) is fixed.
    cat >> /opt/tempest/exclude.lst << 'EOF'
tempest.api.object_storage.test_object_temp_url.ObjectTempUrlTest.test_get_object_using_temp_url_with_prefix
EOF
fi

_tempest() {
    local regex="$1"

    docker run --rm \
      -v /opt/tempest:/tempest \
      -v /etc/ssl/certs:/etc/ssl/certs:ro \
      -e PYTHONWARNINGS="ignore::SyntaxWarning" \
      --network host  \
      --name tempest \
      registry.osism.tech/osism/tempest:latest \
      run \
      --workspace-path /tempest/workspace.yaml \
      --workspace tempest  \
      --exclude-list /tempest/exclude.lst \
      --regex $1 \
      --concurrency 16 | tee -a /opt/tempest/$(date +%Y%m%d-%H%M).log
}

echo
echo "## IDENTITY (API)"
echo

_tempest "tempest.api.identity.v3"

echo
echo "## IMAGE (API)"
echo

_tempest "tempest.api.image.v2"

echo
echo "## NETWORK (API)"
echo

_tempest "tempest.api.network"

echo
echo "## VOLUME (API)"
echo

_tempest "tempest.api.volume"

echo
echo "## COMPUTE (API)"
echo

_tempest "tempest.api.compute"

echo
echo "## DNS (API)"
echo

_tempest "designate_tempest_plugin.tests.api.v2"

echo
echo "## OBJECT-STORE (API)"
echo

_tempest "tempest.api.object_storage"
