# override:neutron_router_enable_snat
# override:manager_boot_from_volume
# customisation:otcbms
availability_zone         = "eu-de-01"
volume_availability_zone  = "eu-de-01"
network_availability_zone = "eu-de-01"
flavor_node               = "physical.o2.medium"
flavor_node_alt           = "physical.o2.medium"
flavor_manager            = "s2.4xlarge.4"
image                     = "Standard_Ubuntu_20.04_latest"
image_node                = "Standard_Ubuntu_20.04_BMS_latest"
volume_size_base          = "40"
public                    = "admin_external_net"
enable_dhcp               = "true"
dns_nameservers           = ["100.125.4.25", "9.9.9.9"]
number_of_nodes           = 10
