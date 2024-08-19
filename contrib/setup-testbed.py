#!/usr/bin/env python3

# SPDX-License-Identifier: Apache-2.0

import argparse
import subprocess
import sys
import yaml
import os
import time


def lookup(yaml_path: str, local_data: dict) -> None | str | dict:
    for bread_crumb in yaml_path.split("."):
        if bread_crumb in local_data.keys():
            local_data = local_data[bread_crumb]
        else:
            local_data = None
            break
    return local_data


def check_environment(name: str, cloud: str) -> None:
    def _check_file(filename: str, name: str):
        if not os.path.exists(filename):
            raise RuntimeError(
                f"There is no file {filename}, create one by using {filename}.sample as template"
            )

        with open(filename, "r") as file:
            cloud_path = f"clouds.{name}"
            data_local = yaml.safe_load(file)
            envs = ", ".join(data_local["clouds"].keys())

            if name == "the_environment":
                raise RuntimeError(
                    f"you have to specify a name below the 'clouds' element in '{filename}', configured environments are: {envs} (set it with ENVIRONMENT=...)"
                )

            if lookup(cloud_path, data_local) is None:
                raise RuntimeError(
                    f"no such key '{cloud_path}' in '{filename}', configured environments are: {envs} (set it with ENVIRONMENT=...)"
                )

    try:
        _check_file("terraform/clouds.yaml", cloud)
    except Exception as e:
        print(e)
        sys.exit(1)

    # TODO: as discussed in https://github.com/osism/testbed/pull/1879 we add a app credential check later
    # to make a smart distinction if that check is needed or not.
    try:
        _check_file("terraform/secure.yaml", cloud)
    except Exception as e:
        print(e)
        time.sleep(2)

    sys.exit(0)


def create_directories(directory_path: str) -> None:
    if not os.path.exists(directory_path):
        os.makedirs(directory_path)
        print(f"Directory '{directory_path}' created.")


def clone_repo(path: str, repo_address: str, branch: str) -> None:
    checkout_path = f".src/{path.strip('/')}"
    print(checkout_path)
    print(os.path.dirname(checkout_path))
    create_directories(os.path.dirname(checkout_path))
    if not os.path.exists(checkout_path):
        repo_command = f"git clone {repo_address} {checkout_path}"
        print(f"+ {repo_command}")
        subprocess.check_output(repo_command, shell=True)

    repo_command = f"git -C {checkout_path} checkout 'main'"
    print(f"+ {repo_command}")
    subprocess.check_output(repo_command, shell=True)

    repo_command = f"git -C {checkout_path} pull"
    print(f"+ {repo_command}")
    subprocess.check_output(repo_command, shell=True)

    if branch and branch != "main":
        repo_command = f"git -C {checkout_path} checkout {branch}"
        print(f"+ {repo_command}")
        subprocess.check_output(repo_command, shell=True)


basedir = os.path.realpath(os.path.dirname(os.path.realpath(__file__)) + "/../")
file_path = f"{basedir}/playbooks/vars/repositories.yml"

os.chdir(basedir)

parser = argparse.ArgumentParser(
    prog="Setup the testbed",
    description="This make the implementation and execution of setup task less painful",
)

parser.add_argument(
    "--config",
    help="the clouds.yaml config file",
    required=False,
    default=file_path,
)
parser.add_argument(
    "--query",
    help="specify a path to the config item seperated by dots",
    required=False,
)
parser.add_argument("--prepare", action="store_true")
parser.add_argument(
    "--environment",
    help="check if specified environment is okay",
    required=False,
)
parser.add_argument(
    "--cloud",
    help="check if specified cloud is okay",
    required=False,
)

args = parser.parse_args()

try:
    assert sys.version_info >= (3, 10)
except AssertionError:
    print("ERROR: Python version >= 3.10 is required to work with the OSISM Testbed.")
    print()
    print(f"Your version: {sys.version}")
    print()
    print("Further details in the Ansible support matrix:")
    print(
        "https://docs.ansible.com/ansible/latest/reference_appendices/release_and_maintenance.html#ansible-core-support-matrix"
    )
    sys.exit(1)

with open(args.config, "r") as file:
    data = yaml.safe_load(file)

if args.environment:
    check_environment(args.environment, args.cloud)
elif args.query:
    sys.stdout.write(lookup(args.query, data))
elif args.prepare:
    print("** Create repository directories")
    for key, item_data in data["repositories"].items():
        print(f"-> {key}")
        clone_repo(
            path=item_data["path"],
            repo_address=item_data["repo"],
            branch=item_data.get("branch"),
        )

    print("** Replicate to terraform folder")
    command = f"rsync -avz .src/{lookup('repositories.terraform-base.path', data)}/testbed-default/ terraform"
    print(f"+ {command}")
    subprocess.check_output(command, shell=True)
