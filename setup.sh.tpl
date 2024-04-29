#!/bin/bash

# Update package lists
apt update 

# Upgrade existing packages
apt upgrade -y

# Install prerequisite packages for HTTPS support
apt install apt-transport-https ca-certificates curl software-properties-common -y

# Install git
apt install git -y

# Add Docker's official GPG key:
apt update
apt install ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update

sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

# Clone the repository and change directory
cd /home/demousr

sudo git clone https://github.com/HelloDanielWorld/GithubRunnerScript.git

cd GithubRunnerScript

echo "REPO=${REPO}" >> .env
echo "TOKEN=${TOKEN}" >> .env

sudo docker compose up -d