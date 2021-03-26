resource "openstack_networking_port_v2" "manager_port_provider" {
  fixed_ip {
    ip_address = "192.168.112.5"
    subnet_id  = openstack_networking_subnet_v2.subnet_provider.id
  }
}
