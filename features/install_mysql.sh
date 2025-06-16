#!/bin/bash

# Load common library
source "$(dirname "$0")/../lib/common.sh"

# Initialize
init_common
log_info "🐬 MySQL Database Server Installer"
setup_logging "install-mysql"

# Get root password
read -rsp "🔑 Enter new MySQL root user password: " ROOT_PASS
echo

# Main installation
update_system
install_packages mysql-server
enable_service mysql

# Set root password
log_step "Setting MySQL root password..."
sudo mysql -u root <<MYSQL_SCRIPT
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$ROOT_PASS';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

# Optional: Create application user
if prompt_yes_no "Create a database user for applications?"; then
    prompt_with_default "Enter username" "laravel" "DB_USER"
    read -rsp "Enter password for $DB_USER: " DB_PASS
    echo
    
    log_step "Creating database user '$DB_USER'..."
    sudo mysql -u root -p$ROOT_PASS <<MYSQL_SCRIPT
CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON *.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT
    log_success "Database user '$DB_USER' created"
fi

log_success "MySQL installation complete!" 