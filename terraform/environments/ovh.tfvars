# override:manager_boot_from_image
# override:nodes_boot_from_image
# override:manager_port_fixed_ip_address
# override:nodes_port_fixed_ip_address
availability_zone         = "nova"
volume_availability_zone  = "nova"
network_availability_zone = "nova"
flavor_node               = "c2-15"
flavor_manager            = "s1-8"
image                     = "Ubuntu 20.04"
public                    = "Ext-Net"
volume_size_storage       = "10"
port_security_enabled     = null
