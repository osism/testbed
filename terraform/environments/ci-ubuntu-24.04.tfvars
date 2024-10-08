# customisation:access_floatingip
# customisation:default
# customisation:neutron_floatingip
# override:manager_boot_from_volume
# override:neutron_availability_zone_hints_network
# override:neutron_availability_zone_hints_router
# override:nodes_boot_from_volume
flavor_manager            = "OSISM-4V-16"
flavor_node               = "OSISM-8V-32"
volume_type               = "ssd"
image                     = "Ubuntu 24.04"
image_node                = "Ubuntu 24.04"
availability_zone         = "nova"
network_availability_zone = "nova"
volume_availability_zone  = "nova"
public                    = "public"
number_of_nodes           = 6
ara                       = false
is_zuul                   = true
