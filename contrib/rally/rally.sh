#!/usr/bin/env bash

sudo mkdir -p /opt/rally
sudo chown dragon: /opt/rally

echo Installing rally, this may take a couple of minutes

INSTALL_LOG=/opt/rally/rally-install-$(date +%Y-%m-%d).log

sudo apt-get install -y python3-venv >>$INSTALL_LOG 2>&1

python3 -m venv /opt/rally/.venv >>$INSTALL_LOG 2>&1
source /opt/rally/.venv/bin/activate >>$INSTALL_LOG 2>&1
pip install rally-openstack >>$INSTALL_LOG 2>&1

echo Finished installing rally, starting tests

rally --config-file /opt/configuration/contrib/rally/rally.conf db create || rally --config-file /opt/configuration/contrib/rally/rally.conf db upgrade
rally --config-file /opt/configuration/contrib/rally/rally.conf env create --name osism --spec /opt/configuration/contrib/rally/rally.json 2>/dev/null >/dev/null || true
rally --config-file /opt/configuration/contrib/rally/rally.conf env check
rally --config-file /opt/configuration/contrib/rally/rally.conf task start \
    --task /opt/configuration/contrib/rally/tests/task.yml \
    --task-args-file /opt/configuration/contrib/rally/tests/task-arguments.yml
