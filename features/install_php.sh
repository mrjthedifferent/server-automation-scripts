#!/bin/bash

# Load common library
source "$(dirname "$0")/../lib/common.sh"

# Initialize
init_common
log_info "🐘 PHP Installer"
setup_logging "install-php"

# Multiple PHP versions support
log_info "Available PHP versions: 7.4, 8.0, 8.1, 8.2, 8.3"
read -rp "Enter PHP versions to install (space-separated, default: $DEFAULT_PHP_VERSION): " PHP_VERSIONS
PHP_VERSIONS=${PHP_VERSIONS:-$DEFAULT_PHP_VERSION}

read -rp "Set default PHP version (default: $DEFAULT_PHP_VERSION): " DEFAULT_VERSION
DEFAULT_VERSION=${DEFAULT_VERSION:-$DEFAULT_PHP_VERSION}

log_step "Updating system..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y software-properties-common curl wget gnupg2 unzip git ufw lsb-release ca-certificates

log_step "Adding Ondrej PHP repository..."
sudo add-apt-repository ppa:ondrej/php -y
sudo apt update

# Install packages function with error checking
install_packages_with_check() {
    local packages="$*"
    log_step "Installing packages: $packages"
    if sudo apt install -y $packages; then
        log_success "Successfully installed: $packages"
        log_to_file "Installed packages: $packages"
        return 0
    else
        log_error "Failed to install packages: $packages"
        log_to_file "ERROR: Failed to install packages: $packages"
        return 1
    fi
}

# Install each PHP version
for VERSION in $PHP_VERSIONS; do
    log_step "Installing PHP $VERSION with extensions..."
    
    if ! install_packages_with_check \
        php$VERSION \
        php$VERSION-cli \
        php$VERSION-fpm \
        php$VERSION-mysql \
        php$VERSION-pgsql \
        php$VERSION-mbstring \
        php$VERSION-xml \
        php$VERSION-bcmath \
        php$VERSION-curl \
        php$VERSION-zip \
        php$VERSION-gd \
        php$VERSION-soap \
        php$VERSION-readline \
        php$VERSION-redis \
        php$VERSION-imagick \
        php$VERSION-intl \
        php$VERSION-xdebug; then
        log_error "Failed to install PHP $VERSION. Continuing with next version..."
        continue
    fi

    log_step "Optimizing PHP $VERSION settings..."
    
    # FPM configuration
    PHP_FPM_INI="/etc/php/$VERSION/fpm/php.ini"
    PHP_CLI_INI="/etc/php/$VERSION/cli/php.ini"
    
    for INI_FILE in $PHP_FPM_INI $PHP_CLI_INI; do
        if [ -f "$INI_FILE" ]; then
            sudo sed -i "s/memory_limit = .*/memory_limit = $DEFAULT_MEMORY_LIMIT/" "$INI_FILE"
            sudo sed -i "s/upload_max_filesize = .*/upload_max_filesize = $DEFAULT_UPLOAD_SIZE/" "$INI_FILE"
            sudo sed -i "s/post_max_size = .*/post_max_size = $DEFAULT_UPLOAD_SIZE/" "$INI_FILE"
            sudo sed -i "s/max_execution_time = .*/max_execution_time = $DEFAULT_EXECUTION_TIME/" "$INI_FILE"
            sudo sed -i "s/;date.timezone.*/date.timezone = UTC/" "$INI_FILE"
            log_info "Configured $INI_FILE"
        else
            log_warning "Configuration file $INI_FILE not found"
        fi
    done
    
    # FPM pool configuration
    FPM_POOL="/etc/php/$VERSION/fpm/pool.d/www.conf"
    if [ -f "$FPM_POOL" ]; then
        sudo sed -i "s/^pm = .*/pm = dynamic/" $FPM_POOL
        sudo sed -i "s/^pm.max_children = .*/pm.max_children = 50/" $FPM_POOL
        sudo sed -i "s/^pm.start_servers = .*/pm.start_servers = 5/" $FPM_POOL
        sudo sed -i "s/^pm.min_spare_servers = .*/pm.min_spare_servers = 5/" $FPM_POOL
        sudo sed -i "s/^pm.max_spare_servers = .*/pm.max_spare_servers = 35/" $FPM_POOL
        sudo sed -i "s/^;pm.max_requests = .*/pm.max_requests = 500/" $FPM_POOL
    fi
    
    # Enable and start PHP-FPM
    if systemctl list-unit-files | grep -q "php$VERSION-fpm.service"; then
        enable_service "php$VERSION-fpm"
        log_success "PHP $VERSION-FPM enabled and started"
    else
        log_warning "PHP $VERSION-FPM service not found"
    fi
done

# Set default PHP version
log_step "Setting PHP $DEFAULT_VERSION as default..."
sudo update-alternatives --set php /usr/bin/php$DEFAULT_VERSION
sudo update-alternatives --set phar /usr/bin/phar$DEFAULT_VERSION
sudo update-alternatives --set phar.phar /usr/bin/phar.phar$DEFAULT_VERSION

# Create PHP version switcher script
log_step "Creating PHP version switcher..."
sudo tee /usr/local/bin/php-switch > /dev/null <<EOF
#!/bin/bash
# PHP Version Switcher

if [ \$# -eq 0 ]; then
    echo "Usage: php-switch <version>"
    echo "Available versions:"
    ls /usr/bin/php?.? 2>/dev/null | sed 's/.*php/  /'
    echo "Current version: \$(php -v | head -n 1)"
    exit 1
fi

VERSION=\$1

if [ ! -f "/usr/bin/php\$VERSION" ]; then
    echo "PHP \$VERSION is not installed"
    exit 1
fi

sudo update-alternatives --set php /usr/bin/php\$VERSION
sudo update-alternatives --set phar /usr/bin/phar\$VERSION  
sudo update-alternatives --set phar.phar /usr/bin/phar.phar\$VERSION

echo "Switched to PHP \$VERSION"
php -v | head -n 1
EOF

sudo chmod +x /usr/local/bin/php-switch

log_success "PHP installation complete!"

echo ""
echo "📋 Installation Summary:"
echo "Installed versions: $PHP_VERSIONS"
echo "Default version: $DEFAULT_VERSION"
echo "Memory limit: $DEFAULT_MEMORY_LIMIT"
echo "Upload size: $DEFAULT_UPLOAD_SIZE"
echo "Execution time: ${DEFAULT_EXECUTION_TIME}s"
echo ""
echo "🔧 Use 'php-switch <version>' to switch between PHP versions"
echo "🐘 Current PHP version: $(php -v | head -n 1)" 