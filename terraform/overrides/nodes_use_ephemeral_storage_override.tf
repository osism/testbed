resource "openstack_compute_instance_v2" "node_server" {
  block_device {
    boot_index            = 0
    destination_type      = "local"
    source_type           = "image"
    uuid                  = data.openstack_images_image_v2.image_node.id
  }

  block_device {
    boot_index            = -1
    destination_type      = "local"
    source_type           = "blank"
    volume_size           = var.volume_size_storage
  }

  # NOTE: At the moment by default only 3 local block devices are possible.
  #
  #       Block Device Mapping is Invalid: You specified more local devices than the limit allows
  #
  #       nova.conf: max_local_block_devices = 3

  block_device {
     boot_index            = -1
     destination_type      = "local"
     source_type           = "blank"
     volume_size           = var.volume_size_storage
  }
}
