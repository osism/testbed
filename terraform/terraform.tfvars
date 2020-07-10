user_data_manager = <<-EOT
#cloud-config
package_update: true
package_upgrade: false
packages:
  - ifupdown
write_files:
  - content: |
      import subprocess
      import netifaces

      PORTS = {
          "${openstack_networking_port_v2.manager_port_internal.mac_address}": "${openstack_networking_port_v2.manager_port_internal.all_fixed_ips[0]}",
          "${openstack_networking_port_v2.manager_port_external.mac_address}": "${openstack_networking_port_v2.manager_port_external.all_fixed_ips[0]}",
          "${openstack_networking_port_v2.manager_port_provider.mac_address}": "${openstack_networking_port_v2.manager_port_provider.all_fixed_ips[0]}",
          "${openstack_networking_port_v2.manager_port_storage_frontend.mac_address}": "${openstack_networking_port_v2.manager_port_storage_frontend.all_fixed_ips[0]}",
      }

      for interface in netifaces.interfaces():
          mac_address = netifaces.ifaddresses(interface)[netifaces.AF_LINK][0]['addr']
          if mac_address in PORTS:
              subprocess.run("ip addr add %s/24 dev %s" % (PORTS[mac_address], interface), shell=True)
              subprocess.run("ip link set up dev %s" % interface, shell=True)
    path: /root/configure-network-devices.py
    permissions: 0600
  - content: ${openstack_compute_keypair_v2.key.public_key}
    path: /home/ubuntu/.ssh/id_rsa.pub
    permissions: 0600
  - content: |
      ${indent(6, openstack_compute_keypair_v2.key.private_key)}
    path: /home/ubuntu/.ssh/id_rsa
    permissions: 0600
  - content: |
      #!/usr/bin/env bash

      echo '* libraries/restart-without-asking boolean true' | debconf-set-selections

      apt-get install --yes python3-netifaces
      python3 /root/configure-network-devices.py

      chown -R ubuntu:ubuntu /home/ubuntu/.ssh

      add-apt-repository --yes ppa:ansible/ansible
      apt-get install --yes ansible

      ansible-galaxy install git+https://github.com/osism/ansible-chrony
      ansible-galaxy install git+https://github.com/osism/ansible-common
      ansible-galaxy install git+https://github.com/osism/ansible-docker
      ansible-galaxy install git+https://github.com/osism/ansible-docker-compose
      ansible-galaxy install git+https://github.com/osism/ansible-operator
      ansible-galaxy install git+https://github.com/osism/ansible-repository
      ansible-galaxy install git+https://github.com/osism/ansible-resolvconf

      curl https://raw.githubusercontent.com/osism/testbed/${var.configuration_version}/playbooks/node.yml > /root/node.yml
      ansible-playbook -i localhost, /root/node.yml

      cp /home/ubuntu/.ssh/id_rsa /home/dragon/.ssh/id_rsa
      cp /home/ubuntu/.ssh/id_rsa.pub /home/dragon/.ssh/id_rsa.pub
      chown -R dragon:dragon /home/dragon/.ssh

      sudo -iu dragon ansible-galaxy install git+https://github.com/osism/ansible-configuration
      sudo -iu dragon ansible-galaxy install git+https://github.com/osism/ansible-docker
      sudo -iu dragon ansible-galaxy install git+https://github.com/osism/ansible-docker-compose
      sudo -iu dragon ansible-galaxy install git+https://github.com/osism/ansible-manager

      curl https://raw.githubusercontent.com/osism/testbed/${var.configuration_version}/playbooks/manager-part-1.yml | sudo -iu dragon tee /home/dragon/manager-part-1.yml
      curl https://raw.githubusercontent.com/osism/testbed/${var.configuration_version}/playbooks/manager-part-2.yml | sudo -iu dragon tee /home/dragon/manager-part-2.yml
      curl https://raw.githubusercontent.com/osism/testbed/${var.configuration_version}/playbooks/manager-part-3.yml | sudo -iu dragon tee /home/dragon/manager-part-3.yml

      sudo -iu dragon ansible-playbook -i testbed-manager.osism.local, /home/dragon/manager-part-1.yml -e configuration_git_version=${var.configuration_version}
      sudo -iu dragon sh -c 'cd /opt/configuration; ./scripts/set-ceph-version.sh ${var.ceph_version}'
      sudo -iu dragon sh -c 'cd /opt/configuration; ./scripts/set-openstack-version.sh ${var.openstack_version}'

      sudo -iu dragon ansible-playbook -i testbed-manager.osism.local, /home/dragon/manager-part-2.yml
      sudo -iu dragon ansible-playbook -i testbed-manager.osism.local, /home/dragon/manager-part-3.yml

      sudo -iu dragon docker cp /home/dragon/.ssh/id_rsa.pub manager_osism-ansible_1:/share/id_rsa.pub

      rm /home/ubuntu/.ssh/id_rsa*

      # NOTE(berendt): wait for ARA
      until [[ "$(/usr/bin/docker inspect -f '{{.State.Health.Status}}' manager_ara-server_1)" == "healthy" ]]; do
          sleep 1;
      done;

      curl https://raw.githubusercontent.com/osism/testbed/${var.configuration_version}/playbooks/cleanup.yml > /root/cleanup.yml
      ansible-playbook -i localhost, /root/cleanup.yml
      update-alternatives --install /usr/bin/python python /usr/bin/python3 1

      # NOTE(berendt): sudo -E does not work here because sudo -i is needed

      sudo -iu dragon sh -c 'INTERACTIVE=false osism-run custom cronjobs'
      sudo -iu dragon sh -c 'INTERACTIVE=false osism-run custom facts'

      # deploy proxy services
      sudo -iu dragon sh -c '/opt/configuration/scripts/deploy_proxy_services.sh'

      sudo -iu dragon sh -c 'INTERACTIVE=false osism-generic bootstrap'
      sudo -iu dragon sh -c 'INTERACTIVE=false osism-generic operator'

      # copy network configuration
      sudo -iu dragon sh -c 'INTERACTIVE=false osism-generic network'

      # reboot nodes
      sudo -iu dragon sh -c 'INTERACTIVE=false osism-generic reboot -l "testbed-all:!testbed-manager" -e ireallymeanit=yes'
      sudo -iu dragon sh -c 'INTERACTIVE=false osism-generic wait-for-connection -l "testbed-all:!testbed-manager" -e ireallymeanit=yes'

      # NOTE: Restart the manager services to update the /etc/hosts file
      sudo -iu dragon sh -c 'docker-compose -f /opt/manager/docker-compose.yml restart'

      # NOTE(berendt): wait for ARA
      until [[ "$(/usr/bin/docker inspect -f '{{.State.Health.Status}}' manager_ara-server_1)" == "healthy" ]];
      do
          sleep 1;
      done;

      # deploy helper services
      sudo -iu dragon sh -c '/opt/configuration/scripts/deploy_helper_services.sh'

      # deploy infrastructure services
      if [[ "${var.deploy_infrastructure}" == "true" ]]; then
          sudo -iu dragon sh -c '/opt/configuration/scripts/deploy_infrastructure_services.sh'
      fi

      # deploy ceph services
      if [[ "${var.deploy_ceph}" == "true" ]]; then
          sudo -iu dragon sh -c '/opt/configuration/scripts/deploy_ceph_services.sh'
      fi

      # deploy openstack services
      if [[ "${var.deploy_openstack}" == "true" ]]; then
          if [[ "${var.deploy_infrastructure}" != "true" ]]; then
              echo "infrastructure services are necessary for the deployment of OpenStack"
          else
              sudo -iu dragon sh -c '/opt/configuration/scripts/deploy_openstack_services_basic.sh'

              if [[ "${var.run_refstack}" == "true" ]]; then
                  sudo -iu dragon sh -c 'INTERACTIVE=false osism-run openstack bootstrap-refstack'
                  sudo -iu dragon sh -c '/opt/configuration/contrib/refstack/refstack.sh'
              fi
          fi
      fi

      # deploy monitoring services
      if [[ "${var.deploy_monitoring}" == "true" ]]; then
          sudo -iu dragon sh -c '/opt/configuration/scripts/deploy_monitoring_services.sh'
      fi
    path: /root/run.sh
    permissions: 0700
