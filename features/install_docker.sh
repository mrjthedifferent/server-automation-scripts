#!/bin/bash

# Load common library
source "$(dirname "$0")/../lib/common.sh"

# Initialize
init_common
log_info "🐳 Docker & Docker Compose Installer"
setup_logging "install-docker"

log_step "Updating system packages..."
sudo apt update

log_step "Installing dependencies..."
sudo apt install -y ca-certificates curl gnupg lsb-release

log_step "Adding Docker's official GPG key..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

log_step "Setting up Docker repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

log_step "Installing Docker Engine..."
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

log_step "Starting and enabling Docker service..."
sudo systemctl enable docker
sudo systemctl start docker

log_step "Adding current user to docker group..."
sudo usermod -aG docker $USER

log_step "Installing Docker Compose (standalone)..."
DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d '"' -f 4)
sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

log_success "Docker and Docker Compose installed successfully!"
echo "🔄 Please log out and log back in for group changes to take effect."
echo "🐳 Docker version: $(docker --version)"
echo "🔧 Docker Compose version: $(docker-compose --version)" 