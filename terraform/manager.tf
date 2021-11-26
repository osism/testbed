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
    ip_address = "192.168.112.0/20"
  }
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
package_update: true
package_upgrade: true
write_files:
  - content: ${openstack_compute_keypair_v2.key.public_key}
    path: /home/ubuntu/.ssh/id_rsa.pub
    permissions: '0600'
  - content: |
      ${indent(6, openstack_compute_keypair_v2.key.private_key)}
    path: /home/ubuntu/.ssh/id_rsa
    permissions: '0600'
  - content: |
      ${indent(6, file("files/manager-part-0.yml"))}
    path: /opt/manager-part-0.yml
    permissions: '0644'
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
      ${indent(6, file("files/manager.sh"))}
    path: /root/manager.sh
    permissions: '0700'
  - content: |
      #!/usr/bin/env bash

      export NUMBER_OF_NODES=${var.number_of_nodes}

      export CEPH_VERSION=${var.ceph_version}
      export CONFIGURATION_VERSION=${var.configuration_version}
      export MANAGER_VERSION=${var.manager_version}
      export OPENSTACK_VERSION=${var.openstack_version}

      export DEPLOY_CEPH=${var.deploy_ceph}
      export DEPLOY_IDENTITY=${var.deploy_identity}
      export DEPLOY_INFRASTRUCTURE=${var.deploy_infrastructure}
      export DEPLOY_MONITORING=${var.deploy_monitoring}
      export DEPLOY_OPENSTACK=${var.deploy_openstack}

      bash /root/manager.sh

    path: /root/run-manager.sh
    permissions: '0700'
runcmd:
  - "echo 'network: {config: disabled}' > /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg"
  - "/root/run-manager.sh"
final_message: "The system is finally up, after $UPTIME seconds"
power_state:
  mode: reboot
  condition: True
EOT

}
