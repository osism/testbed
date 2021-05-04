resource "openstack_blockstorage_volume_v3" "manager_base_volume" {
  count = 1
}

resource "openstack_compute_instance_v2" "manager_server" {
  block_device {
    uuid                  = openstack_blockstorage_volume_v3.manager_base_volume[0].id
    source_type           = var.block_device_source_type
    boot_index            = 0
    destination_type      = var.block_device_dest_type
    delete_on_termination = false
  }
}
