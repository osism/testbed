###################
# Networks        #
###################

resource "openstack_networking_network_v2" "net_management" {
  availability_zone_hints = [var.network_availability_zone]
}

###################
# Router          #
###################

resource "openstack_networking_router_v2" "router" {
  availability_zone_hints = [var.network_availability_zone]
}
