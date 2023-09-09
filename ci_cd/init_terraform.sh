echo 'This script needs to be run with a single argument that is the environment "dev", "preprod", or "prod".'
env="$1"
stack="$2"
cd "$stack"
terraform init -backend-config="$env.tfbackend"
cd ..