provider "openstack" {
  cloud = var.cloud_provider
}

terraform {
  required_version = ">= 0.12"
}
