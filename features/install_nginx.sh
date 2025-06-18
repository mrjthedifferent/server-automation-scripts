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

log_step "Configuring client_max_body_size in nginx.conf..."
NGINX_CONF="/etc/nginx/nginx.conf"
if grep -q "client_max_body_size" "$NGINX_CONF"; then
    # Update existing directive
    sudo sed -i "/client_max_body_size/c\\    client_max_body_size 64M;" "$NGINX_CONF"
    log_info "Updated existing client_max_body_size to 64M in nginx.conf."
else
    # Insert into http block
    sudo sed -i "/http {/a \\    client_max_body_size 64M;" "$NGINX_CONF"
    log_info "Inserted client_max_body_size 64M into http block in nginx.conf."
fi

# Add/update other recommended settings
NGINX_SETTINGS=(
  "client_body_timeout 60s;"
  "client_header_timeout 60s;"
  "keepalive_timeout 75s;"
  "send_timeout 60s;"
  "proxy_read_timeout 60s;"
  "proxy_connect_timeout 60s;"
  "proxy_send_timeout 60s;"
  "server_tokens off;"
  "gzip on;"
  "gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;"
)

for SETTING in "${NGINX_SETTINGS[@]}"; do
  KEY=$(echo "$SETTING" | awk '{print $1}')
  if grep -q "$KEY" "$NGINX_CONF"; then
    sudo sed -i "/$KEY/c\\    $SETTING" "$NGINX_CONF"
    log_info "Updated $KEY in nginx.conf."
  else
    sudo sed -i "/http {/a \\    $SETTING" "$NGINX_CONF"
    log_info "Inserted $KEY into http block in nginx.conf."
  fi
done

log_step "Reloading Nginx to apply configuration..."
sudo systemctl reload nginx

log_step "Testing Nginx configuration..."
sudo nginx -t

log_success "Nginx installation complete!" 