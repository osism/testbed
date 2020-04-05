#!/usr/bin/env bash

export ELEMENTS_PATH=./elements

disk-image-create \
  -a amd64 \
  -o testbed \
  --image-size 4 \
  vm ubuntu testbed

qemu-img info testbed.qcow2
