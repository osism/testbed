output "private_key" {
  value     = openstack_compute_keypair_v2.key.private_key
  sensitive = true
}

resource "local_sensitive_file" "id_rsa" {
  filename        = ".id_rsa.${var.cloud_provider}"
  file_permission = "0600"
  content         = openstack_compute_keypair_v2.key.private_key
}

resource "local_file" "id_rsa_pub" {
  filename        = ".id_rsa.${var.cloud_provider}.pub"
  file_permission = "0644"
  content         = "${openstack_compute_keypair_v2.key.public_key}\n"
}
