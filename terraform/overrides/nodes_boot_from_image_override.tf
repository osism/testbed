resource "openstack_compute_instance_v2" "node_server" {
  image_id = data.openstack_images_image_v2.image_node.id
}
