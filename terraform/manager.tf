resource "openstack_networking_floatingip_v2" "manager_floating_ip" {
  pool       = var.public
  port_id    = openstack_networking_port_v2.manager_port_management.id
  depends_on = [openstack_networking_router_interface_v2.router_interface]
}

resource "openstack_networking_port_v2" "manager_port_management" {
  network_id = openstack_networking_network_v2.net_management.id
  security_group_ids = [
    openstack_compute_secgroup_v2.security_group_management.id,
    openstack_compute_secgroup_v2.security_group_manager.id
  ]

  fixed_ip {
    ip_address = "192.168.40.5"
    subnet_id  = openstack_networking_subnet_v2.subnet_management.id
  }
}

resource "openstack_networking_port_v2" "manager_port_internal" {
  network_id         = openstack_networking_network_v2.net_internal.id
  security_group_ids = [openstack_compute_secgroup_v2.security_group_internal.id]

  fixed_ip {
    ip_address = "192.168.50.5"
    subnet_id  = openstack_networking_subnet_v2.subnet_internal.id
  }

  allowed_address_pairs {
    ip_address = "192.168.60.0/24"
  }
}

resource "openstack_networking_port_v2" "manager_port_external" {
  network_id         = openstack_networking_network_v2.net_external.id
  security_group_ids = [openstack_compute_secgroup_v2.security_group_external.id]

  fixed_ip {
    ip_address = "192.168.90.5"
    subnet_id  = openstack_networking_subnet_v2.subnet_external.id
  }

  allowed_address_pairs {
    ip_address = "192.168.60.0/24"
  }
}

resource "openstack_networking_port_v2" "manager_port_provider" {
  network_id = openstack_networking_network_v2.net_provider.id

  # NOTE: port_security_enabled not usable with OVH
  #
  # {"NeutronError": {"message": "Unrecognized attribute(s) 'port_security_enabled'", "type": "HTTPBadRequest", "detail": ""}}
  # port_security_enabled = false

  security_group_ids = [openstack_compute_secgroup_v2.security_group_provider.id]
  allowed_address_pairs {
    ip_address = "0.0.0.0/0"
  }

  fixed_ip {
    ip_address = "192.168.100.5"
    subnet_id  = openstack_networking_subnet_v2.subnet_provider.id
  }
}

resource "openstack_networking_port_v2" "manager_port_storage_frontend" {
  network_id         = openstack_networking_network_v2.net_storage_frontend.id
  security_group_ids = [openstack_compute_secgroup_v2.security_group_storage_frontend.id]

  fixed_ip {
    ip_address = "192.168.70.5"
    subnet_id  = openstack_networking_subnet_v2.subnet_storage_frontend.id
  }
}

resource "openstack_compute_instance_v2" "manager_server" {
  name              = "testbed-manager"
  availability_zone = var.availability_zone
  image_name        = var.image
  flavor_name       = var.flavor_manager
  key_pair          = openstack_compute_keypair_v2.key.name

  depends_on = [
    openstack_compute_instance_v2.node_server
  ]

  network { port = openstack_networking_port_v2.manager_port_management.id }
  network { port = openstack_networking_port_v2.manager_port_internal.id }
  network { port = openstack_networking_port_v2.manager_port_external.id }
  network { port = openstack_networking_port_v2.manager_port_provider.id }
  network { port = openstack_networking_port_v2.manager_port_storage_frontend.id }

  user_data = var.user_data_manager
}
