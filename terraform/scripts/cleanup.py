#!/usr/bin/env python3

import logging
import os

import openstack

logging.basicConfig(format='%(asctime)s - %(message)s', level=logging.INFO,
                    datefmt='%Y-%m-%d %H:%M:%S')


def cleanup_routers(conn):
    logging.info("clean up routers")
    for router in conn.network.routers():
        router_dict = router.to_dict()
        router_name = router_dict["name"]

        if not router_name.startswith("testbed"):
            continue

        logging.info(router_name)

        conn.network.remove_gateway_from_router(router_dict["id"])

        for port in conn.network.ports(device_id=router_dict["id"]):
            conn.network.remove_interface_from_router(router_dict["id"],
                                                      port_id=port["id"])

        conn.network.delete_router(router_dict["id"])


def cleanup_networks(conn):
    logging.info("clean up networks")
    for network in conn.network.networks():
        network_dict = network.to_dict()
        network_name = network_dict["name"]

        if not network_name.startswith("net-testbed"):
            continue

        logging.info(network_name)
        conn.network.delete_network(network_dict["id"])


def cleanup_ports(conn):
    logging.info("clean up ports")
    for port in conn.network.ports():
        port_dict = port.to_dict()
        port_status = port_dict["status"]
        port_device_owner = port_dict["device_owner"]

        if not port_status == "DOWN" or port_device_owner != "":
            continue

        logging.info(port_dict["id"])
        conn.network.delete_port(port_dict["id"])


def cleanup_volumes(conn):
    logging.info("clean up volumes")
    for volume in conn.block_storage.volumes():
        volume_dict = volume.to_dict()
        volume_name = volume_dict["name"]

        if not volume_name.startswith("testbed"):
            continue

        logging.info(volume_name)
        conn.block_storage.delete_volume(volume_dict["id"])


def cleanup_servers(conn):
    logging.info("clean up servers")
    for server in conn.compute.servers():
        server_dict = server.to_dict()
        server_name = server_dict["name"]

        if not server_name.startswith("testbed"):
            continue

        logging.info(server_name)
        conn.compute.delete_server(server_dict["id"], force=True)


def cleanup_keypairs(conn):
    logging.info("clean up keypairs")
    for keypair in conn.compute.keypairs():
        keypair_dict = keypair.to_dict()
        keypair_name = keypair_dict["name"]

        if not keypair_name.startswith("testbed"):
            continue

        logging.info(keypair_name)
        conn.compute.delete_keypair(keypair)


def cleanup_security_groups(conn):
    logging.info("clean up security groups")
    for security_group in conn.network.security_groups():
        security_group_dict = security_group.to_dict()
        security_group_name = security_group_dict["name"]

        if not security_group_name.startswith("testbed"):
            continue

        logging.info(security_group_name)
        conn.network.delete_security_group(security_group)


def cleanup_floating_ips(conn):
    logging.info("clean up floating ips")
    for floating_ip in conn.search_floating_ips():
        floating_ip_dict = dict(floating_ip)
        floating_ip_name = floating_ip["floating_ip_address"]

        if not floating_ip_dict["attached"]:
            logging.info(floating_ip_name)
            conn.delete_floating_ip(floating_ip_dict["id"])


def main():
    conn = openstack.connect(cloud=os.environ['ENVIRONMENT'])
    cleanup_servers(conn)
    cleanup_volumes(conn)
    cleanup_ports(conn)
    cleanup_routers(conn)
    cleanup_networks(conn)
    cleanup_keypairs(conn)
    cleanup_security_groups(conn)
    cleanup_floating_ips(conn)


if __name__ == '__main__':
    main()
