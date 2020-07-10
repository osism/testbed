resource "openstack_networking_port_v2" "node_port_management" {
  count              = var.number_of_nodes
  network_id         = openstack_networking_network_v2.net_management.id
  security_group_ids = [openstack_compute_secgroup_v2.security_group_management.id]

  fixed_ip {
    ip_address = "192.168.40.1${count.index}"
    subnet_id  = openstack_networking_subnet_v2.subnet_management.id
  }
}

resource "openstack_networking_port_v2" "node_port_internal" {
  count              = var.number_of_nodes
  network_id         = openstack_networking_network_v2.net_internal.id
  security_group_ids = [openstack_compute_secgroup_v2.security_group_internal.id]

  fixed_ip {
    ip_address = "192.168.50.1${count.index}"
    subnet_id  = openstack_networking_subnet_v2.subnet_internal.id
  }

  allowed_address_pairs {
    ip_address = "192.168.50.200/32"
  }
}

resource "openstack_networking_port_v2" "node_port_external" {
  count              = var.number_of_nodes
  network_id         = openstack_networking_network_v2.net_external.id
  security_group_ids = [openstack_compute_secgroup_v2.security_group_external.id]

  fixed_ip {
    ip_address = "192.168.90.1${count.index}"
    subnet_id  = openstack_networking_subnet_v2.subnet_external.id
  }

  allowed_address_pairs {
    ip_address = "192.168.90.200/32"
  }
}

resource "openstack_networking_port_v2" "node_port_provider" {
  count      = var.number_of_nodes
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
    ip_address = "192.168.100.1${count.index}"
    subnet_id  = openstack_networking_subnet_v2.subnet_provider.id
  }
}

resource "openstack_networking_port_v2" "node_port_storage_frontend" {
  count              = var.number_of_nodes
  network_id         = openstack_networking_network_v2.net_storage_frontend.id
  security_group_ids = [openstack_compute_secgroup_v2.security_group_storage_frontend.id]

  fixed_ip {
    ip_address = "192.168.70.1${count.index}"
    subnet_id  = openstack_networking_subnet_v2.subnet_storage_frontend.id
  }
}

resource "openstack_networking_port_v2" "node_port_storage_backend" {
  count              = var.number_of_nodes
  network_id         = openstack_networking_network_v2.net_storage_backend.id
  security_group_ids = [openstack_compute_secgroup_v2.security_group_storage_backend.id]

  fixed_ip {
    ip_address = "192.168.80.1${count.index}"
    subnet_id  = openstack_networking_subnet_v2.subnet_storage_backend.id
  }
}

resource "openstack_blockstorage_volume_v3" "node_volume_0" {
  count             = var.number_of_nodes
  name              = "testbed-node-${count.index}-volume-0"
  size              = var.volume_size_storage
  availability_zone = var.volume_availability_zone
}

resource "openstack_compute_volume_attach_v2" "node_volume_0_attachment" {
  count       = var.number_of_nodes
  instance_id = openstack_compute_instance_v2.node_server[count.index].id
  volume_id   = openstack_blockstorage_volume_v3.node_volume_0[count.index].id
}

resource "openstack_blockstorage_volume_v3" "node_volume_1" {
  count             = var.number_of_nodes
  name              = "testbed-node-${count.index}-volume-1"
  size              = var.volume_size_storage
  availability_zone = var.volume_availability_zone
}

resource "openstack_compute_volume_attach_v2" "node_volume_1_attachment" {
  count       = var.number_of_nodes
  instance_id = openstack_compute_instance_v2.node_server[count.index].id
  volume_id   = openstack_blockstorage_volume_v3.node_volume_1[count.index].id
}

resource "openstack_blockstorage_volume_v3" "node_volume_2" {
  count             = var.number_of_nodes
  name              = "testbed-node-${count.index}-volume-2"
  size              = var.volume_size_storage
  availability_zone = var.volume_availability_zone
}

resource "openstack_compute_volume_attach_v2" "node_volume_2_attachment" {
  count       = var.number_of_nodes
  instance_id = openstack_compute_instance_v2.node_server[count.index].id
  volume_id   = openstack_blockstorage_volume_v3.node_volume_2[count.index].id
}

resource "openstack_compute_instance_v2" "node_server" {
  count             = var.number_of_nodes
  name              = "testbed-node-${count.index}"
  availability_zone = var.availability_zone
  image_name        = var.image
  flavor_name       = var.flavor_node
  key_pair          = openstack_compute_keypair_v2.key.name

  network { port = openstack_networking_port_v2.node_port_management[count.index].id }
  network { port = openstack_networking_port_v2.node_port_internal[count.index].id }
  network { port = openstack_networking_port_v2.node_port_external[count.index].id }
  network { port = openstack_networking_port_v2.node_port_provider[count.index].id }
  network { port = openstack_networking_port_v2.node_port_storage_frontend[count.index].id }
  network { port = openstack_networking_port_v2.node_port_storage_backend[count.index].id }

  user_data = var.user_data_node
}
