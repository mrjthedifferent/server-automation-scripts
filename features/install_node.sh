#!/bin/bash

# Load common library
source "$(dirname "$0")/../lib/common.sh"

# Initialize
init_common
log_info "🟢 Node.js & npm Installer"
setup_logging "install-node"

# Main installation
update_system
install_packages curl

log_step "Adding NodeSource repository..."
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -

log_step "Installing Node.js..."
install_packages nodejs

log_step "Verifying installation..."
node -v && npm -v

log_success "Node.js and npm installation complete!" 