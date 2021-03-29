resource "openstack_blockstorage_volume_v3" "manager_base_volume" {
  count = 1
}

resource "openstack_compute_instance_v2" "manager_server" {
  block_device {
    uuid                  = openstack_blockstorage_volume_v3.manager_base_volume[0].id
    source_type           = "volume"
    boot_index            = 0
    destination_type      = "volume"
    delete_on_termination = false
  }
}
