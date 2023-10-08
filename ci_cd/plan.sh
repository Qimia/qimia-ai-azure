#!/bin/bash
set -e
die () {
    echo >&2 "$@"
    exit 1
}

[ "$#" -eq 2 ] || die "This scripts needs to be run with two parameters env and the stack for example 'sh plan.sh dev infrastructure'"

env="$1"
stack="$2"

export TF_VAR_env="$env"

bash ci_cd/init_terraform.sh $env $stack
mkdir -p plan-artifacts
cd "$stack"
echo "Planning"
terraform plan -out="../plan-artifacts/$env-$stack.tfplan" -var-file="$env.tfvars"
cd ..