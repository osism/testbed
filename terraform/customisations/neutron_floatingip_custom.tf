resource "openstack_networking_floatingip_v2" "manager_floating_ip" {
  pool       = var.public
  depends_on = [openstack_networking_router_interface_v2.router_interface]
}

resource "openstack_networking_floatingip_associate_v2" "manager_floating_ip_association" {
  floating_ip = openstack_networking_floatingip_v2.manager_floating_ip.address
  port_id     = openstack_networking_port_v2.manager_port_management.id
}

resource "openstack_networking_router_v2" "router" {
  name                = var.prefix
  external_network_id = data.openstack_networking_network_v2.public.id
}

resource "openstack_networking_router_interface_v2" "router_interface" {
  router_id = openstack_networking_router_v2.router.id
  subnet_id = openstack_networking_subnet_v2.subnet_management.id
}
