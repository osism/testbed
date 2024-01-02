# customisation:access_floatingip
# customisation:default
# customisation:neutron_floatingip
# override:manager_boot_from_image
# override:neutron_availability_zone_hints_network
# override:neutron_availability_zone_hints_router
# override:nodes_boot_from_image
flavor_manager            = "SCS-4V-8-50"
flavor_node               = "SCS-8V-32-100"
volume_type               = "ssd"
image                     = "OSISM CI"
image_node                = "OSISM CI"
availability_zone         = "nova"
network_availability_zone = "nova"
volume_availability_zone  = "nova"
public                    = "public"
