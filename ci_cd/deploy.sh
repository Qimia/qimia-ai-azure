set -e
die () {
    echo >&2 "$@"
    exit 1
}
[ "$#" -eq 2 ] || die "2 argument required, $# provided"
export env=$1
stack=$2
source ci_cd/init_terraform.sh $env $stack
cd "$stack"
terraform apply -input=false ../plan-artifacts/$env-$stack.tfplan
cd ..