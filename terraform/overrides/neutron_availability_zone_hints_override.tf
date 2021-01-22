###################
# Networks        #
###################

resource "openstack_networking_network_v2" "net_management" {
  availability_zone_hints = [var.network_availability_zone]
}

resource "openstack_networking_network_v2" "net_internal" {
  availability_zone_hints = [var.network_availability_zone]
}

resource "openstack_networking_network_v2" "net_provider" {
  availability_zone_hints = [var.network_availability_zone]
}

resource "openstack_networking_network_v2" "net_external" {
  availability_zone_hints = [var.network_availability_zone]
}

resource "openstack_networking_network_v2" "net_storage_frontend" {
  availability_zone_hints = [var.network_availability_zone]
}

resource "openstack_networking_network_v2" "net_storage_backend" {
  availability_zone_hints = [var.network_availability_zone]
}

###################
# Router          #
###################

resource "openstack_networking_router_v2" "router" {
  availability_zone_hints = [var.network_availability_zone]
}
