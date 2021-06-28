resource "openstack_networking_floatingip_v2" "manager_floating_ip" {
  pool       = var.public
  depends_on = [openstack_networking_router_interface_v2.router_interface]
}

resource "openstack_networking_port_v2" "manager_port_management" {
  network_id = openstack_networking_network_v2.net_management.id
  security_group_ids = [
    openstack_compute_secgroup_v2.security_group_management.id
  ]

  fixed_ip {
    ip_address = "192.168.16.5"
    subnet_id  = openstack_networking_subnet_v2.subnet_management.id
  }

  allowed_address_pairs {
    ip_address = "192.168.48.0/20"
  }

  allowed_address_pairs {
    ip_address = "192.168.64.0/20"
  }

  allowed_address_pairs {
    ip_address = "192.168.80.0/20"
  }

  allowed_address_pairs {
    ip_address = "192.168.96.0/20"
  }

  allowed_address_pairs {
    ip_address = "192.168.112.0/20"
  }
}

resource "openstack_networking_floatingip_associate_v2" "manager_floating_ip_association" {
  floating_ip = openstack_networking_floatingip_v2.manager_floating_ip.address
  port_id     = openstack_networking_port_v2.manager_port_management.id
}

resource "openstack_blockstorage_volume_v3" "manager_base_volume" {
  count             = 0
  image_id          = data.openstack_images_image_v2.image.id
  name              = "${var.prefix}-volume-manager-base"
  size              = var.volume_size_base
  availability_zone = var.volume_availability_zone
}

