availability_zone         = "eu-de-02"
volume_availability_zone  = "eu-de-02"
network_availability_zone = "eu-de-02"
flavor_node               = "s2.4xlarge.2"
flavor_manager            = "s2.xlarge.2"
#image                     = "Standard_Ubuntu_20.04_latest"
image                     = "Ubuntu 20.04"
volume_size_storage       = "10"
public                    = "admin_external_net"
enable_dhcp               = "true"
dns_nameservers           = [ "100.125.4.25", "9.9.9.9" ]
