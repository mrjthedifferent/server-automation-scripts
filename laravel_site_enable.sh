#!/bin/bash

# Load common library
source "$(dirname "$0")/lib/common.sh"
init_common

log_info "🛠️ Laravel Site Setup Script"
setup_logging "laravel-site"

# Collect input
prompt_with_default "📂 Enter full Laravel project path (e.g., /var/www/my-app)" "" "LARAVEL_PATH"
prompt_with_default "🌐 Enter domain name (e.g., example.com)" "" "DOMAIN_NAME"
prompt_with_default "🐘 Enter PHP version" "$DEFAULT_PHP_VERSION" "PHP_VERSION"

# Validate Laravel project
validate_laravel_path "$LARAVEL_PATH"

# Optional features
SETUP_SSL=$(prompt_yes_no "🔒 Configure SSL with Let's Encrypt?" "y" && echo "true" || echo "false")
SETUP_FIREWALL=$(prompt_yes_no "🔥 Setup firewall rules?" "y" && echo "true" || echo "false")
SETUP_MONITORING=$(prompt_yes_no "📊 Setup monitoring?" "y" && echo "true" || echo "false")
SETUP_BACKUPS=$(prompt_yes_no "🗄️ Setup automatic backups?" "y" && echo "true" || echo "false")

# Get SSL email if needed
if [ "$SETUP_SSL" = "true" ]; then
    prompt_with_default "📧 Enter email for SSL certificate" "" "SSL_EMAIL"
fi

NGINX_CONF="/etc/nginx/sites-available/$DOMAIN_NAME"
SUPERVISOR_CONF="/etc/supervisor/conf.d/${DOMAIN_NAME//./_}_queue.conf"

# Set proper ownership and permissions
log_step "Setting proper ownership and permissions..."
sudo chown -R www-data:www-data "$LARAVEL_PATH"
sudo chmod -R 755 "$LARAVEL_PATH"
sudo chmod -R 775 "$LARAVEL_PATH/storage" "$LARAVEL_PATH/bootstrap/cache"

# Create Nginx configuration
log_step "Creating Nginx configuration..."
generate_nginx_config "$DOMAIN_NAME" "$LARAVEL_PATH" "$PHP_VERSION" | sudo tee "$NGINX_CONF" > /dev/null

# Enable Nginx site
log_step "Enabling Nginx site..."
sudo ln -sf "$NGINX_CONF" "/etc/nginx/sites-enabled/$DOMAIN_NAME"
sudo nginx -t && sudo systemctl reload nginx

# Setup SSL if requested
if [ "$SETUP_SSL" = "true" ] && command -v certbot &> /dev/null; then
    log_step "Setting up SSL certificate..."
    sudo certbot --nginx -d "$DOMAIN_NAME" --email "$SSL_EMAIL" --agree-tos --non-interactive --redirect
fi

# Create log directory
create_directory "/var/log/laravel/$DOMAIN_NAME" "www-data:www-data" "755"

# Setup Supervisor for queue worker
if command -v supervisorctl &> /dev/null; then
    log_step "Setting up Supervisor queue worker..."
    generate_supervisor_config "$DOMAIN_NAME" "$LARAVEL_PATH" | sudo tee "$SUPERVISOR_CONF" > /dev/null
    
    sudo supervisorctl reread
    sudo supervisorctl update
    sudo supervisorctl start "${DOMAIN_NAME//./_}_queue:"
    log_success "Queue worker configured"
fi

# Setup firewall if requested
if [ "$SETUP_FIREWALL" = "true" ]; then
    setup_firewall
fi

# Setup monitoring if requested
if [ "$SETUP_MONITORING" = "true" ]; then
    setup_monitoring "$DOMAIN_NAME"
fi

# Setup backups if requested
if [ "$SETUP_BACKUPS" = "true" ]; then
    setup_backups "$DOMAIN_NAME" "$LARAVEL_PATH"
fi

log_success "Laravel site '$DOMAIN_NAME' is fully configured!"

echo ""
echo "📊 Setup Summary:"
echo "Domain: $DOMAIN_NAME"
echo "Path: $LARAVEL_PATH"
echo "PHP Version: $PHP_VERSION"
echo "SSL: $([ "$SETUP_SSL" = "true" ] && echo "✅ Enabled" || echo "❌ Disabled")"
echo "Firewall: $([ "$SETUP_FIREWALL" = "true" ] && echo "✅ Enabled" || echo "❌ Disabled")"
echo "Monitoring: $([ "$SETUP_MONITORING" = "true" ] && echo "✅ Enabled" || echo "❌ Disabled")"
echo "Backups: $([ "$SETUP_BACKUPS" = "true" ] && echo "✅ Enabled" || echo "❌ Disabled")"
