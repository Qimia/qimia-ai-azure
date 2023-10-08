set -e

apt update && apt install -y docker.io docker-compose postgresql-client-common postgresql-client-12 wget curl
wget -O azcopy.tar.gz https://aka.ms/downloadazcopy-v10-linux
tar -xvf azcopy.tar.gz
rm azcopy.tar.gz
rm /usr/bin/azcopy || true
cp ./azcopy_linux_amd64_*/azcopy /usr/bin/

whoami >> /home/ai_admin/init_user.txt

curl -sL https://aka.ms/InstallAzureCLIDeb | bash
usermod -aG docker ai_admin
az login --identity
echo "logged in."
docker-compose down || true
docker container stop $(docker container ls -aq) || true
docker container rm $(docker container ls -aq) || true
az acr login -n qimiaai27da
docker-compose pull
docker-compose up --detach
docker image prune -f