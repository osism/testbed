#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = [
#     "openstacksdk>=1.0.0",
#     "PyYAML>=6.0",
# ]
# ///
"""Report resource usage from Terraform state and OpenStack.

Outputs raw counts from both sources, then a markdown table ready for
the cloud resources section of the testbed prerequisites documentation.

The markdown table uses the OpenStack counts, because quota is enforced
on the project total. That total includes what Neutron creates on its
own, such as the default security group with its rules, a router port
and a DHCP port, none of which appear in Terraform state.

OpenStack resources are attributed to the testbed by name, matching the
Terraform prefix variable (default "testbed"). Ports and floating IPs
are created without a name, so they are matched through the testbed
network instead. Anything else the project holds is reported in its own
column and left out of the table.

Requires a deployed testbed. Reads the Terraform state of the current
workspace and queries the live project.

The Terraform column derives vCPUs and RAM from the flavor name, which
keeps it an independent cross-check of the OpenStack column rather than
a second reading of the same API. This covers the SCS and OSISM naming
of the profiles the testbed is usually run on. Other providers use
schemes the pattern does not match, whether or not the name carries the
numbers at all: cah-f1a has XL.mem+, otc d2.xlarge.8, ovh c2-15 for
memory alone, cleura 4C-8GB-50GB for both. A flavor the pattern does
not match leaves the vCPU and memory rows of that column blank rather
than short, and is named in a warning. The markdown table is unaffected
either way, as it is built from the OpenStack column, which asks the
API for the size of a flavor rather than reading its name.

Usage (from repo root):
    # With uv (recommended):
    uv run contrib/resource_usage.py <cloud-name>

    # Or in the testbed venv, with openstacksdk installed:
    . venv/bin/activate
    pip3 install openstacksdk
    python3 contrib/resource_usage.py <cloud-name>

Example:
    uv run contrib/resource_usage.py regiocloud
"""

import argparse
import os
import re
import subprocess
import sys

import yaml

try:
    import openstack
except ImportError:
    print("ERROR: openstacksdk is required. Install it with:")
    print("  pip install openstacksdk")
    sys.exit(1)


TERRAFORM_DIR = os.path.join(os.path.dirname(__file__), "..", "terraform")
CLOUDS_YAML = os.path.join(TERRAFORM_DIR, "clouds.yaml")
WORKSPACE_FILE = os.path.join(TERRAFORM_DIR, ".terraform", "environment")

# make deps installs tofu into the venv, which is not on PATH under uv run
VENV_TOFU = os.path.join(os.path.dirname(__file__), "..", "venv", "bin", "tofu")
TOFU = VENV_TOFU if os.path.exists(VENV_TOFU) else "tofu"

# default of the prefix variable in terraform-base, which names the
# instances, volumes, security groups, network, subnet and router
DEFAULT_PREFIX = "testbed"

# rows of the quota table, labelled as in the prerequisites documentation
RESOURCES = [
    "Instances",
    "vCPUs",
    "RAM (GB)",
    "Volumes",
    "Volume storage (GB)",
    "Floating IPs",
    "Keypairs",
    "Security groups",
    "Security group rules",
    "Networks",
    "Subnetworks",
    "Ports",
    "Routers",
]

# rows the testbed owns outright, so both sources have to agree on them
EXACT_ROWS = [
    "Instances",
    "vCPUs",
    "RAM (GB)",
    "Volumes",
    "Volume storage (GB)",
    "Floating IPs",
    "Keypairs",
    "Networks",
    "Subnetworks",
    "Routers",
]


def workspace():
    """Return the name of the selected Terraform workspace."""
    try:
        with open(WORKSPACE_FILE, encoding="utf-8") as f:
            return f.read().strip()
    except OSError:
        return "default"


def _tofu_state_show(resource):
    """Run tofu state show and parse text output into a dict."""
    show = subprocess.run(
        [TOFU, "state", "show", resource],
        capture_output=True,
        text=True,
        cwd=TERRAFORM_DIR,
        check=False,
    )
    attrs = {}
    if show.returncode == 0:
        for line in show.stdout.splitlines():
            m = re.match(r'\s+(\w+)\s+=\s+"?([^"]*)"?', line)
            if m:
                attrs[m.group(1)] = m.group(2)
    return attrs


