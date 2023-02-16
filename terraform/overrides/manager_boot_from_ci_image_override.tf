resource "openstack_compute_instance_v2" "manager_server" {
  image_id = openstack_images_image_v2.ci_image.id
}
