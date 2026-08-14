#!/bin/bash

set -e

echo "Updating system..."
sudo apt update -y
sudo apt upgrade -y

echo "Installing Docker dependencies..."
sudo apt install -y ca-certificates curl gnupg lsb-release

echo "Adding Docker GPG key..."
sudo mkdir -p /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo "Adding Docker repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "Installing Docker..."
sudo apt update -y

sudo apt install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

echo "Starting Docker..."
sudo systemctl enable docker
sudo systemctl start docker

echo "Adding current user to Docker group..."
sudo usermod -aG docker $USER

echo "Verifying Docker..."
sudo docker --version

echo "Verifying Docker Compose..."
sudo docker compose version

echo "Testing Docker..."
sudo docker run hello-world

echo ""
echo "Docker installation completed!"
echo "Log out and log back in for Docker group permissions to take effect."