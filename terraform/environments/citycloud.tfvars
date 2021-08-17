# customisation:access_floatingip
# customisation:default
# customisation:neutron_floatingip
# override:manager_boot_from_image
# override:neutron_availability_zone_hints_network
# override:neutron_availability_zone_hints_router
# override:nodes_boot_from_image
availability_zone         = "nova"
volume_availability_zone  = "nova"
network_availability_zone = "nova"
flavor_node               = "8C-32GB-150GB"
flavor_manager            = "4C-8GB-50GB"
image                     = "Ubuntu 20.04 Focal Fossa 20210616"
image_node                = "Ubuntu 20.04 Focal Fossa 20210616"
public                    = "ext-net"
volume_size_storage       = "10"
