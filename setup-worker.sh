#!/bin/bash

set -e

echo "========================================"
echo "Updating system"
echo "========================================"

sudo apt update -y
sudo apt upgrade -y


echo "========================================"
echo "Installing Java 17"
echo "========================================"

sudo apt install -y openjdk-17-jdk


echo "========================================"
echo "Installing Maven, Git and utilities"
echo "========================================"

sudo apt install -y maven git curl unzip


echo "========================================"
echo "Checking Java and Maven"
echo "========================================"

java -version
mvn -version


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
# AWS CLI
# ============================================================

echo "========================================"
echo "Installing AWS CLI v2"
echo "========================================"

cd /tmp

curl -fsSL \
    "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
    -o awscliv2.zip

rm -rf aws

unzip -q awscliv2.zip

sudo ./aws/install --update

rm -rf aws awscliv2.zip


echo "========================================"
echo "Checking AWS CLI"
echo "========================================"

aws --version


# ============================================================
# KUBECTL
# ============================================================

echo "========================================"
echo "Installing kubectl"
echo "========================================"

cd /tmp

KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)

curl -LO \
    "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"

sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

rm -f kubectl


echo "========================================"
echo "Checking kubectl"
echo "========================================"

kubectl version --client


# ============================================================
# FINAL
# ============================================================

echo "========================================"
echo "WORKER SETUP COMPLETED"
echo "========================================"

echo ""
echo "Installed:"
echo "✓ Java 17"
echo "✓ Maven"
echo "✓ Git"
echo "✓ Docker"
echo "✓ Docker Compose"
echo "✓ AWS CLI v2"
echo "✓ kubectl"
echo ""
echo "IMPORTANT:"
echo "Log out and log back in for Docker group permissions."
echo ""
echo "After reconnecting, run:"
echo "docker ps"
echo "docker --version"
echo "mvn -version"
echo "java -version"
echo "aws --version"
echo "kubectl version --client"