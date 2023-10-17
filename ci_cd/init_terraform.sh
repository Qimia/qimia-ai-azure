#!/bin/bash
set -e
die () {
    echo >&2 "$@"
    exit 1
}
[ "$#" -eq 2 ] || die "This scripts needs to be run with two parameters env and the stack for example 'sh init_terraform.sh dev infrastructure'"
env="$1"
stack="$2"

TF_BACKEND_CONFIG_PATH="${TF_BACKEND_CONFIG_PATH:-$env.tfbackend}"  # If TF_BACKEND_CONFIG_PATH not defined take the $end.tfvars instead.
echo "TF backend config path $TF_BACKEND_CONFIG_PATH"
cd "$stack"
terraform init -backend-config="$TF_BACKEND_CONFIG_PATH" -reconfigure
cd ..