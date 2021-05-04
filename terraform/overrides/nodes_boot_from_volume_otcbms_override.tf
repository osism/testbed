resource "openstack_blockstorage_volume_v3" "node_base_volume" {
  count = var.number_of_nodes
}

resource "opentelekomcloud_compute_bms_server_v2" "node_server" {
  block_device {
    uuid                  = openstack_blockstorage_volume_v3.node_base_volume[count.index].id
    source_type           = var.block_device_source_type
    boot_index            = 0
    destination_type      = var.block_device_dest_type
    delete_on_termination = false
  }
}
