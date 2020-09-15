###################
# Security groups #
###################

resource "openstack_compute_secgroup_v2" "security_group_manager" {
  name        = "${var.prefix}-manager"
  description = "manager security group"

  rule {
    cidr        = "0.0.0.0/0"
    ip_protocol = "udp"
    from_port   = 51820
    to_port     = 51820
  }
}

resource "openstack_compute_secgroup_v2" "security_group_management" {
  name        = "${var.prefix}-management"
  description = "management security group"

  rule {
    cidr        = "0.0.0.0/0"
    ip_protocol = "tcp"
    from_port   = 22
    to_port     = 22
  }

  rule {
    cidr        = "0.0.0.0/0"
    ip_protocol = "icmp"
    from_port   = -1
    to_port     = -1
  }
}

resource "openstack_compute_secgroup_v2" "security_group_internal" {
  name        = "${var.prefix}-internal"
  description = "internal security group"

  rule {
    cidr        = "0.0.0.0/0"
    ip_protocol = "tcp"
    from_port   = 1
    to_port     = 65535
  }

  rule {
    cidr        = "0.0.0.0/0"
    ip_protocol = "udp"
    from_port   = 1
    to_port     = 65535
  }

  rule {
    cidr        = "0.0.0.0/0"
    ip_protocol = "icmp"
    from_port   = -1
    to_port     = -1
  }
}

resource "openstack_networking_secgroup_rule_v2" "security_group_internal_vrrp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "vrrp"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_compute_secgroup_v2.security_group_internal.id
}

resource "openstack_compute_secgroup_v2" "security_group_storage_frontend" {
  name        = "${var.prefix}-storage-frontend"
  description = "storage frontend security group"

  rule {
    cidr        = "0.0.0.0/0"
    ip_protocol = "tcp"
    from_port   = 1
    to_port     = 65535
  }

  rule {
    cidr        = "0.0.0.0/0"
    ip_protocol = "udp"
    from_port   = 1
    to_port     = 65535
  }

  rule {
    cidr        = "0.0.0.0/0"
    ip_protocol = "icmp"
    from_port   = -1
    to_port     = -1
  }
}

resource "openstack_compute_secgroup_v2" "security_group_storage_backend" {
  name        = "${var.prefix}-storage-backend"
  description = "storage backend security group"

  rule {
    cidr        = "0.0.0.0/0"
    ip_protocol = "tcp"
    from_port   = 1
    to_port     = 65535
  }

  rule {
    cidr        = "0.0.0.0/0"
    ip_protocol = "udp"
    from_port   = 1
    to_port     = 65535
  }

  rule {
    cidr        = "0.0.0.0/0"
    ip_protocol = "icmp"
    from_port   = -1
    to_port     = -1
  }
}

resource "openstack_compute_secgroup_v2" "security_group_external" {
  name        = "${var.prefix}-external"
  description = "external security group"

  rule {
    cidr        = "0.0.0.0/0"
    ip_protocol = "tcp"
    from_port   = 1
    to_port     = 65535
  }

  rule {
    cidr        = "0.0.0.0/0"
    ip_protocol = "udp"
    from_port   = 1
    to_port     = 65535
  }

  rule {
    cidr        = "0.0.0.0/0"
    ip_protocol = "icmp"
    from_port   = -1
    to_port     = -1
  }
}

############
# Networks #
############

resource "openstack_networking_network_v2" "net_management" {
  name                    = "${var.prefix}-management"
  availability_zone_hints = [var.network_availability_zone]
}

resource "openstack_networking_subnet_v2" "subnet_management" {
  network_id      = openstack_networking_network_v2.net_management.id
  cidr            = "192.168.16.0/20"
  ip_version      = 4
  dns_nameservers = ["8.8.8.8", "9.9.9.9"]

  allocation_pool {
    start = "192.168.31.200"
    end   = "192.168.31.250"
  }
}

resource "openstack_networking_network_v2" "net_internal" {
  name                    = "${var.prefix}-internal"
  availability_zone_hints = [var.network_availability_zone]
}

resource "openstack_networking_subnet_v2" "subnet_internal" {
  network_id  = openstack_networking_network_v2.net_internal.id
  cidr        = "192.168.32.0/20"
  ip_version  = 4
  gateway_ip  = null
  enable_dhcp = false

  allocation_pool {
    start = "192.168.47.200"
    end   = "192.168.47.250"
  }
}

resource "openstack_networking_network_v2" "net_provider" {
  name                    = "${var.prefix}-provider"
  availability_zone_hints = [var.network_availability_zone]
}

resource "openstack_networking_subnet_v2" "subnet_provider" {
  network_id  = openstack_networking_network_v2.net_provider.id
  cidr        = "192.168.112.0/20"
  ip_version  = 4
  gateway_ip  = null
  enable_dhcp = false

  allocation_pool {
    start = "192.168.127.200"
    end   = "192.168.127.250"
  }
}

resource "openstack_networking_network_v2" "net_external" {
  name                    = "${var.prefix}-external"
  availability_zone_hints = [var.network_availability_zone]
}

resource "openstack_networking_subnet_v2" "subnet_external" {
  network_id  = openstack_networking_network_v2.net_external.id
  cidr        = "192.168.96.0/20"
  ip_version  = 4
  gateway_ip  = null
  enable_dhcp = false

  allocation_pool {
    start = "192.168.111.200"
    end   = "192.168.111.250"
  }
}

resource "openstack_networking_port_v2" "vip_port_external" {
  network_id = openstack_networking_network_v2.net_external.id

  fixed_ip {
    ip_address = "192.168.96.9"
    subnet_id  = openstack_networking_subnet_v2.subnet_external.id
  }
}

resource "openstack_networking_port_v2" "vip_port_internal" {
  network_id = openstack_networking_network_v2.net_internal.id

  fixed_ip {
    ip_address = "192.168.32.9"
    subnet_id  = openstack_networking_subnet_v2.subnet_internal.id
  }
}

resource "openstack_networking_network_v2" "net_storage_frontend" {
  name                    = "${var.prefix}-storage-frontend"
  availability_zone_hints = [var.network_availability_zone]
}

resource "openstack_networking_subnet_v2" "subnet_storage_frontend" {
  network_id  = openstack_networking_network_v2.net_storage_frontend.id
  cidr        = "192.168.64.0/20"
  ip_version  = 4
  gateway_ip  = null
  enable_dhcp = false

  allocation_pool {
    start = "192.168.79.200"
    end   = "192.168.79.250"
  }
}

resource "openstack_networking_network_v2" "net_storage_backend" {
  name                    = "${var.prefix}-storage-backend"
  availability_zone_hints = [var.network_availability_zone]
}

resource "openstack_networking_subnet_v2" "subnet_storage_backend" {
  network_id  = openstack_networking_network_v2.net_storage_backend.id
  cidr        = "192.168.80.0/20"
  ip_version  = 4
  gateway_ip  = null
  enable_dhcp = false

  allocation_pool {
    start = "192.168.95.200"
    end   = "192.168.95.250"
  }
}

data "openstack_networking_network_v2" "public" {
  name = var.public
}

resource "openstack_networking_router_v2" "router" {
  name                    = var.prefix
  external_network_id     = data.openstack_networking_network_v2.public.id
  availability_zone_hints = [var.network_availability_zone]
}

resource "openstack_networking_router_interface_v2" "router_interface" {
  router_id = openstack_networking_router_v2.router.id
  subnet_id = openstack_networking_subnet_v2.subnet_management.id
}
