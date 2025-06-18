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

log_step "Configuring phpMyAdmin for Nginx..."

# Create Nginx config for phpMyAdmin
NGINX_CONF="/etc/nginx/snippets/phpmyadmin.conf"
sudo tee "$NGINX_CONF" > /dev/null <<EOL
location /phpmyadmin {
    root /usr/share/;
    index index.php index.html index.htm;
    location ~ ^/phpmyadmin/(.+\.php)$ {
        try_files $uri $uri/ /phpmyadmin/index.php?$args;
        root /usr/share/;
        fastcgi_pass unix:/var/run/php/php${DEFAULT_PHP_VERSION}-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
    location ~* ^/phpmyadmin/(.+\.(jpg|jpeg|gif|css|png|js|ico|html|xml|txt))$ {
        root /usr/share/;
    }
}
EOL

log_step "Include the phpMyAdmin config in your Nginx site configuration, e.g.:"
echo -e "    include snippets/phpmyadmin.conf;"

# Prompt to add to default Nginx site
if prompt_yes_no "Add phpMyAdmin endpoint to the default Nginx site?" "y"; then
    DEFAULT_SITE="/etc/nginx/sites-available/default"
    backup_file "$DEFAULT_SITE"
    if ! grep -q "include snippets/phpmyadmin.conf;" "$DEFAULT_SITE"; then
        sudo sed -i '/server_name _;/a \\n    include snippets/phpmyadmin.conf;' "$DEFAULT_SITE"
        log_success "phpMyAdmin config included in default Nginx site."
    else
        log_info "phpMyAdmin config already included in default Nginx site."
    fi
    restart_service nginx
fi

enable_service nginx
restart_service nginx

log_success "phpMyAdmin installation and Nginx configuration complete!" 