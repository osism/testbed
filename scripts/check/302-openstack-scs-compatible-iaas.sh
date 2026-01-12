#!/usr/bin/env bash
set -x
set -e

echo
echo "# Tempest"
echo

if [[ ! -e /opt/tempest ]]; then
    osism apply tempest --skip-tags run-tempest

    sed -i "/log_dir =/d" /opt/tempest/etc/tempest.conf
    sed -i "/log_file =/d" /opt/tempest/etc/tempest.conf

    cp /opt/configuration/environments/openstack/files/tempest/include-scs-compatible-iaas.lst /opt/tempest/include-scs-compatible-iaas.lst
fi

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
  --include-list /tempest/include-scs-compatible-iaas.lst \
  --concurrency 16 | tee -a /opt/tempest/$(date +%Y%m%d-%H%M).log
