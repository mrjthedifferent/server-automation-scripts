#!/bin/bash

# Load common library
source "$(dirname "$0")/../lib/common.sh"

# Initialize - Allow user mode for this script
init_common --allow-user
log_info "💅 Oh My Zsh Shell Enhancement Installer"

# Install zsh
if command -v sudo &> /dev/null; then
    sudo apt update && sudo apt install -y zsh
else
    log_warning "Running without sudo - ensure zsh is installed"
fi

log_step "Installing Oh My Zsh..."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

log_step "Adding useful aliases..."
echo "alias art='php artisan'" >> ~/.zshrc
echo "alias ..='cd ..'" >> ~/.zshrc
echo "alias ll='ls -la'" >> ~/.zshrc

log_step "Setting zsh as default shell..."
chsh -s $(which zsh)

log_success "Oh My Zsh installation and setup complete!"
log_info "Please restart your terminal or run 'exec zsh' to use the new shell" 