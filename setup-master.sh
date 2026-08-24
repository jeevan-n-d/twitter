#!/bin/bash

set -e

echo "========================================"
echo "Updating system"
echo "========================================"

sudo apt update -y
sudo apt upgrade -y


# ============================================================
# DOCKER
# ============================================================

echo "========================================"
echo "Installing Docker dependencies"
echo "========================================"

sudo apt install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release


echo "========================================"
echo "Adding Docker GPG key"
echo "========================================"

sudo mkdir -p /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg


echo "========================================"
echo "Adding Docker repository"
echo "========================================"

echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null


echo "========================================"
echo "Installing Docker"
echo "========================================"

sudo apt update -y

sudo apt install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin


echo "========================================"
echo "Starting Docker"
echo "========================================"

sudo systemctl enable docker
sudo systemctl start docker


echo "========================================"
echo "Adding current user to Docker group"
echo "========================================"

sudo usermod -aG docker "$USER"


echo "========================================"
echo "Docker verification"
echo "========================================"

sudo docker --version
sudo docker compose version


echo "========================================"
echo "Testing Docker"
echo "========================================"

sudo docker run hello-world


# ============================================================
# FINAL
# ============================================================

echo "========================================"
echo "MASTER HOST SETUP COMPLETED"
echo "========================================"

echo ""
echo "Installed:"
echo "✓ Docker"
echo "✓ Docker Compose"
echo ""

echo "IMPORTANT:"
echo "Log out and log back in for Docker group permissions."
echo ""

echo "After reconnecting, run:"
echo "docker ps"
echo "docker --version"
echo "docker compose version"