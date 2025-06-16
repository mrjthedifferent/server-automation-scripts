#!/bin/bash

# Load common library
source "$(dirname "$0")/../lib/common.sh"

# Initialize
init_common
log_info "🐳 Docker & Docker Compose Installer"
setup_logging "install-docker"

log_step "Removing conflicting packages..."
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do 
    sudo apt-get remove -y $pkg 2>/dev/null || true
done

log_step "Updating system packages..."
sudo apt-get update

log_step "Installing dependencies..."
sudo apt-get install -y ca-certificates curl

log_step "Adding Docker's official GPG key..."
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

log_step "Setting up Docker repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

log_step "Installing Docker Engine..."
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

log_step "Starting and enabling Docker service..."
sudo systemctl enable docker
sudo systemctl start docker

log_step "Adding current user to docker group..."
sudo usermod -aG docker $USER

log_step "Verifying Docker installation..."
if sudo docker run --rm hello-world >/dev/null 2>&1; then
    log_success "Docker installation verified successfully!"
else
    log_error "Docker installation verification failed!"
    exit 1
fi

log_success "Docker and Docker Compose installed successfully!"
echo "🔄 Please log out and log back in for group changes to take effect."
echo "🐳 Docker version: $(docker --version 2>/dev/null || sudo docker --version)"
echo "🔧 Docker Compose version: $(docker compose version 2>/dev/null || sudo docker compose version)"
echo ""
echo "💡 Note: After logging out and back in, you can run Docker commands without sudo."
echo "💡 The standalone docker-compose command is replaced by 'docker compose' (with space)." 