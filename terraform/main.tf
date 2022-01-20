terraform {
  required_version = ">= 1.1.0"

  required_providers {
    local = {
      source = "hashicorp/local"
    }

    null = {
      source = "hashicorp/null"
    }

    openstack = {
      source = "terraform-provider-openstack/openstack"
    }

    # NOTE: Required because we support OTC BMS nodes. The provider
    #       is only used if an OTC BMS environment is used.
    opentelekomcloud = {
      source = "opentelekomcloud/opentelekomcloud"
    }
  }
}
