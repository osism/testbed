#!/bin/bash
# Cleanup OSISM Testbed
# Usage: cleanup.sh [STACK_NM]
# STACK_NA defaults to the environment variable ENVIRONMENT
# Sometimes terraform does not know the state and we need to force a cleanup.
# (c) Kurt Garloff <scs@garloff.de>, 2/2021, CC-BY-SA 4.0
STACK_NM="${STACK_NM:-$ENVIRONMENT}"
STACK_NM="${1:-$STACK_NM}"
if test -z "$STACK_NM"; then echo "Usage: ENVIRONMENT=XXX ./cleanup.sh"; exit 1; fi
echo "Cleaning $STACK_NM"
echo "Trying make clean ENVIRONMENT=\"$STACK_NM\" first"
make clean ENVIRONMENT="$STACK_NM"
#terraform destroy -auto-approve -var-file="environments/${STACK_NM}.tfvars"
SERVER=$(openstack server list -f value -c ID -c Name | grep testbed-)
if test -n "$SERVER"; then
  echo Delete Servers: $SERVER
  SERVER=$(echo "$SERVER" | awk '{ print $1; }')
  openstack server delete $SERVER
  echo -n "Wait for servers to be gone: "
  while true; do
    SRV=$(openstack server list -f value -c "ID" -c "Name" -c "Status" | grep testbed)
    if test -z "$SRV"; then break; fi
    echo -n "."
    sleep 3;
  done
fi
echo 
KEYPAIRS=$(openstack keypair list -f value -c Name | grep testbed)
if test -n "$KEYPAIRS"; then
  echo Delete keypairs $KEYPAIRS
  openstack keypair delete $KEYPAIRS
fi
VOLUMES=$(openstack volume list -f value -c ID -c Name | grep testbed)
if test -n "$VOLUMES"; then
  echo Delete volumes $VOLUMES
  VOLUMES=$(echo "$VOLUMES" | awk '{ print $1; }')
  openstack volume delete $VOLUMES
fi
ROUTERS=$(openstack router list -f value -c Name | grep testbed)
SUBNETS=$(openstack subnet list -f value -c "ID" -c "Name" | grep testbed)
SUBNETFILT=$(echo "$SUBNETS" | awk '{ print $1; }')
SUBNETFILT=$(echo $SUBNETFILT)
SUBNETFILT="\\(${SUBNETFILT// /\\|}\\)"
#echo "$SUBNETS"
#echo "$SUBNETFILT"
if test -n "$SUBNETS"; then
  PORTS=$(openstack port list -f value -c ID -c "Fixed IP Addresses" | grep "$SUBNETFILT")
  PORTFILT=$(echo "$PORTS" | awk '{ print $1; }')
  PORTFILT=$(echo $PORTFILT)
  PORTFILT="\\(${PORTFILT// /\\|}\\)"
  #echo "Ports: $PORTS"
  #echo "$PORTFILT"
  if test -n "$PORTS"; then
    FIPS=$(openstack floating ip list -f value -c ID -c "Floating IP Address" -c "Port" | grep "$PORTFILT")
    if test -n "$FIPS"; then
      echo "Deleting Floating IP $FIPS"
      FIPS=$(echo "$FIPS" | awk '{ print $1; }')
      for FIP in $FIPS; do openstack floating ip delete $FIP; done
    fi
    REALPORTS=$(echo "$PORTS" | grep -v "'192\\.168\\.[0-9]*\\.\\(1\\|254\\)'")
    #echo "Realports: $REALPORTS"
    REALPORTS=$(echo "$REALPORTS" | awk '{ print $1; }')
    echo Deleting ports $REALPORTS
    openstack port delete $REALPORTS
  fi
  echo Delete subnets: $SUBNETS
  MGMT=$(echo "$SUBNETS" | grep manage | awk '{ print $1; }')
  openstack router remove subnet $ROUTERS $MGMT
  SUBNETS=$(echo "$SUBNETS" | awk '{ print $1; }')
  openstack subnet delete $SUBNETS
fi
SGS=$(openstack security group list -f value -c Name | grep testbed)
if test -n "$SGS"; then echo Deleting security groups $SGS; fi
for sg in $SGS; do
   openstack security group delete $sg
done
NETS=$(openstack network list -f value -c Name | grep testbed)
if test -n "$NETS"; then
  echo Deleting networks $NETS
  openstack network delete $NETS
fi
ROUTERS=$(openstack router list -f value -c Name | grep testbed)
if test -n "$ROUTERS"; then
  echo Deleting router $ROUTERS
  for router in $ROUTERS; do
    openstack router delete $router
  done
fi

#rm -f .deploy.$STACK_NM .MANAGER_ADDRESS.$STACK_NM .id_rsa.$STACK_NM *_override.tf
