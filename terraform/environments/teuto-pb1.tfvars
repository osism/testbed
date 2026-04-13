# customisation:access_floatingip
# customisation:default
# customisation:neutron_floatingip
# override:nodes_boot_from_image
# override:manager_boot_from_image

## override:manager_boot_from_volume
## override:neutron_availability_zone_hints_network
## override:neutron_availability_zone_hints_router
## override:nodes_boot_from_volume
flavor_manager            = "standard.4.1905"
flavor_node               = "standard.8.1905"
volume_type               = "Ceph-SSD"
image                     = "Ubuntu 24.04"
image_node                = "Ubuntu 24.04"
public                    = "extern"
availability_zone         = "nova"
volume_availability_zone  = "nova"
network_availability_zone = null
