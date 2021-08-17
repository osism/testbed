resource "openstack_networking_router_v2" "router" {
  availability_zone_hints = [var.network_availability_zone]
}
