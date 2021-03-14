variable "cloud_provider" {
  type = string
}

variable "prefix" {
  type    = string
  default = "testbed"
}

variable "image" {
  type    = string
  default = "Ubuntu 20.04"
}

variable "volume_size_storage" {
  type    = number
  default = 10
}

variable "flavor_node" {
  type    = string
  default = "4C-16GB-40GB"
}

variable "flavor_manager" {
  type    = string
  default = "4C-8GB-20GB"
}

variable "availability_zone" {
  type    = string
  default = "south-2"
}

variable "volume_availability_zone" {
  type    = string
  default = "south-2"
}

variable "network_availability_zone" {
  type    = string
  default = "south-2"
}

variable "public" {
  type    = string
  default = "external"
}

variable "port_security_enabled" {
  type    = bool
  default = false
}

variable "deploy_infrastructure" {
  type    = bool
  default = false
}

variable "deploy_openstack" {
  type    = bool
  default = false
}

variable "deploy_ceph" {
  type    = bool
  default = false
}

variable "deploy_monitoring" {
  type    = bool
  default = false
}

variable "deploy_identity" {
  type    = bool
  default = false
}

variable "run_rally" {
  type    = bool
  default = false
}

variable "run_refstack" {
  type    = bool
  default = false
}

variable "configuration_version" {
  type    = string
  default = "master"
}

variable "ceph_version" {
  type    = string
  default = "nautilus"
}

variable "openstack_version" {
  type    = string
  default = "victoria"
}

variable "number_of_nodes" {
  type    = number
  default = 3
}

variable "number_of_volumes" {
  type    = number
  default = 3
}

variable "enable_dhcp" {
  type    = bool
  default = false
}

variable "dns_nameservers" {
  type    = list(string)
  default = ["8.8.8.8", "9.9.9.9"]
}
