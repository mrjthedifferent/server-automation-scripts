#!/bin/bash

# Load common library
source "$(dirname "$0")/../lib/common.sh"

# Initialize
init_common
log_info "🌐 Nginx Web Server Installer"
setup_logging "install-nginx"

# Main installation
update_system
install_packages nginx
enable_service nginx

log_step "Removing default site configuration..."
sudo rm -f /etc/nginx/sites-enabled/default

log_step "Testing Nginx configuration..."
sudo nginx -t

log_success "Nginx installation complete!" 