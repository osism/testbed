resource "openstack_networking_port_v2" "node_port_provider" {
  fixed_ip {
    ip_address = "192.168.112.1${count.index}"
    subnet_id  = openstack_networking_subnet_v2.subnet_provider.id
  }
}
