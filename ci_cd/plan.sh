#!/bin/bash
set -e
die () {
    echo >&2 "$@"
    exit 1
}

[ "$#" -eq 4 ] || die "This scripts needs to be run with two parameters env and the stack for example 'sh plan.sh dev infrastructure qimia-ai-dev devopsimiaaidev'"

env="$1"
stack="$2"
resource_group_name="$3"
storage_account_name="$4"

export TF_VAR_env="$env"
export TF_VAR_resource_group_name="$resource_group_name"
export TF_VAR_storage_account_name="$storage_account_name"

bash ci_cd/init_terraform.sh "$env" "$stack" "$resource_group_name" "$storage_account_name"
mkdir -p plan-artifacts
cd "$stack"
echo "Planning"
terraform plan -out="../plan-artifacts/$env-$stack.tfplan"
cd ..