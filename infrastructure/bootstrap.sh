set -e
echo "Bootstrap path: $(pwd)"
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
az acr login -n qimiaai27da  || true # It's okay to fail silently here. We'd find out in the next step anyway
docker-compose pull
docker-compose up --detach
sleep 90
echo "Sleep finished"
docker container ls -a
docker logs $(docker container ls -qa -f name=.*model.*) || true
docker image prune -f
exit 1;