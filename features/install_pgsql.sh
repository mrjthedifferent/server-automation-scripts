#!/bin/bash

# Load common library
source "$(dirname "$0")/../lib/common.sh"

# Initialize
init_common
log_info "🐘 PostgreSQL Database Server Installer"
setup_logging "install-pgsql"

# Get root password
read -rsp "🔑 Enter new PostgreSQL root (postgres) user password: " ROOT_PASS
echo

# Main installation
update_system
install_packages postgresql postgresql-contrib
enable_service postgresql

# Set root password
log_step "Setting PostgreSQL root password..."
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '$ROOT_PASS';"

# Optional: Create application user
if prompt_yes_no "Create a database user for applications?" "y"; then
    prompt_with_default "Enter username" "laravel" "DB_USER"
    read -rsp "Enter password for $DB_USER: " DB_PASS
    echo
    
    log_step "Creating database user '$DB_USER'..."
    sudo -u postgres createuser --createdb "$DB_USER"
    sudo -u postgres psql -c "ALTER USER $DB_USER WITH PASSWORD '$DB_PASS';"
    log_success "Database user '$DB_USER' created"
fi

log_success "PostgreSQL installation complete!" 