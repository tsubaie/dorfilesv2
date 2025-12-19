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
    
    # Add Flathub if not already added
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    
    if [ -f "$SCRIPT_DIR/packages/flatpak.txt" ]; then
        while IFS= read -r package; do
            # Skip empty lines and comments
            [[ -z "$package" || "$package" =~ ^#.* ]] && continue
            
            if ! flatpak list | grep -q "$package"; then
                print_info "Installing $package..."
                flatpak install -y flathub "$package"
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

# Main execution
main() {
    print_info "Starting package installation for Pop!_OS..."
    echo ""
    
    # Ask for confirmation
    read -p "This will install packages from apt.txt and flatpak.txt. Continue? (y/n) " -n 1 -r
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
    
    print_status "All packages installed successfully!"
    print_info "You may need to restart your system for some changes to take effect."
}

# Run main function
main