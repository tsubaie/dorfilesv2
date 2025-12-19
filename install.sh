#!/bin/bash

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Functions
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_info() {
    echo -e "${YELLOW}[i]${NC} $1"
}

# Update system
update_system() {
    print_info "Updating system packages..."
    sudo apt update && sudo apt upgrade -y
    print_status "System updated"
}

# Install APT packages
install_apt_packages() {
    print_info "Installing APT packages..."
    if [ -f "$SCRIPT_DIR/packages/apt.txt" ]; then
        while IFS= read -r package; do
            # Skip empty lines and comments
            [[ -z "$package" || "$package" =~ ^#.* ]] && continue
            
            if ! dpkg -l | grep -q "^ii  $package "; then
                print_info "Installing $package..."
                sudo apt install -y "$package"
            else
                print_status "$package already installed"
            fi
        done < "$SCRIPT_DIR/packages/apt.txt"
        print_status "APT packages installed"
    else
        print_error "apt.txt not found"
        exit 1
    fi
}

# Install Flatpak packages
install_flatpak_packages() {
    print_info "Installing Flatpak packages..."
    
    # Ensure Flatpak is installed
    if ! command -v flatpak &> /dev/null; then
        print_info "Installing Flatpak..."
        sudo apt install -y flatpak
        sudo apt install -y gnome-software-plugin-flatpak
    fi
    
    # Add Flathub if not already added (prefer user installation)
    if ! flatpak remote-list --user | grep -q "flathub"; then
        print_info "Adding Flathub remote for user..."
        flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    fi
    
    if [ -f "$SCRIPT_DIR/packages/flatpak.txt" ]; then
        while IFS= read -r package; do
            # Skip empty lines and comments
            [[ -z "$package" || "$package" =~ ^#.* ]] && continue
            
            if ! flatpak list --user | grep -q "$package"; then
                print_info "Installing $package..."
                flatpak install --user -y flathub "$package"
            else
                print_status "$package already installed"
            fi
        done < "$SCRIPT_DIR/packages/flatpak.txt"
        print_status "Flatpak packages installed"
    else
        print_error "flatpak.txt not found"
        exit 1
    fi
}

# Install Ghostty terminal
install_ghostty() {
    print_info "Installing Ghostty terminal..."
    if command -v ghostty &> /dev/null; then
        print_status "Ghostty already installed"
    else
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/mkasberg/ghostty-ubuntu/HEAD/install.sh)"
        print_status "Ghostty installed"
    fi
}

# Install Brave browser
install_brave() {
    print_info "Installing Brave browser..."
    if command -v brave-browser &> /dev/null; then
        print_status "Brave already installed"
    else
        curl -fsS https://dl.brave.com/install.sh | sh
        print_status "Brave installed"
    fi
}

# Install Starship prompt
install_starship() {
    print_info "Installing Starship prompt..."
    if command -v starship &> /dev/null; then
        print_status "Starship already installed"
    else
        curl -sS https://starship.rs/install.sh | sh -s -- -y
        print_status "Starship installed"
        
        # Add to bashrc if not already there
        if ! grep -q "starship init bash" ~/.bashrc; then
            echo 'eval "$(starship init bash)"' >> ~/.bashrc
            print_status "Starship added to .bashrc"
        fi
        
        # Add to zshrc if not already there (for when zsh is set up)
        if [ -f ~/.zshrc ]; then
            if ! grep -q "starship init zsh" ~/.zshrc; then
                echo 'eval "$(starship init zsh)"' >> ~/.zshrc
                print_status "Starship added to .zshrc"
            fi
        fi
    fi
}

# Install and setup Tailscale
install_tailscale() {
    print_info "Installing Tailscale..."
    if command -v tailscale &> /dev/null; then
        print_status "Tailscale already installed"
    else
        curl -fsSL https://tailscale.com/install.sh | sh
        print_status "Tailscale installed"
    fi
    
    # Enable and start Tailscale service
    print_info "Enabling Tailscale service..."
    sudo systemctl enable --now tailscaled
    print_status "Tailscale service enabled"
    
    # Check if Tailscale is already authenticated and running
    if sudo tailscale status 2>/dev/null | grep -q "^# "; then
        print_status "Tailscale is already authenticated and running"
        
        # Check if already advertising as exit node
        if sudo tailscale status --peers=false 2>/dev/null | grep -q "offers exit node"; then
            print_status "Already configured as exit node"
        else
            print_info "Configuring as exit node..."
            print_info "Note: If you see warnings about existing settings, that's normal"
            
            # Try to configure, but don't fail if it's already configured
            sudo tailscale up --advertise-exit-node 2>/dev/null || true
            
            print_status "Exit node configuration attempted"
            print_info "Remember to approve this device as an exit node in the Tailscale admin console"
        fi
    else
        # First time setup
        print_info "Starting Tailscale authentication..."
        print_info "Please authenticate in the browser that opens..."
        sudo tailscale up --advertise-exit-node
        
        print_status "Tailscale configured as exit node"
        print_info "Remember to approve this device as an exit node in the Tailscale admin console"
    fi
}

# Install and setup ZSH
install_zsh() {
    print_info "Installing and setting up ZSH..."
    
    # Install zsh if not already installed
    if ! command -v zsh &> /dev/null; then
        sudo apt install -y zsh
        print_status "ZSH installed"
    else
        print_status "ZSH already installed"
    fi
    
    # Change default shell to zsh
    if [ "$SHELL" != "$(which zsh)" ]; then
        print_info "Changing default shell to ZSH..."
        chsh -s $(which zsh)
        print_status "Default shell changed to ZSH (will take effect after logout)"
    else
        print_status "ZSH is already the default shell"
    fi
    
    # Install Oh My Zsh if not already installed
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        print_info "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        print_status "Oh My Zsh installed"
        
        # Add starship to zshrc if not already there
        if [ -f ~/.zshrc ] && ! grep -q "starship init zsh" ~/.zshrc; then
            echo 'eval "$(starship init zsh)"' >> ~/.zshrc
            print_status "Starship added to .zshrc"
        fi
    else
        print_status "Oh My Zsh already installed"
    fi
}

# Deploy dotfiles using GNU Stow
deploy_dotfiles() {
    print_info "Deploying dotfiles with GNU Stow..."
    
    cd "$SCRIPT_DIR"
    
    # Stow all config packages
    for package in ghostty starship zsh; do
        if [ -d "$package" ]; then
            print_info "Stowing $package..."
            stow -v -R -t "$HOME" "$package"
            print_status "$package configured"
        fi
    done
    
    cd - > /dev/null
    print_status "All dotfiles deployed"
}


# Main execution
main() {
    print_info "Starting package installation for Pop!_OS..."
    echo ""
    
    # Ask for confirmation
    read -p "This will install packages and configure your system. Continue? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_error "Installation cancelled"
        exit 1
    fi
    
    update_system
    echo ""
    
    install_apt_packages
    echo ""
    
    install_flatpak_packages
    echo ""
    
    install_ghostty
    echo ""
    
    install_brave
    echo ""
    
    install_starship
    echo ""
    
    install_tailscale
    echo ""
    
    install_zsh
    echo ""
    
    deploy_dotfiles
    echo ""
    
    print_status "All packages installed successfully!"
    echo ""
    print_info "Important notes:"
    echo "  - You need to log out and log back in for ZSH to become your default shell"
    echo "  - Approve this device as an exit node in the Tailscale admin console at https://login.tailscale.com/admin/machines"
    echo "  - Tailscale will persist across reboots (systemd service enabled)"
    echo "  - Starship prompt is configured for both bash and zsh"
}

# Run main function
main