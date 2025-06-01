#!/usr/bin/env bash
set -x
set -e

echo
echo "# Tempest"
echo

osism apply tempest --skip-tags run-tempest

sed -i "/log_dir =/d" /opt/tempest/etc/tempest.conf
sed -i "/log_file =/d" /opt/tempest/etc/tempest.conf

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
echo "## IDENTITY"
echo

_tempest "tempest.api.identity.v3"

echo
echo "## IMAGE"
echo

_tempest "tempest.api.image.v2"

echo
echo "## NETWORK"
echo

_tempest "tempest.api.network"

echo
echo "## VOLUME"
echo

_tempest "tempest.api.volume"

echo
echo "## COMPUTE"
echo

_tempest "tempest.api.compute"
