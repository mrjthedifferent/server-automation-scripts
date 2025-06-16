#!/bin/bash

# Template for Feature Installation Scripts
# Copy this template and customize for each feature

# Load common library
source "$(dirname "$0")/../lib/common.sh"

# Feature configuration
FEATURE_NAME="feature"
FEATURE_DESCRIPTION="Feature Description"
PACKAGES="package1 package2"
SERVICES="service1"

# Initialize
init_common
log_info "🔧 $FEATURE_DESCRIPTION Installer"
setup_logging "install-$FEATURE_NAME"

# Pre-installation checks
pre_install_check() {
    # Add feature-specific checks here
    return 0
}

# Main installation function
install_feature() {
    update_system
    install_packages $PACKAGES
    
    # Add feature-specific installation steps here
    
    # Enable services
    for service in $SERVICES; do
        enable_service "$service"
    done
}

# Post-installation configuration
configure_feature() {
    # Add feature-specific configuration here
    return 0
}

# Main execution
if pre_install_check; then
    install_feature
    configure_feature
    log_success "$FEATURE_DESCRIPTION installation complete!"
else
    log_error "Pre-installation checks failed"
    exit 1
fi 