#!/bin/bash

# Load common library
source "$(dirname "$0")/../lib/common.sh"

# Initialize
init_common
log_info "🔐 Certbot (Let's Encrypt) SSL Installer"
setup_logging "install-certbot"

# Main installation
update_system
install_packages snapd

log_step "Installing certbot via snap..."
sudo snap install core && sudo snap refresh core
sudo snap install --classic certbot
sudo ln -sf /snap/bin/certbot /usr/bin/certbot

log_step "Setting up auto-renewal..."
echo "0 3 * * * /usr/bin/certbot renew --quiet" | sudo tee -a /etc/crontab > /dev/null

log_step "Verifying installation..."
certbot --version

log_success "Certbot installation and auto-renewal setup complete!"
log_info "To generate SSL certificates: sudo certbot --nginx -d yourdomain.com" 