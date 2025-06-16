#!/bin/bash

# Load common library
source "$(dirname "$0")/../lib/common.sh"

# Initialize
init_common
log_info "🧻 Laravel Logrotate Setup"
setup_logging "setup-logrotate"

log_step "Configuring logrotate for Laravel logs..."
sudo tee /etc/logrotate.d/laravel > /dev/null <<EOF
/var/www/*/storage/logs/laravel.log {
    daily
    missingok
    rotate $LOG_RETENTION_DAYS
    compress
    delaycompress
    notifempty
    copytruncate
    create 644 www-data www-data
}
EOF

log_step "Testing logrotate configuration..."
sudo logrotate -d /etc/logrotate.d/laravel

log_success "Logrotate configuration for Laravel complete!"
log_info "Logs will be rotated daily and kept for $LOG_RETENTION_DAYS days" 