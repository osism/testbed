# customisation:access_floatingip
# customisation:default
# customisation:neutron_floatingip
# override:manager_boot_from_volume
# override:neutron_availability_zone_hints_network
# override:neutron_availability_zone_hints_router
# override:nodes_boot_from_volume
flavor_manager            = "SCS-4V-16"
flavor_node               = "SCS-8V-32"
volume_type               = "__DEFAULT__"
image                     = "Ubuntu 22.04"
image_node                = "Ubuntu 22.04"
public                    = "PN-231"
availability_zone         = "chur"
volume_availability_zone  = "chur"
network_availability_zone = "nova"
volume_size_storage       = 100
number_of_nodes           = 6
