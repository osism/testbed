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
  quay.io/osism/tempest:latest \
  run \
  --workspace-path /tempest/workspace.yaml \
  --workspace tempest \
  --serial \
  --regex '^tempest\.scenario\..*$|^barbican_tempest_plugin\.tests\.scenario.*$|^designate_tempest_plugin\.tests\.scenario\..*$|^octavia_tempest_plugin\.tests\.scenario\.v2\..*$' \
  --exclude-regex '^tempest\.scenario\.test_server_volume_attachment\.TestServerVolumeAttachScenarioOldVersion\.test_old_versions_reject.*$|^tempest\.scenario\.test_server_volume_attachment\.TestServerVolumeAttachmentScenario\.test_server_detach_rules.*$|^barbican_tempest_plugin\.tests\.scenario\.test_image_signing\.ImageSigningTest\.test_signed_image_upload_boot_failure.*$'
