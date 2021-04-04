data "openstack_networking_network_v2" "public" {
  name = var.public
}

data "openstack_images_image_v2" "image" {
  name        = var.image
  most_recent = true
}

data "openstack_images_image_v2" "image_node" {
  name        = var.image_node
  most_recent = true
}
