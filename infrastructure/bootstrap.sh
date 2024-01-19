set -e
echo "Bootstrap path: $(pwd)"
echo "User: $USER"

sudo apt update && sudo apt install -y docker.io postgresql-client-common postgresql-client-12 wget curl
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit nvidia-docker2
sudo systemctl restart docker
sudo apt-get install ubuntu-drivers-common && sudo ubuntu-drivers autoinstall
curl -s -L https://nvidia.github.io/nvidia-container-runtime/gpgkey | sudo apt-key add -
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-container-runtime/$distribution/nvidia-container-runtime.list | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-runtime.list
sudo apt-get update
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
/usr/local/bin/docker-compose down || true
docker container stop $(docker container ls -aq) || true
docker container rm $(docker container ls -aq) || true
docker image rm $(docker image ls -q) || true
/usr/local/bin/docker-compose pull
/usr/local/bin/docker-compose up --detach
sleep 10
docker image prune -f