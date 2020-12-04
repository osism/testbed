provider "openstack" {
  cloud = var.cloud_provider
}

terraform {
  required_version = ">= 0.14"

  required_providers {
    local = {
      source = "hashicorp/local"
    }

    openstack = {
      source = "terraform-provider-openstack/openstack"
    }
  }
}
