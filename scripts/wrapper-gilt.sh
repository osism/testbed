#!/usr/bin/env bash

if [[ -e /opt/venv/bin/activate ]]; then
    source /opt/venv/bin/activate
fi

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

if [[ -e /opt/venv/bin/activate ]]; then
    deactivate
fi
