output "manager_address" {
  value = openstack_networking_floatingip_v2.manager_floating_ip.address
}

output "private_key" {
  value = openstack_compute_keypair_v2.key.private_key
}

resource "local_file" "id_rsa" {
  filename          = ".id_rsa.${var.cloud_provider}"
  file_permission   = "0600"
  sensitive_content = openstack_compute_keypair_v2.key.private_key
}

resource "local_file" "MANAGER_ADDRESS" {
  filename        = ".MANAGER_ADDRESS.${var.cloud_provider}"
  file_permission = "0644"
  content         = "MANAGER_ADDRESS=${openstack_networking_floatingip_v2.manager_floating_ip.address}\n"
}
