#!/usr/bin/env bash

export ELEMENTS_PATH=./elements
export DIB_CLOUD_INIT_DATASOURCES="ConfigDrive, OpenStack"

disk-image-create \
  -a amd64 \
  -o testbed \
  --image-size 3 \
  vm ubuntu testbed

qemu-img info testbed.qcow2
