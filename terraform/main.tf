provider "openstack" {
  cloud = var.cloud_provider
}

terraform {
  required_version = ">= 0.13"

  # The "hashicorp" namespace is the new home for the HashiCorp-maintained
  # provider plugins.
  #
  # source is not required for the hashicorp/* namespace as a measure of
  # backward compatibility for commonly-used providers, but recommended for
  # explicitness.
  #
  # source is required for providers in other namespaces, to avoid ambiguity.

  required_providers {
    local = {
      source = "hashicorp/local"
    }

    openstack = {
      source = "terraform-providers/openstack"
    }
  }
}
