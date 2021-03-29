resource "openstack_blockstorage_volume_v3" "node_base_volume" {
  count = var.number_of_nodes
}

resource "openstack_compute_instance_v2" "node_server" {
  block_device {
    uuid                  = openstack_blockstorage_volume_v3.node_base_volume[count.index].id
    source_type           = "volume"
    boot_index            = 0
    destination_type      = "volume"
    delete_on_termination = false
  }
}
