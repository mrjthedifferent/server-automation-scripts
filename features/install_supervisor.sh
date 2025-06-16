#!/bin/bash

# Load common library
source "$(dirname "$0")/../lib/common.sh"

# Initialize
init_common
log_info "🔁 Supervisor Process Manager Installer"
setup_logging "install-supervisor"

# Main installation
update_system
install_packages supervisor
enable_service supervisor

log_step "Verifying installation..."
supervisorctl version

log_success "Supervisor installation complete!" 