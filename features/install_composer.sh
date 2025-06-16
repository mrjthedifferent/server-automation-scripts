#!/bin/bash

# Load common library
source "$(dirname "$0")/../lib/common.sh"

# Initialize
init_common
log_info "📦 Composer Installer"
setup_logging "install-composer"

# Pre-installation check
if ! command -v php &> /dev/null; then
    log_error "PHP is required but not installed"
    exit 1
fi

# Download and verify Composer
log_step "Downloading Composer installer..."
EXPECTED_CHECKSUM="$(php -r 'copy("https://composer.github.io/installer.sig", "php://stdout");')"
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
ACTUAL_CHECKSUM="$(sha384sum composer-setup.php | cut -d ' ' -f 1)"

if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]; then
    log_error "Invalid Composer checksum"
    rm composer-setup.php
    exit 1
fi

log_step "Installing Composer..."
sudo php composer-setup.php --install-dir=/usr/local/bin --filename=composer
rm composer-setup.php

log_step "Verifying installation..."
composer --version

log_success "Composer installation complete!" 