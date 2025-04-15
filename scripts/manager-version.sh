export MANAGER_VERSION=$(awk -F': ' '/^manager_version:/ { print $2 }' /opt/configuration/environments/manager/configuration.yml)
