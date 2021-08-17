output "private_key" {
  value     = openstack_compute_keypair_v2.key.private_key
  sensitive = true
}

resource "local_file" "id_rsa" {
  filename          = ".id_rsa.${var.cloud_provider}"
  file_permission   = "0600"
  sensitive_content = openstack_compute_keypair_v2.key.private_key
}
