set -e
aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws/h7r6l8b8
echo "Building the image"
ECR_TAG="public.ecr.aws/h7r6l8b8/tfenv-azurecli:latest"
docker image build --tag "$ECR_TAG" .
docker push "$ECR_TAG"