# customisation:access_floatingip
# customisation:default
# customisation:neutron_floatingip
# override:manager_boot_from_image
# override:nodes_boot_from_image
availability_zone         = null
volume_availability_zone  = null
network_availability_zone = null
flavor_node               = "4C-16GB-60GB"
# Let's use "4C-8GB-60GB" which is the one
# used in the scs-demo.tfvars settings
flavor_manager            = "4C-8GB-60GB"
image                     = "Ubuntu 20.04"
image_node                = "Ubuntu 20.04"
public                    = "ext01"
volume_size_storage       = "10"
