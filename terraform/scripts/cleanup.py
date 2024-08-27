#!/usr/bin/env python3

# SPDX-License-Identifier: Apache-2.0

import logging
import os
import time

import openstack

logging.basicConfig(
    format="%(asctime)s - %(message)s", level=logging.INFO, datefmt="%Y-%m-%d %H:%M:%S"
)


def disconnect_routers(conn, prefix):
    logging.info("disconnect routers")
    routers = list(conn.network.routers())
    for router in routers:
        router_dict = router.to_dict()
        router_name = router_dict["name"]
        router_id = router_dict["id"]
        if not router_name.startswith(prefix):
            continue

        logging.info(router_name)
        ports = list(conn.network.ports(device_id=router_id))
        for port in ports:
            conn.network.remove_interface_from_router(router_id, port_id=port["id"])


def cleanup_routers(conn, prefix):
    logging.info("clean up routers")
    routers = list(conn.network.routers())
    for router in routers:
        router_name = router.to_dict()["name"]
        if not router_name.startswith(prefix):
            continue

        logging.info(router_name)
        conn.network.remove_gateway_from_router(router)
        conn.network.delete_router(router)


def cleanup_networks(conn, prefix):
    logging.info("clean up networks")
    networks = list(conn.network.networks(shared=False))
    for network in networks:
        network_name = network.to_dict()["name"]
        if not network_name.startswith(f"net-{prefix}"):
            continue

        logging.info(network_name)
        conn.network.delete_network(network)


def cleanup_subnets(conn, prefix):
    logging.info("clean up subnets")
    subnets = list(conn.network.subnets())
    for subnet in subnets:
        subnet_name = subnet.to_dict()["name"]
        if not subnet_name.startswith(f"subnet-{prefix}"):
            continue

        logging.info(subnet_name)
        conn.network.delete_subnet(subnet)


def port_filter(port, prefix, ipfilter):
    """Determine whether port is to be cleaned up:
       - If it is connected to a VM/LB/...: False
       - It it has a name that starts with the prefix: True
       - If it has a name not matching the prefix filter: False
       - If it has no name and we do not have IP range filters: True
       - Otherwise see if one of the specified IP ranges matches
    """
    if port.device_owner:
        return False
    if port.name.startswith(prefix):
        return True
    if port.name:
        return False
    if not ipfilter:
        return True
    for fixed_addr in port.fixed_ips:
        ip_addr = fixed_addr["ip_address"]
        for ipmatch in ipfilter:
            if ip_addr.startswith(ipmatch):
                logger.debug(f"{ip_addr} matches {ipmatch}")
                return True
    return False


def cleanup_ports(conn, prefix, ipfilter):
    logging.info("clean up ports")
    # FIXME: We can't filter for device_owner = '' unfortunately
    ports = list(conn.network.ports(status="DOWN"))
    for port in ports:
        if not port_filter(port, prefix, ipfilter):
            continue
        logging.info(port.id)
        conn.network.delete_port(port)


def cleanup_volumes(conn, prefix):
    logging.info("clean up volumes")
    volumes = list(conn.block_storage.volumes())
    for volume in volumes:
        volume_name = volume.to_dict()["name"]
        if not volume_name.startswith(prefix):
            continue

        logging.info(volume_name)
        conn.block_storage.delete_volume(volume)


def cleanup_servers(conn, prefix):
    logging.info("clean up servers")
    # nova supports regex filtering
    servers = list(conn.compute.servers(name=f"^{prefix}"))
    for server in servers:
        server_name = server.to_dict()["name"]
        if not server_name.startswith(prefix):
            continue

        logging.info(server_name)
        try:
            conn.compute.delete_server(server, force=True)
        except openstack.exceptions.HttpException:
            conn.compute.delete_server(server)


def wait_servers_gone(conn, prefix):
    logging.info("wait for servers to be gone")
    count = 0
    found = []
    while count < 100:
        found = []
        # nova supports regex filtering
        servers = list(conn.compute.servers(name=f"^{prefix}"))
        for server in servers:
            server_name = server.to_dict()["name"]
            if server_name.startswith(prefix):
                found.append(server_name)
        if not found:
            break
        count += 1
        time.sleep(2)

    if count >= 100:
        logging.error("timeout waiting for servers to vanish: %s" % found)


def cleanup_keypairs(conn, prefix):
    logging.info("clean up keypairs")
    keypairs = list(conn.compute.keypairs())
    for keypair in keypairs:
        keypair_name = keypair.to_dict()["name"]
        if not keypair_name.startswith(prefix):
            continue

        logging.info(keypair_name)
        conn.compute.delete_keypair(keypair)


def cleanup_security_groups(conn, prefix):
    logging.info("clean up security groups")
    for security_group in conn.network.security_groups():
        security_group_name = security_group.to_dict()["name"]
        if not security_group_name.startswith(prefix):
            continue

        logging.info(security_group_name)
        conn.network.delete_security_group(security_group)


def cleanup_floating_ips(conn, prefix):
    # Note: FIPs have no name, so we might clean up unrelated
    #  currently unused FIPs here.
    logging.info("clean up floating ips")
    floating_ips = list(conn.search_floating_ips(filters={"attached": False}))
    for floating_ip in floating_ips:
        # Do not delete if it's attached (above filter does not work)
        if floating_ip.fixed_ip_address:
            continue
        logging.info(floating_ip.name)
        conn.delete_floating_ip(floating_ip.id)


def main():
    PREFIX = os.environ.get("PREFIX", "testbed")
    OSENV = os.environ.get["OS_CLOUD"]
    if not OSENV:
        OSENV = os.environ.get["ENVIRONMENT"]
        if not OSENV:
            logging.error("Need to have OS_CLOUD or ENVIRONMENT set!")
            raise KeyError("Lacking both OS_CLOUD and ENVIRONMENT")
    PORTFILTER = os.environ.get("IPADDR").split(",")
    conn = openstack.connect(cloud=OSENV)
    cleanup_servers(conn, PREFIX)
    cleanup_keypairs(conn, PREFIX)
    wait_servers_gone(conn, PREFIX)
    cleanup_ports(conn, PREFIX, PORTFILTER)
    cleanup_volumes(conn, PREFIX)
    disconnect_routers(conn, PREFIX)
    cleanup_subnets(conn, PREFIX)
    cleanup_networks(conn, PREFIX)
    cleanup_security_groups(conn, PREFIX)
    cleanup_floating_ips(conn, PREFIX)
    cleanup_routers(conn, PREFIX)


if __name__ == "__main__":
    main()
