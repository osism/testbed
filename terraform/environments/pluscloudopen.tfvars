# override:manager_boot_from_image
# override:nodes_boot_from_image
# override:manager_port_fixed_ip_address
# override:nodes_port_fixed_ip_address
availability_zone         = "nova"
volume_availability_zone  = "nova"
network_availability_zone = "nova"
flavor_node               = "4C-16GB-60GB"
flavor_manager            = "2C-4GB-20GB"
image                     = "Ubuntu 20.04"
public                    = "ext01"
volume_size_storage       = "10"