def get_terraform_counts():
    """Count resources in Terraform state by type.

    Returns the counts, or None when the state cannot be read, together
    with the messages explaining why.
    """
    if not os.path.isdir(TERRAFORM_DIR):
        return None, [f"[WARN] terraform directory not found: {TERRAFORM_DIR}"]

    try:
        result = subprocess.run(
            [TOFU, "state", "list"],
            capture_output=True,
            text=True,
            cwd=TERRAFORM_DIR,
            check=False,
        )
        if result.returncode != 0:
            return None, [f"[WARN] tofu state list failed: {result.stderr.strip()}"]
    except FileNotFoundError:
        return None, [f"[WARN] tofu not found: {TOFU}"]

    # tofu state list includes data sources, which are not owned resources
    lines = [
        line
        for line in result.stdout.strip().split("\n")
        if line and not line.startswith("data.")
    ]

    if not lines:
        return None, [
            f"[WARN] Terraform state of workspace '{workspace()}' is empty, "
            "so the OpenStack counts cannot be cross-checked"
        ]

    patterns = {
        "Instances": r"compute_instance_v2\.",
        "Volumes": r"blockstorage_volume_v3\.",
        "Floating IPs": r"floatingip_v2\.",
        "Keypairs": r"keypair_v2\.",
        "Security groups": r"secgroup_v2\.",
        "Security group rules": r"secgroup_rule_v2\.",
        "Networks": r"networking_network_v2\.",
        "Subnetworks": r"networking_subnet_v2\.",
        "Ports": r"networking_port_v2\.",
        "Routers": r"networking_router_v2\.",
    }

    counts = {}
    for label, pattern in patterns.items():
        counts[label] = sum(1 for line in lines if re.search(pattern, line))

    messages = []
    vcpus = 0
    ram_mb = 0
    unparsed = set()
    for line in lines:
        if "compute_instance_v2" not in line:
            continue
        attrs = _tofu_state_show(line)
        flavor = attrs.get("flavor_name", "")
        # SCS and OSISM flavor names both encode vCPUs and RAM: <n>V-<GiB>
        m = re.match(r"[A-Za-z]+-(\d+)V-(\d+)", flavor)
        if m:
            vcpus += int(m.group(1))
            ram_mb += int(m.group(2)) * 1024
        else:
            unparsed.add(flavor or "<unnamed>")

    if unparsed:
        # a sum of the instances that did parse would be a total that is
        # simply wrong, and it would disagree with OpenStack every time
        messages.append(
            "[WARN] vCPUs and RAM are left blank in the Terraform column, "
            "these flavor names are not in the SCS or OSISM naming: "
            + ", ".join(sorted(unparsed))
        )

    counts["vCPUs"] = None if unparsed else vcpus
    counts["RAM (GB)"] = None if unparsed else ram_mb // 1024

    total_gb = 0
    for line in lines:
        if "blockstorage_volume_v3" not in line:
            continue
        attrs = _tofu_state_show(line)
        size = attrs.get("size", "0")
        total_gb += int(size)

    counts["Volume storage (GB)"] = total_gb

    return counts, messages


def _flavor_totals(conn, servers):
    """Return the vCPUs and GB of RAM of the given servers."""
    vcpus = 0
    ram_mb = 0
    seen = {}
    for server in servers:
        flavor_id = server.flavor["id"]
        if flavor_id not in seen:
            seen[flavor_id] = conn.compute.find_flavor(flavor_id)
        flavor = seen[flavor_id]
        if flavor:
            vcpus += flavor.vcpus
            ram_mb += flavor.ram
    return vcpus, ram_mb // 1024


