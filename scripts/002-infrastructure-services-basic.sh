#!/usr/bin/env bash

export INTERACTIVE=false

osism-infrastructure openstackclient
osism-infrastructure minikube
osism-kolla deploy testbed --tags infrastructure --skip-tags openstack
