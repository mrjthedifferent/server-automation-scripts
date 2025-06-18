#!/bin/bash

# Load common library
source "$(dirname "$0")/../lib/common.sh"

# Initialize
init_common
log_info "🗄️  Adminer Installer (with Nginx)"
setup_logging "install-adminer"

# Main installation
update_system
install_packages adminer

log_step "Linking Adminer to /var/www/html/adminer..."
if [ ! -L "/var/www/html/adminer" ]; then
    sudo ln -s /usr/share/adminer /var/www/html/adminer
    log_success "Symlink created: /var/www/html/adminer -> /usr/share/adminer"
else
    log_info "Symlink already exists: /var/www/html/adminer"
fi

log_step "No custom Nginx config needed. Adminer will be available at /adminer using the default PHP handler."

# Optionally prompt to remove old snippet and config if present
if [ -f "/etc/nginx/snippets/adminer.conf" ]; then
    if prompt_yes_no "Remove old adminer.conf Nginx snippet and config include?" "y"; then
        sudo rm -f /etc/nginx/snippets/adminer.conf
        sudo sed -i '/include snippets\/adminer.conf;/d' /etc/nginx/sites-available/default 2>/dev/null || true
        log_success "Old adminer.conf snippet and config include removed."
    fi
fi

enable_service nginx
restart_service nginx

log_success "Adminer installation and configuration complete! Access it at /adminer." 