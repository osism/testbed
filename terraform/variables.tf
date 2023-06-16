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

variable "image_node" {
  type    = string
  default = "Ubuntu 20.04"
}

variable "volume_size_base" {
  type    = number
  default = 30
}

variable "volume_size_storage" {
  type    = number
  default = 10
}

variable "flavor_node" {
  type    = string
  default = "SCS-8V:32:50"
}

variable "flavor_manager" {
  type    = string
  default = "SCS-4V:8:50"
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

variable "deploy_monitoring" {
  type    = bool
  default = false
}

variable "refstack" {
  type    = bool
  default = false
}

variable "configuration_version" {
  type    = string
  default = "main"
}

variable "ceph_version" {
  type    = string
  default = "quincy"
}

variable "manager_version" {
  type    = string
  default = "latest"
}

variable "openstack_version" {
  type    = string
  default = "zed"
}

variable "number_of_nodes" {
  type    = number
  default = 3
}

variable "number_of_volumes" {
  type    = number
  default = 3
}

variable "enable_config_drive" {
  type    = bool
  default = true
}

variable "dns_nameservers" {
  type    = list(string)
  default = ["8.8.8.8", "9.9.9.9"]
}