runcmd:
  - "echo 'network: {config: disabled}' > /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg"
  - "rm -f /etc/network/interfaces.d/50-cloud-init.cfg"
  - "mv /etc/netplan/50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml.unused"
  - "/root/run.sh"
final_message: "The system is finally up, after $UPTIME seconds"
power_state:
  mode: reboot
  condition: True
EOT

user_data_node = <<-EOT
#cloud-config
package_update: true
package_upgrade: false
packages:
  - ifupdown
write_files:
  - content: |
      import subprocess
      import netifaces

      PORTS = {
          "${openstack_networking_port_v2.node_port_internal[count.index].mac_address}": "${openstack_networking_port_v2.node_port_internal[count.index].all_fixed_ips[0]}",
          "${openstack_networking_port_v2.node_port_external[count.index].mac_address}": "${openstack_networking_port_v2.node_port_external[count.index].all_fixed_ips[0]}",
          "${openstack_networking_port_v2.node_port_provider[count.index].mac_address}": "${openstack_networking_port_v2.node_port_provider[count.index].all_fixed_ips[0]}",
          "${openstack_networking_port_v2.node_port_storage_frontend[count.index].mac_address}": "${openstack_networking_port_v2.node_port_storage_frontend[count.index].all_fixed_ips[0]}",
          "${openstack_networking_port_v2.node_port_storage_backend[count.index].mac_address}": "${openstack_networking_port_v2.node_port_storage_backend[count.index].all_fixed_ips[0]}",
      }

      for interface in netifaces.interfaces():
          mac_address = netifaces.ifaddresses(interface)[netifaces.AF_LINK][0]['addr']
          if mac_address in PORTS:
              subprocess.run("ip addr add %s/24 dev %s" % (PORTS[mac_address], interface), shell=True)
              subprocess.run("ip link set up dev %s" % interface, shell=True)
    path: /root/configure-network-devices.py
    permissions: 0600
  - content: ${openstack_compute_keypair_v2.key.public_key}
    path: /home/ubuntu/.ssh/id_rsa.pub
    permissions: 0600
  - content: |
      ${indent(6, openstack_compute_keypair_v2.key.private_key)}
    path: /home/ubuntu/.ssh/id_rsa
    permissions: 0600
  - content: |
      #!/usr/bin/env bash

      echo '* libraries/restart-without-asking boolean true' | debconf-set-selections

      apt-get install --yes python3-netifaces
      python3 /root/configure-network-devices.py

      chown -R ubuntu:ubuntu /home/ubuntu/.ssh

      add-apt-repository --yes ppa:ansible/ansible
      apt-get install --yes ansible

      ansible-galaxy install git+https://github.com/osism/ansible-chrony
      ansible-galaxy install git+https://github.com/osism/ansible-common
      ansible-galaxy install git+https://github.com/osism/ansible-docker
      ansible-galaxy install git+https://github.com/osism/ansible-docker-compose
      ansible-galaxy install git+https://github.com/osism/ansible-operator
      ansible-galaxy install git+https://github.com/osism/ansible-repository
      ansible-galaxy install git+https://github.com/osism/ansible-resolvconf

      curl https://raw.githubusercontent.com/osism/testbed/${var.configuration_version}/playbooks/node.yml > /root/node.yml
      ansible-playbook -i localhost, /root/node.yml

      curl https://raw.githubusercontent.com/osism/testbed/${var.configuration_version}/playbooks/cleanup.yml > /root/cleanup.yml
      ansible-playbook -i localhost, /root/cleanup.yml
      update-alternatives --install /usr/bin/python python /usr/bin/python3 1

      rm /home/ubuntu/.ssh/id_rsa*
    path: /root/run.sh
    permissions: 0700
runcmd:
  - "echo 'network: {config: disabled}' > /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg"
  - "rm -f /etc/network/interfaces.d/50-cloud-init.cfg"
  - "mv /etc/netplan/50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml.unused"
  - "/root/run.sh"
final_message: "The system is finally up, after $UPTIME seconds"
EOT
