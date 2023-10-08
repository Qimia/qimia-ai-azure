#!/bin/bash
set -e
[ "$#" -eq 2 ] || die "This scripts needs to be run with two parameters env and the stack for example 'sh init_terraform.sh dev infrastructure'"
env="$1"
stack="$2"
cd "$stack"
echo "Initializing Terraform"
terraform init -backend-config="${env}.tfbackend" -reconfigure
cd ..