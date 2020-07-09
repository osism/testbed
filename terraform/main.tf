provider "openstack" {
  cloud = var.cloud_provider
}

terraform {
  required_version = ">= 0.12"

  backend "local" {
    path          = "terraform.tfstate"
    workspace_dir = "terraform-workspace-${var.cloud_provider}"
  }
}
