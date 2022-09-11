
echo "Set Repos"
wget https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb

wget https://packages.microsoft.com/config/ubuntu/18.04/multiarch/prod.list -O microsoft-prod.list
sudo cp ./microsoft-prod.list /etc/apt/sources.list.d/

curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo cp ./microsoft.gpg /etc/apt/trusted.gpg.d/

echo "Update Repo"
sudo apt-get update -y

echo "Install container engine"
sudo apt-get install moby-engine -y

echo "Install iot edge"
sudo apt-get install aziot-identity-service aziot-edge defender-iot-micro-agent-edge -y