resource "openstack_compute_instance_v2" "manager_server" {
  name              = "${var.prefix}-manager"
  availability_zone = var.availability_zone
  flavor_name       = var.flavor_manager
  key_pair          = openstack_compute_keypair_v2.key.name
  config_drive      = var.enable_config_drive

  depends_on = [
    null_resource.node_semaphore
  ]

  network { port = openstack_networking_port_v2.manager_port_management.id }

  user_data = <<-EOT
#cloud-config
network:
   config: disabled
package_update: false
package_upgrade: false
write_files:
  - content: |
      import subprocess
      import netifaces

      PORTS = {
          "${openstack_networking_port_v2.manager_port_management.mac_address}": [
              "192.168.64.5/20",
              "192.168.96.5/20"
          ]
      }

      for interface in netifaces.interfaces():
          try:
              mac_address = netifaces.ifaddresses(interface)[netifaces.AF_LINK][0]['addr']
              if mac_address in PORTS:
                  for address in PORTS[mac_address]:
                      subprocess.run("ip addr add %s dev %s" % (address, interface), shell=True)
          except:
              pass
    path: /root/configure-network-devices.py
    permissions: '0600'
  - content: ${openstack_compute_keypair_v2.key.public_key}
    path: /home/ubuntu/.ssh/id_rsa.pub
    permissions: '0600'
  - content: |
      ${indent(6, openstack_compute_keypair_v2.key.private_key)}
    path: /home/ubuntu/.ssh/id_rsa
    permissions: '0600'
  - content: |
      ${indent(6, file("files/node.yml"))}
    path: /opt/node.yml
    permissions: '0644'
  - content: |
      ${indent(6, file("files/cleanup.yml"))}
    path: /opt/cleanup.yml
    permissions: '0644'
  - content: |
      ${indent(6, file("files/cleanup.sh"))}
    path: /root/cleanup.sh
    permissions: '0700'
  - content: |
      ${indent(6, file("files/manager-part-1.yml"))}
    path: /opt/manager-part-1.yml
    permissions: '0644'
  - content: |
      ${indent(6, file("files/manager-part-2.yml"))}
    path: /opt/manager-part-2.yml
    permissions: '0644'
  - content: |
      ${indent(6, file("files/manager-part-3.yml"))}
    path: /opt/manager-part-3.yml
    permissions: '0644'
  - content: |
      ${indent(6, file("files/node.sh"))}
    path: /root/node.sh
    permissions: 0700
  - content: |
      #!/usr/bin/env bash

      apt-get install --yes python3-netifaces
      python3 /root/configure-network-devices.py

      cp /home/ubuntu/.ssh/id_rsa /home/dragon/.ssh/id_rsa
      cp /home/ubuntu/.ssh/id_rsa.pub /home/dragon/.ssh/id_rsa.pub
      chown -R dragon:dragon /home/dragon/.ssh

      sudo -iu dragon ansible-playbook -i testbed-manager.osism.test, /opt/manager-part-1.yml -e configuration_git_version=${var.configuration_version}
      sudo -iu dragon sh -c 'cd /opt/configuration; ./scripts/set-ceph-version.sh ${var.ceph_version}'
      sudo -iu dragon sh -c 'cd /opt/configuration; ./scripts/set-openstack-version.sh ${var.openstack_version}'
      sudo -iu dragon sh -c 'cd /opt/configuration; ./scripts/enable-secondary-nodes.sh ${var.number_of_nodes}'

      sudo -iu dragon ansible-playbook -i testbed-manager.osism.test, /opt/manager-part-2.yml
      sudo -iu dragon ansible-playbook -i testbed-manager.osism.test, /opt/manager-part-3.yml

      sudo -iu dragon cp /home/dragon/.ssh/id_rsa.pub /opt/ansible/secrets/id_rsa.operator.pub

      # NOTE(berendt): wait for ARA
      until [[ "$(/usr/bin/docker inspect -f '{{.State.Health.Status}}' manager_ara-server_1)" == "healthy" ]]; do
          sleep 1;
      done;

      /root/cleanup.sh

      # NOTE(berendt): sudo -E does not work here because sudo -i is needed

      sudo -iu dragon sh -c 'INTERACTIVE=false osism-run custom cronjobs'
      sudo -iu dragon sh -c 'INTERACTIVE=false osism-run custom facts'

      sudo -iu dragon sh -c 'INTERACTIVE=false osism-generic bootstrap'
      sudo -iu dragon sh -c 'INTERACTIVE=false osism-generic operator'

      # copy network configuration
      sudo -iu dragon sh -c 'INTERACTIVE=false osism-generic network'

      # apply workarounds
      sudo -iu dragon sh -c 'INTERACTIVE=false osism-run custom workarounds'

      # reboot nodes
      sudo -iu dragon sh -c 'INTERACTIVE=false osism-generic reboot -l testbed-nodes -e ireallymeanit=yes'
      sudo -iu dragon sh -c 'INTERACTIVE=false osism-generic wait-for-connection -l testbed-nodes -e ireallymeanit=yes'

      # NOTE: Restart the manager services to update the /etc/hosts file
      sudo -iu dragon sh -c 'docker-compose -f /opt/manager/docker-compose.yml restart'

      # NOTE(berendt): wait for ARA
      until [[ "$(/usr/bin/docker inspect -f '{{.State.Health.Status}}' manager_ara-server_1)" == "healthy" ]];
      do
          sleep 1;
      done;

      # deploy helper services
      sudo -iu dragon sh -c '/opt/configuration/scripts/001-helper-services.sh'

      # deploy identity services
      # NOTE: All necessary infrastructure services are also deployed.
      if [[ "${var.deploy_identity}" == "true" ]]; then
          sudo -iu dragon sh -c '/opt/configuration/scripts/999-identity-services.sh'
      fi

      # deploy infrastructure services
      if [[ "${var.deploy_infrastructure}" == "true" ]]; then
          sudo -iu dragon sh -c '/opt/configuration/scripts/002-infrastructure-services-basic.sh'
      fi

      # deploy ceph services
      if [[ "${var.deploy_ceph}" == "true" ]]; then
          sudo -iu dragon sh -c '/opt/configuration/scripts/003-ceph-services.sh'
      fi

      # deploy openstack services
      if [[ "${var.deploy_openstack}" == "true" ]]; then
          if [[ "${var.deploy_infrastructure}" != "true" ]]; then
              echo "infrastructure services are necessary for the deployment of OpenStack"
          else
              sudo -iu dragon sh -c '/opt/configuration/scripts/004-openstack-services-basic.sh'

              if [[ "${var.run_rally}" == "true" ]]; then
                  sudo -iu dragon sh -c '/opt/configuration/contrib/rally/rally.sh'
              fi

              if [[ "${var.run_refstack}" == "true" ]]; then
                  sudo -iu dragon sh -c 'INTERACTIVE=false osism-run openstack bootstrap-refstack'
                  sudo -iu dragon sh -c '/opt/configuration/contrib/refstack/refstack.sh'
              fi
          fi
      fi

      # deploy monitoring services
      if [[ "${var.deploy_monitoring}" == "true" ]]; then
          sudo -iu dragon sh -c '/opt/configuration/scripts/005-monitoring-services.sh'
      fi
    path: /root/manager.sh
    permissions: 0700
runcmd:
  - "echo 'network: {config: disabled}' > /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg"
  - "rm -f /etc/network/interfaces.d/50-cloud-init.cfg"
  - "mv /etc/netplan/50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml.unused"
  - "/root/node.sh"
  - "/root/manager.sh"
final_message: "The system is finally up, after $UPTIME seconds"
power_state:
  mode: reboot
  condition: True
EOT

}
