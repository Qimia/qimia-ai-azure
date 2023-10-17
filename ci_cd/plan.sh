#!/bin/bash
set -e
die () {
    echo >&2 "$@"
    exit 1
}

[ "$#" -eq 2 ] || die "This scripts needs to be run with two parameters env and the stack for example 'sh plan.sh dev infrastructure qimia-ai-dev devopsimiaaidev'"

env="$1"
stack="$2"

bash ci_cd/init_terraform.sh "$env" "$stack"
mkdir -p plan-artifacts
cd "$stack"
echo "Planning"
TF_VARIABLES_PATH="${TF_VARIABLES_PATH:-$env.tfvars}"  # If TF_BACKEND_CONFIG_PATH not defined take the $end.tfvars instead.
echo "TF variables path $TF_VARIABLES_PATH"
terraform plan  -out="../plan-artifacts/$env-$stack.tfplan" -var-file="$TF_VARIABLES_PATH"
cd ..