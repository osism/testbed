#!/usr/bin/env python3
import argparse
import subprocess
import sys

import yaml
import os


def lookup(yaml_path: str, local_data: dict) -> None | str | dict:
    for bread_crumb in yaml_path.split("."):
        if bread_crumb in local_data.keys():
            local_data = local_data[bread_crumb]
        else:
            local_data = None
            break
    return local_data


def check_environment(name: str) -> None:
    def _check_file(filename: str, name: str):
        if not os.path.exists(filename):
            raise RuntimeError(f"There is no file {filename}, create one by using {filename}.sample")
        with open(filename, 'r') as file:
            data_local = yaml.safe_load(file)
            if lookup(name, data_local) is None:
                raise RuntimeError(f"no such key '{name}' in {filename}")
    try:
        _check_file("terraform/clouds.yaml", f"clouds.{name}")
        _check_file("terraform/secure.yaml", f"clouds.{name}")
    except Exception as e:
        print(e)
        sys.exit(1)
    sys.exit(0)


def create_directory(directory_path: str) -> None:
    if not os.path.exists(directory_path):
        os.makedirs(directory_path)
        print(f"Directory '{directory_path}' created.")


def clone_repo(path: str, url: str) -> None:
    create_directory(path)
    checkout_path = f".src/{path}/"
    repo_command = f"git -C {checkout_path} pull"
    if not os.path.exists(path):
        repo_command = f"git clone {url} {checkout_path}"
    print(f"+ {repo_command}")
    subprocess.check_output(repo_command, shell=True)


basedir = os.path.realpath(os.path.dirname(os.path.realpath(__file__)) + "/../")
file_path = f"{basedir}/playbooks/vars/repositories.yml"

os.chdir(basedir)

parser = argparse.ArgumentParser(
    prog='Setup the testbed',
    description='This make the implementation and execution of setup task less painful')

parser.add_argument('-c', '--config',
                    help='the cloud.yaml config file',
                    required=False,
                    default=file_path)
parser.add_argument('-q', '--query',
                    help='specify a path to the config item seperated by dots',
                    required=False,
                    )
parser.add_argument('--prepare',
                    action='store_true')

parser.add_argument('-e', '--environment_check',
                    help='check if specified environment is okay',
                    required=False,
                    )

args = parser.parse_args()

with open(args.config, 'r') as file:
    data = yaml.safe_load(file)

if args.environment_check:
    check_environment(args.environment_check)
elif args.query:
    sys.stdout.write(lookup(args.query, data))
elif args.prepare:
    print("** Create directories")
    for key, item_data in data["repositories"].items():
        print(f"-> {key}")
        clone_repo(item_data["path"], item_data["repo"])

    print("** Replicate to terraform folder")
    command = f"rsync -avz .src/{lookup('repositories.terraform-base.path', data)}/testbed-default/ terraform"

    print(f"+ {command}")
    subprocess.check_output(command, shell=True)
