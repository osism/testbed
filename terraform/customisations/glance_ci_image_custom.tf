resource "openstack_images_image_v2" "ci_image" {
  name             = "OSISM CI Image"
  image_source_url = "https://minio.services.osism.tech/ci-image/ci-image.qcow2"
  container_format = "bare"
  disk_format      = "qcow2"
  web_download     = true
}
