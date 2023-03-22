# customisation:access_floatingip
# customisation:default
# customisation:neutron_floatingip
# override:manager_boot_from_volume
# override:neutron_router_enable_snat
# override:nodes_boot_from_volume
availability_zone         = "eu-west-101b"
volume_availability_zone  = "eu-west-101b"
network_availability_zone = "eu-west-101b"
flavor_node               = "c6s.4xlarge.2"
flavor_manager            = "s6.2xlarge.2"
image                     = "Ubuntu 22.04 server 64bit"
image_node                = "Ubuntu 22.04 server 64bit"
volume_size_storage       = 50
public                    = "admin_external_net"
dns_nameservers           = ["9.9.9.9"]
number_of_volumes         = 3
