#!/usr/bin/env bash
set -x
set -e

pushd /opt/configuration

if [[ -e /opt/venv/bin/activate ]]; then
    source /opt/venv/bin/activate
fi

pip3 install --no-cache-dir python-gilt==1.2.3 requests
GILT=$(which gilt)
${GILT} overlay
${GILT} overlay

if [[ -e /opt/venv/bin/activate ]]; then
    deactivate
fi

popd
