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

log_step "Configuring Adminer for Nginx..."

# Create Nginx config for Adminer if not present
NGINX_CONF="/etc/nginx/snippets/adminer.conf"
if [ ! -f "$NGINX_CONF" ]; then
    sudo tee "$NGINX_CONF" > /dev/null <<EOL
location /adminer {
    alias /usr/share/adminer/;
    index index.php;
    location ~ ^/adminer/(.+\.php)$ {
        fastcgi_pass unix:/var/run/php/php${DEFAULT_PHP_VERSION}-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
}
EOL
    log_info "Created Nginx snippet for Adminer."
else
    log_info "Nginx snippet for Adminer already exists."
fi

log_step "Include the Adminer config in your Nginx site configuration, e.g.:"
echo -e "    include snippets/adminer.conf;"

# Prompt to add to default Nginx site
if prompt_yes_no "Add Adminer endpoint to the default Nginx site?" "y"; then
    DEFAULT_SITE="/etc/nginx/sites-available/default"
    backup_file "$DEFAULT_SITE"
    if ! grep -q "include snippets/adminer.conf;" "$DEFAULT_SITE"; then
        sudo sed -i '/server_name _;/a \\n    include snippets/adminer.conf;' "$DEFAULT_SITE"
        log_success "Adminer config included in default Nginx site."
    else
        log_info "Adminer config already included in default Nginx site."
    fi
    restart_service nginx
fi

enable_service nginx
restart_service nginx

log_success "Adminer installation and Nginx configuration complete!" 