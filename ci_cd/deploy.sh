#!/bin/bash
set -e
die () {
    echo >&2 "$@"
    exit 1
}
[ "$#" -eq 4 ] || die "4 arguments required, $# provided"
env=$1
stack=$2
resource_group_name="$3"
storage_account_name="$4"

bash ci_cd/init_terraform.sh $env $stack $resource_group_name $storage_account_name
cd "$stack"
terraform apply -input=false ../plan-artifacts/$env-$stack.tfplan
cd ..