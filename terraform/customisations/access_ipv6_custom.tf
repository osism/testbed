output "manager_address" {
  value     = openstack_compute_instance_v2.manager_server.access_ip_v6
  sensitive = true
}

resource "local_file" "MANAGER_ADDRESS" {
  filename        = ".MANAGER_ADDRESS.${var.cloud_provider}"
  file_permission = "0644"
  content         = "MANAGER_ADDRESS=${openstack_compute_instance_v2.manager_server.access_ip_v6}\n"
}
