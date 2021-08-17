output "manager_address" {
  value     = openstack_networking_floatingip_v2.manager_floating_ip.address
  sensitive = true
}

resource "local_file" "MANAGER_ADDRESS" {
  filename        = ".MANAGER_ADDRESS.${var.cloud_provider}"
  file_permission = "0644"
  content         = "MANAGER_ADDRESS=${openstack_networking_floatingip_v2.manager_floating_ip.address}\n"
}
