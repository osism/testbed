terraform {
  required_version = ">= 1.1.0"

  required_providers {
    openstack = {
      source = "terraform-provider-openstack/openstack"
    }
  }
}

variable "cloud_provider" {
  type    = string
  default = "betacloud"
}

variable "ttl" {
  type    = number
  default = 3600
}

provider "openstack" {
  cloud = var.cloud_provider
}

resource "openstack_dns_zone_v2" "zone" {
  name  = "osism.xyz."
  email = "info@osism.tech"
  ttl   = var.ttl
  type  = "PRIMARY"
}

resource "openstack_dns_recordset_v2" "rs_api_int" {
  zone_id = "${openstack_dns_zone_v2.zone.id}"
  name    = "api-int.testbed.osism.xyz."
  ttl     = var.ttl
  type    = "A"
  records = ["192.168.16.9"]
}

resource "openstack_dns_recordset_v2" "rs_api" {
  zone_id = "${openstack_dns_zone_v2.zone.id}"
  name    = "api.testbed.osism.xyz."
  ttl     = var.ttl
  type    = "A"
  records = ["192.168.16.254"]
}

resource "openstack_dns_recordset_v2" "rs_testbed_manager" {
  zone_id = "${openstack_dns_zone_v2.zone.id}"
  name    = "testbed-manager.testbed.osism.xyz."
  ttl     = var.ttl
  type    = "A"
  records = ["192.168.16.5"]
}

resource "openstack_dns_recordset_v2" "rs_testbed_node_0" {
  zone_id = "${openstack_dns_zone_v2.zone.id}"
  name    = "testbed-node-0.testbed.osism.xyz."
  ttl     = var.ttl
  type    = "A"
  records = ["192.168.16.10"]
}

resource "openstack_dns_recordset_v2" "rs_testbed_node_1" {
  zone_id = "${openstack_dns_zone_v2.zone.id}"
  name    = "testbed-node-1.testbed.osism.xyz."
  ttl     = var.ttl
  type    = "A"
  records = ["192.168.16.11"]
}

resource "openstack_dns_recordset_v2" "rs_testbed_node_2" {
  zone_id = "${openstack_dns_zone_v2.zone.id}"
  name    = "testbed-node-2.testbed.osism.xyz."
  ttl     = var.ttl
  type    = "A"
  records = ["192.168.16.12"]
}

resource "openstack_dns_recordset_v2" "rs_testbed_node_3" {
  zone_id = "${openstack_dns_zone_v2.zone.id}"
  name    = "testbed-node-3.testbed.osism.xyz."
  ttl     = var.ttl
  type    = "A"
  records = ["192.168.16.13"]
}

resource "openstack_dns_recordset_v2" "rs_testbed_node_4" {
  zone_id = "${openstack_dns_zone_v2.zone.id}"
  name    = "testbed-node-4.testbed.osism.xyz."
  ttl     = var.ttl
  type    = "A"
  records = ["192.168.16.14"]
}

resource "openstack_dns_recordset_v2" "rs_testbed_node_5" {
  zone_id = "${openstack_dns_zone_v2.zone.id}"
  name    = "testbed-node-5.testbed.osism.xyz."
  ttl     = var.ttl
  type    = "A"
  records = ["192.168.16.15"]
}

resource "openstack_dns_recordset_v2" "rs_testbed_node_6" {
  zone_id = "${openstack_dns_zone_v2.zone.id}"
  name    = "testbed-node-6.testbed.osism.xyz."
  ttl     = var.ttl
  type    = "A"
  records = ["192.168.16.16"]
}

resource "openstack_dns_recordset_v2" "rs_testbed_node_7" {
  zone_id = "${openstack_dns_zone_v2.zone.id}"
  name    = "testbed-node-7.testbed.osism.xyz."
  ttl     = var.ttl
  type    = "A"
  records = ["192.168.16.17"]
}

resource "openstack_dns_recordset_v2" "rs_testbed_node_8" {
  zone_id = "${openstack_dns_zone_v2.zone.id}"
  name    = "testbed-node-8.testbed.osism.xyz."
  ttl     = var.ttl
  type    = "A"
  records = ["192.168.16.18"]
}

resource "openstack_dns_recordset_v2" "rs_testbed_node_9" {
  zone_id = "${openstack_dns_zone_v2.zone.id}"
  name    = "testbed-node-9.testbed.osism.xyz."
  ttl     = var.ttl
  type    = "A"
  records = ["192.168.16.19"]
}
