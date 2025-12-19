#!/bin/bash

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_info() {
    echo -e "${YELLOW}[i]${NC} $1"
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd "$SCRIPT_DIR"

print_info "Pulling latest dotfiles from GitHub..."
echo ""

# Check for uncommitted changes
if [[ -n $(git status -s) ]]; then
    print_error "You have uncommitted changes. Please commit or stash them first."
    echo ""
    git status -s
    exit 1
fi

# Pull from remote
print_info "Pulling changes..."
git pull

if [ $? -ne 0 ]; then
    print_error "Pull failed"
    exit 1
fi

print_status "Successfully pulled from GitHub!"
echo ""

# Ask if user wants to restow dotfiles
read -p "Do you want to apply the updated dotfiles? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Applying dotfiles with Stow..."
    
    # Restow all packages
    for package in ghostty starship zsh; do
        if [ -d "$package" ]; then
            print_info "Restowing $package..."
            stow -R -t "$HOME" "$package"
            print_status "$package applied"
        fi
    done
    
    echo ""
    print_status "Dotfiles applied! Restart your terminal or run 'source ~/.zshrc'"
else
    print_info "Skipping dotfile application. Run './install.sh' or 'stow -R <package>' manually to apply."
fi
