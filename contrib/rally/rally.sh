#!/usr/bin/env bash

sudo mkdir -p /opt/rally
sudo chown dragon: /opt/rally

INSTALL_LOG=/opt/rally/rally-install-$(date +%Y-%m-%d).log

sudo apt-get install -y virtualenv >>$INSTALL_LOG 2>&1

virtualenv -p python3 /opt/rally/.venv >>$INSTALL_LOG 2>&1
source /opt/rally/.venv/bin/activate >>$INSTALL_LOG 2>&1
pip3 install rally-openstack >>$INSTALL_LOG 2>&1

# 2020-09-30 20:46:34.065 12177 WARNING rally.common.plugin.discover [-]        Failed to load plugins
# from module 'rally_openstack' (package: 'rally-openstack 2.0.0'): (importlib-metadata 2.0.0
# (/opt/rally/.venv/lib/python3.6/site-packages), Requirement.parse('importlib-metadata<2,>=0.12;
# python_version < "3.8"'), {'virtualenv'}): pkg_resources.ContextualVersionConflict: (importlib-metadata
# 2.0.0 (/opt/rally/.venv/lib/python3.6/site-packages), Requirement.parse('importlib-metadata<2,>=0.12;
# python_version < "3.8"'), {'virtualenv'})
# Platform openstack not found

pip3 install "importlib-metadata<2,>=0.12" >>$INSTALL_LOG 2>&1

rally --config-file /opt/configuration/contrib/rally/rally.conf db create || rally --config-file /opt/configuration/contrib/rally/rally.conf db upgrade
rally --config-file /opt/configuration/contrib/rally/rally.conf env create --name osism --spec /opt/configuration/contrib/rally/rally.json 2>/dev/null >/dev/null || true
rally --config-file /opt/configuration/contrib/rally/rally.conf env check
rally --config-file /opt/configuration/contrib/rally/rally.conf task start \
    --task /opt/configuration/contrib/rally/tests/task.yml \
    --task-args-file /opt/configuration/contrib/rally/tests/task-arguments.yml
