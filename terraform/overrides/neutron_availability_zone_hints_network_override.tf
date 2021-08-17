resource "openstack_networking_network_v2" "net_management" {
  availability_zone_hints = [var.network_availability_zone]
}
