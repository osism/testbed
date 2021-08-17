# customisation:access_ipv6
# customisation:default
# override:manager_boot_from_image
# override:neutron_availability_zone_hints_network
# override:nodes_boot_from_image
availability_zone         = "nova"
volume_availability_zone  = "nova"
network_availability_zone = "nova"
image                     = "Ubuntu-20.04"
image_node                = "Ubuntu-20.04"
flavor_manager            = "general.v1.medium"
flavor_node               = "baremetal"
public                    = "admin"
