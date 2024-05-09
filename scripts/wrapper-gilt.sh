#!/usr/bin/env bash

source /opt/venv/bin/activate
if [[ $1 == "set-versions" ]]; then
    pushd /opt/configuration/environments
    python3 set-versions.py
    popd
elif [[ $1 == "render-images" ]]; then
    pushd /opt/configuration/environments/manager
    python3 render-images.py
    popd
else
    echo "unsupported script $1"
fi
deactivate
