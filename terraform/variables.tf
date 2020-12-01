variable "cloud_provider" {
  type = string
}

variable "prefix" {
  default = "testbed"
  type    = string
}

variable "image" {
  default = "Ubuntu 20.04"
  type    = string
}

variable "volume_size_storage" {
  default = 10
  type    = number
}

variable "flavor_node" {
  default = "4C-16GB-40GB"
  type    = string
}

variable "flavor_manager" {
  default = "4C-8GB-20GB"
  type    = string
}

variable "availability_zone" {
  default = "south-2"
  type    = string
}

variable "volume_availability_zone" {
  default = "south-2"
  type    = string
}

variable "network_availability_zone" {
  default = "south-2"
  type    = string
}

variable "public" {
  default = "external"
  type    = string
}

variable "port_security_enabled" {
  default = false
  type    = bool
}

variable "deploy_infrastructure" {
  default = false
  type    = bool
}

variable "deploy_openstack" {
  default = false
  type    = bool
}

variable "deploy_ceph" {
  default = false
  type    = bool
}

variable "deploy_monitoring" {
  default = false
  type    = bool
}

variable "run_rally" {
  default = false
  type    = bool
}

variable "run_refstack" {
  default = false
  type    = bool
}

variable "configuration_version" {
  default = "master"
  type    = string
}

variable "ceph_version" {
  default = "nautilus"
  type    = string
}

variable "openstack_version" {
  default = "victoria"
  type    = string
}

variable "number_of_nodes" {
  default = 3
  type    = number
}

variable "number_of_volumes" {
  default = 3
  type    = number
}
