#!/bin/bash

# Load common library
source "$(dirname "$0")/../lib/common.sh"

# Initialize
init_common
log_info "🛡️ Fail2Ban Intrusion Prevention Installer"
setup_logging "install-fail2ban"

log_info "Fail2Ban protects your server from brute-force attacks and malicious behavior"

# Main installation
update_system
install_packages fail2ban
enable_service fail2ban

log_step "Verifying installation..."
sudo fail2ban-client version

log_success "Fail2Ban installation complete!" 