def get_openstack_counts(conn, prefix):
    """Count the project's resources, split by whether they are the testbed.

    Returns the counts of the testbed itself and of everything else in
    the project. Terraform names instances, volumes, security groups,
    the network, the subnet and the router after the prefix variable.
    Ports and floating IPs are created without a name and are matched
    through the testbed network instead.
    """

    def named(name):
        return bool(name) and prefix in name

    project_id = conn.current_project_id

    servers = list(conn.compute.servers())
    volumes = list(conn.block_storage.volumes())
    keypairs = list(conn.compute.keypairs())
    groups = list(conn.network.security_groups())
    networks = list(conn.network.networks(project_id=project_id))
    subnets = list(conn.network.subnets(project_id=project_id))
    ports = list(conn.network.ports(project_id=project_id))
    routers = list(conn.network.routers(project_id=project_id))
    floating_ips = list(conn.network.ips())

    tb_servers = [s for s in servers if named(s.name)]
    tb_volumes = [v for v in volumes if named(v.name)]
    tb_keypairs = [k for k in keypairs if named(k.name)]
    tb_networks = [n for n in networks if named(n.name)]
    tb_routers = [r for r in routers if named(r.name)]

    network_ids = {n.id for n in tb_networks}
    tb_subnets = [s for s in subnets if s.network_id in network_ids]
    tb_ports = [p for p in ports if p.network_id in network_ids]
    port_ids = {p.id for p in tb_ports}
    tb_floating_ips = [f for f in floating_ips if f.port_id in port_ids]

    tb_groups = [g for g in groups if named(g.name)]
    if tb_groups:
        # the project's default group is not the testbed's, but it exists
        # in every project and its rules count against the same quota
        tb_groups += [g for g in groups if g.name == "default"]

    def tally(
        servers_,
        volumes_,
        keypairs_,
        groups_,
        networks_,
        subnets_,
        ports_,
        routers_,
        floating_ips_,
    ):
        vcpus, ram = _flavor_totals(conn, servers_)
        return {
            "Instances": len(servers_),
            "Nodes": sum(1 for s in servers_ if "-node" in (s.name or "")),
            "vCPUs": vcpus,
            "RAM (GB)": ram,
            "Volumes": len(volumes_),
            "Volume storage (GB)": sum(v.size for v in volumes_),
            "Floating IPs": len(floating_ips_),
            "Keypairs": len(keypairs_),
            "Security groups": len(groups_),
            "Security group rules": sum(len(g.security_group_rules) for g in groups_),
            "Networks": len(networks_),
            "Subnetworks": len(subnets_),
            "Ports": len(ports_),
            "Routers": len(routers_),
        }

    testbed = tally(
        tb_servers,
        tb_volumes,
        tb_keypairs,
        tb_groups,
        tb_networks,
        tb_subnets,
        tb_ports,
        tb_routers,
        tb_floating_ips,
    )

    def others(all_, testbed_):
        ids = {r.id for r in testbed_}
        return [r for r in all_ if r.id not in ids]

    other = tally(
        others(servers, tb_servers),
        others(volumes, tb_volumes),
        [k for k in keypairs if k not in tb_keypairs],
        others(groups, tb_groups),
        others(networks, tb_networks),
        others(subnets, tb_subnets),
        others(ports, tb_ports),
        others(routers, tb_routers),
        others(floating_ips, tb_floating_ips),
    )

    return testbed, other


def print_comparison(tf_counts, os_counts, other_counts):
    """Print a comparison table."""
    print("\nComparison\n")
    header = f"  {'Resource':<21}  {'Terraform':>10}  {'OpenStack':>10}  {'Other':>10}"
    print(header)
    print("  " + "-" * (len(header) - 2))

    def cell(counts, resource):
        value = counts.get(resource) if counts else None
        return "-" if value is None else value

    for resource in RESOURCES:
        tf_val = cell(tf_counts, resource)
        os_val = cell(os_counts, resource)
        other_val = cell(other_counts, resource)
        print(f"  {resource:<21}  {tf_val:>10}  {os_val:>10}  {other_val:>10}")


def print_legend(prefix):
    """Explain what the columns of the comparison hold."""
    print()
    print(f"  Terraform   tracked in the Terraform state of workspace {workspace()!r}")
    print(f"  OpenStack   the deployed testbed, matched by the name {prefix!r},")
    print("              plus the default security group of the project")
    print("  Other       everything else in the project, which is not part of")
    print("              the testbed and is left out of the table")


def collect_warnings(tf_counts, os_counts, other_counts, prefix):
    """Report anything that makes the counts unfit for the documentation."""
    messages = []

    if not os_counts["Instances"]:
        # nothing matched, so the Other column holds the whole project
        # and there is nothing left to say about it
        messages.append(
            f"[WARN] no OpenStack resources named after {prefix!r} in this "
            "project, is the testbed deployed?"
        )
        return messages

    if tf_counts:
        differing = [
            f"{row} ({tf_counts.get(row)} vs {os_counts.get(row)})"
            for row in EXACT_ROWS
            if tf_counts.get(row) is not None
            and tf_counts.get(row) != os_counts.get(row)
        ]
        if differing:
            messages.append(
                "[WARN] Terraform and OpenStack disagree on: " + ", ".join(differing)
            )

    if any(other_counts[row] for row in RESOURCES):
        messages.append(
            f"[NOTE] the project holds resources not named after {prefix!r}, "
            "counted as Other above and left out of the table"
        )

    return messages


