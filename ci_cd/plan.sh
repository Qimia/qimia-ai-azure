set -e
die () {
    echo >&2 "$@"
    exit 1
}
[ "$#" -eq 2 ] || die "2 argument required, $# provided"
env="$1"
stack="$2"

source ci_cd/init_terraform.sh $env $stack
mkdir -p plan-artifacts
cd "$stack"
export TF_VAR_env="$env"
terraform --version
terraform plan -out="../plan-artifacts/$env-$stack.tfplan" -var-file="$env.tfvars"
cd ..