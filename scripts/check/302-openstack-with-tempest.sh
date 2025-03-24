#!/usr/bin/env bash
set -x
set -e

echo
echo "# Tempest"
echo

osism apply tempest \
  --skip-tags run-tempest \
  -e tempest_enable_barbican=${TEMPEST_BARBICAN:-false} \
  -e tempest_enable_cinder=${TEMPEST_CINDER:-false} \
  -e tempest_enable_designate=${TEMPEST_DESIGNATE:-false} \
  -e tempest_enable_glance=${TEMPEST_GLANCE:-false} \
  -e tempest_enable_horizon=${TEMPEST_HORIZON:-false} \
  -e tempest_enable_neutron=${TEMPEST_NEUTRON:-false} \
  -e tempest_enable_nova=${TEMPEST_NOVA:-false} \
  -e tempest_enable_octavia=${TEMPEST_OCTAVIA:-false} \
  -e tempest_enable_swift=${TEMPEST_SWIFT:-false}

sed -i "/log_dir =/d" /opt/tempest/etc/tempest.conf
sed -i "/log_file =/d" /opt/tempest/etc/tempest.conf

docker run --rm \
  -v /opt/tempest:/tempest \
  -v /etc/ssl/certs:/etc/ssl/certs:ro \
  --network host  \
  --name tempest \
  quay.io/osism/tempest:latest \
  run \
  --workspace-path /tempest/workspace.yaml \
  --workspace tempest  \
  --exclude-list /tempest/exclude.lst \
  --concurrency 16 | tee -a /opt/tempest/$(date +%Y%m%d-%H%M).log