def print_prereqs_table(os_counts):
    """Print a markdown table for the prerequisites documentation.

    Uses OpenStack counts because quotas are enforced on the project
    total, not just Terraform-managed resources.
    """
    instances = os_counts["Instances"]
    nodes = os_counts["Nodes"]
    managers = instances - nodes
    note = f"{os_counts['vCPUs']} VCPUs + {os_counts['RAM (GB)']} GByte RAM"
    if nodes and managers:
        note += f" ({nodes} nodes, {managers} manager)"

    rows = [
        ("Instances", str(instances), note),
        (
            "Volumes",
            str(os_counts["Volumes"]),
            f"{os_counts['Volume storage (GB)']} GByte volume storage",
        ),
        ("Floating IPs", str(os_counts["Floating IPs"]), ""),
        ("Keypairs", str(os_counts["Keypairs"]), ""),
        ("Security groups", str(os_counts["Security groups"]), ""),
        ("Security group rules", str(os_counts["Security group rules"]), ""),
        ("Networks", str(os_counts["Networks"]), ""),
        ("Subnetworks", str(os_counts["Subnetworks"]), ""),
        ("Ports", str(os_counts["Ports"]), ""),
        ("Routers", str(os_counts["Routers"]), ""),
    ]

    note_width = max(len(note) for _, _, note in rows)
    note_width = max(note_width, 4)  # at least as wide as "Note"

    print("\n## Markdown for the prerequisites documentation\n")
    print(f"| Resource             | Quantity | {'Note':<{note_width}} |")
    print(f"|:---------------------|:---------|:{'-' * (note_width + 1)}|")
    for label, qty, text in rows:
        print(f"| {label:<20} | {qty:<8} | {text:<{note_width}} |")


def detect_clouds():
    """Return the clouds of the testbed clouds.yaml, if there is one.

    A testbed driven from this checkout keeps its credentials there. In
    CI they come from the configuration openstacksdk finds on its own
    and the file does not exist, which is not an error.
    """
    if not os.path.exists(CLOUDS_YAML):
        return []

    with open(CLOUDS_YAML, encoding="utf-8") as f:
        data = yaml.safe_load(f)

    clouds = list(data.get("clouds", {}).keys())
    if not clouds:
        print(f"ERROR: No clouds defined in {CLOUDS_YAML}.")
        sys.exit(1)

    return clouds


def main():
    """Parse arguments and report resource usage."""
    available = detect_clouds()
    if len(available) == 1:
        default_cloud = available[0]
    else:
        default_cloud = os.environ.get("OS_CLOUD")

    parser = argparse.ArgumentParser(
        description="Report resource usage from Terraform and OpenStack"
    )
    parser.add_argument(
        "cloud",
        nargs="?",
        default=default_cloud,
        help=(
            f"Cloud name (available: {', '.join(available)})"
            if available
            else "Cloud name, as openstacksdk knows it"
        ),
    )
    parser.add_argument(
        "--prefix",
        default=DEFAULT_PREFIX,
        help=f"Terraform prefix naming the testbed (default: {DEFAULT_PREFIX})",
    )
    args = parser.parse_args()

    if not args.cloud:
        if available:
            print(f"ERROR: Multiple clouds found, specify one: {', '.join(available)}")
        else:
            print(f"ERROR: No {CLOUDS_YAML} and no OS_CLOUD, name the cloud.")
        sys.exit(1)

    if available and args.cloud not in available:
        print(f"ERROR: Cloud '{args.cloud}' not found in {CLOUDS_YAML}.")
        print(f"Available: {', '.join(available)}")
        sys.exit(1)

    if available:
        os.environ["OS_CLIENT_CONFIG_FILE"] = CLOUDS_YAML

    conn = openstack.connect(cloud=args.cloud)

    print(f"cloud {args.cloud}, workspace {workspace()}, prefix {args.prefix}")

    tf_counts, messages = get_terraform_counts()
    os_counts, other_counts = get_openstack_counts(conn, args.prefix)

    print_comparison(tf_counts, os_counts, other_counts)
    print_legend(args.prefix)

    if tf_counts and args.cloud != workspace():
        messages.append(
            f"[WARN] the Terraform column is the state of workspace "
            f"{workspace()!r}, which is not the cloud {args.cloud!r} queried "
            "for the OpenStack column"
        )

    messages += collect_warnings(tf_counts, os_counts, other_counts, args.prefix)
    if messages:
        print()
        for message in messages:
            print(message)

    if os_counts["Instances"]:
        print_prereqs_table(os_counts)
    else:
        print(
            f"\nNo markdown table: nothing in this project is named after "
            f"{args.prefix!r}, so there is no testbed to describe."
        )


if __name__ == "__main__":
    main()
