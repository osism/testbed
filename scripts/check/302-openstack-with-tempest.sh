#!/usr/bin/env bash
set -x
set -e

echo
echo "# Tempest"
echo

osism apply tempest --skip-tags run-tempest

sed -i "/log_dir =/d" /opt/tempest/etc/tempest.conf
sed -i "/log_file =/d" /opt/tempest/etc/tempest.conf

docker run --rm \
  -v /opt/tempest:/tempest \
  -v /etc/ssl/certs:/etc/ssl/certs:ro \
  --network host  \
  --name tempest \
  registry.osism.tech/osism/tempest:latest \
  run \
  --workspace-path /tempest/workspace.yaml \
  --workspace tempest  \
  --exclude-list /tempest/exclude.lst \
  --concurrency 16 | tee -a /opt/tempest/$(date +%Y%m%d-%H%M).log
