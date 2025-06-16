#!/bin/bash

# Load common library
source "$(dirname "$0")/../lib/common.sh"

# Initialize
init_common
log_info "🔴 Redis Server Installer"
setup_logging "install-redis"

# Main installation
update_system
install_packages redis-server
enable_service redis-server

log_step "Testing Redis connection..."
redis-cli ping || log_warning "Redis test failed - service may still be starting"

log_success "Redis installation complete!" 