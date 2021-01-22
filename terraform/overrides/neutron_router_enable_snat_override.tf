resource "openstack_networking_router_v2" "router" {
  enable_snat = true
}
