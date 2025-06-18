#!/bin/bash

# Load common library
source "$(dirname "$0")/../lib/common.sh"

# Initialize
init_common
log_info "🗄️  phpMyAdmin Installer (with Nginx)"
setup_logging "install-phpmyadmin"

# Main installation
update_system
install_packages phpmyadmin

log_step "Linking phpMyAdmin to /var/www/html/phpmyadmin..."
if [ ! -L "/var/www/html/phpmyadmin" ]; then
    sudo ln -s /usr/share/phpmyadmin /var/www/html/phpmyadmin
    log_success "Symlink created: /var/www/html/phpmyadmin -> /usr/share/phpmyadmin"
else
    log_info "Symlink already exists: /var/www/html/phpmyadmin"
fi

log_step "No custom Nginx config needed. phpMyAdmin will be available at /phpmyadmin using the default PHP handler."

# Optionally prompt to remove old snippet and config if present
if [ -f "/etc/nginx/snippets/phpmyadmin.conf" ]; then
    if prompt_yes_no "Remove old phpmyadmin.conf Nginx snippet and config include?" "y"; then
        sudo rm -f /etc/nginx/snippets/phpmyadmin.conf
        sudo sed -i '/include snippets\/phpmyadmin.conf;/d' /etc/nginx/sites-available/default 2>/dev/null || true
        log_success "Old phpmyadmin.conf snippet and config include removed."
    fi
fi

enable_service nginx
restart_service nginx

log_success "phpMyAdmin installation and configuration complete! Access it at /phpmyadmin." 