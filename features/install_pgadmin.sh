#!/bin/bash

# Load common library
source "$(dirname "$0")/../lib/common.sh"

# Initialize
init_common
log_info "🗄️  pgAdmin Installer (with Nginx)"
setup_logging "install-pgadmin"

# Main installation
update_system
install_packages curl ca-certificates gnupg

log_step "Adding pgAdmin repository and installing pgAdmin4..."
# Add the public key and repository
curl -fsSLo /usr/share/keyrings/pgadmin-keyring.gpg https://www.pgadmin.org/static/packages_pgadmin_org.pub
sudo sh -c 'echo "deb [signed-by=/usr/share/keyrings/pgadmin-keyring.gpg] https://ftp.postgresql.org/pub/pgadmin/pgadmin4/apt/$(lsb_release -cs) pgadmin4 main" > /etc/apt/sources.list.d/pgadmin4.list'
update_system
install_packages pgadmin4-web

log_step "Configuring pgAdmin4..."
sudo /usr/pgadmin4/bin/setup-web.sh --yes

log_step "Configuring pgAdmin for Nginx..."
# Create Nginx config for pgAdmin
NGINX_CONF="/etc/nginx/snippets/pgadmin.conf"
sudo tee "$NGINX_CONF" > /dev/null <<EOL
location /pgadmin4/ {
    proxy_set_header X-Script-Name /pgadmin4;
    proxy_set_header Host $host;
    proxy_pass http://127.0.0.1/pgadmin4/;
    proxy_redirect off;
}
EOL

log_step "Include the pgAdmin config in your Nginx site configuration, e.g.:"
echo -e "    include snippets/pgadmin.conf;"

# Prompt to add to default Nginx site
if prompt_yes_no "Add pgAdmin endpoint to the default Nginx site?" "y"; then
    DEFAULT_SITE="/etc/nginx/sites-available/default"
    backup_file "$DEFAULT_SITE"
    if ! grep -q "include snippets/pgadmin.conf;" "$DEFAULT_SITE"; then
        sudo sed -i '/server_name _;/a \\n    include snippets/pgadmin.conf;' "$DEFAULT_SITE"
        log_success "pgAdmin config included in default Nginx site."
    else
        log_info "pgAdmin config already included in default Nginx site."
    fi
    restart_service nginx
fi

enable_service nginx
restart_service nginx

log_success "pgAdmin installation and Nginx configuration complete!" 