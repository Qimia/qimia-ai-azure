#!/bin/bash
set -e
die () {
    echo >&2 "$@"
    exit 1
}
[ "$#" -eq 2 ] || die "4 arguments required, $# provided"
env=$1
stack=$2

bash ci_cd/init_terraform.sh $env $stack
cd "$stack"
terraform apply -input=false ../plan-artifacts/$env-$stack.tfplan
cd ..