#!/bin/bash
set -e
die () {
    echo >&2 "$@"
    exit 1
}
[ "$#" -eq 4 ] || die "This scripts needs to be run with two parameters env and the stack for example 'sh init_terraform.sh dev infrastructure'"
env="$1"
stack="$2"
resource_group_name="$3"
storage_account_name="$4"
cd "$stack"
echo "Initializing Terraform"

cp ".tfbackend" "${env}.tfbackend"
echo "" >> "${env}.tfbackend"
echo 'resource_group_name = "'"$resource_group_name"'"' >> "${env}.tfbackend"
echo 'storage_account_name = "'"$storage_account_name"'"' >> "${env}.tfbackend"
terraform init -backend-config="${env}.tfbackend" -reconfigure
cd ..