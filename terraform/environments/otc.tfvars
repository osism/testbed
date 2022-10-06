# customisation:access_floatingip
# customisation:default
# customisation:neutron_floatingip
# override:manager_boot_from_volume
# override:neutron_router_enable_snat
# override:nodes_boot_from_volume
availability_zone         = "eu-de-02"
volume_availability_zone  = "eu-de-02"
network_availability_zone = "eu-de-02"
flavor_node               = "d2.4xlarge.8"
flavor_manager            = "d2.xlarge.8"
image                     = "Standard_Ubuntu_20.04_latest"
image_node                = "Standard_Ubuntu_20.04_latest"
volume_size_storage       = "10"
public                    = "admin_external_net"
enable_dhcp               = "true"
dns_nameservers           = ["100.125.4.25", "9.9.9.9"]
number_of_volumes         = "0"
