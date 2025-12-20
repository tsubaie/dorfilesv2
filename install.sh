#!/bin/bash

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Functions
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}→${NC} $1"
}

print_section() {
    echo -e "\n${YELLOW}▶${NC} $1"
}

# Wait for apt/dpkg locks to clear
wait_for_apt_lock() {
    local count=0
    local max_wait=20  # Reduced from 40
    
    while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 || \
          sudo fuser /var/lib/apt/lists/lock >/dev/null 2>&1 || \
          sudo fuser /var/cache/apt/archives/lock >/dev/null 2>&1; do
        
        if [ $count -eq 0 ]; then
            print_info "Waiting for other package managers to finish..."
        fi
        
        sleep 2
        ((count++))
        
        if [ $count -ge $max_wait ]; then
            print_error "Timeout waiting for package manager locks"
            echo ""
            read -p "$(echo -e ${YELLOW}?)${NC} Force kill package managers and continue? (y/n) " -n 1 -r
            echo ""
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                print_info "Killing stuck processes..."
                sudo killall apt apt-get nala dpkg 2>/dev/null || true
                sudo rm -f /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock /var/cache/apt/archives/lock 2>/dev/null || true
                sleep 2
                print_info "Cleaned up locks, continuing..."
                return 0
            else
                return 1
            fi
        fi
    done
    
    sleep 1
    return 0
}

# Ask user if they want to proceed with a step
ask_proceed() {
    local message="$1"
    echo ""
    read -p "$(echo -e ${BLUE}?${NC}) $message (y/n) " -n 1 -r
    echo ""
    [[ $REPLY =~ ^[Yy]$ ]]
}

# Update system
update_system() {
    if ask_proceed "Update system packages?"; then
        print_section "Updating system"
        print_info "Running apt update..."
        sudo apt update
        print_info "Running apt upgrade..."
        sudo apt upgrade -y
        print_status "System updated"
    else
        print_info "Skipped system update"
    fi
}

# Install Nala package manager
install_nala() {
    if command -v nala &> /dev/null; then
        print_info "Nala already installed"
        return
    fi
    
    if ask_proceed "Install Nala package manager?"; then
        print_section "Installing Nala"
        print_info "Downloading and running Nala installer..."
        curl https://gitlab.com/volian/volian-archive/-/raw/main/install-nala.sh | bash
        print_status "Nala installed"
    else
        print_info "Skipped Nala installation"
    fi
}

# Install APT packages
install_apt_packages() {
    if ! ask_proceed "Install APT packages from apt.txt?"; then
        print_info "Skipped APT packages"
        return
    fi
    
    print_section "Installing APT packages"
    if [ -f "$SCRIPT_DIR/packages/apt.txt" ]; then
        # Determine which package manager to use
        if command -v nala &> /dev/null; then
            PKG_MGR="nala"
            print_info "Using nala for package installation"
        else
            PKG_MGR="apt"
            print_info "Using apt for package installation"
        fi
        
        # Collect packages to install
        local to_install=()
        while IFS= read -r package; do
            [[ -z "$package" || "$package" =~ ^#.* ]] && continue
            
            if ! dpkg -s "$package" &>/dev/null; then
                to_install+=("$package")
            else
                print_status "$package already installed"
            fi
        done < "$SCRIPT_DIR/packages/apt.txt"
        
        # Install all at once
        if [ ${#to_install[@]} -gt 0 ]; then
            print_info "Installing ${#to_install[@]} packages: ${to_install[*]}"
            wait_for_apt_lock || return 1
            
            DEBIAN_FRONTEND=noninteractive sudo $PKG_MGR install -y "${to_install[@]}"
            print_status "Installed ${#to_install[@]} package(s)"
        else
            print_status "All packages already installed"
        fi
    else
        print_error "apt.txt not found"
        exit 1
    fi
}

# Install Flatpak packages
install_flatpak_packages() {
    if ! ask_proceed "Install Flatpak packages from flatpak.txt?"; then
        print_info "Skipped Flatpak packages"
        return
    fi
    
    print_section "Installing Flatpak packages"
    
    if ! command -v flatpak &> /dev/null; then
        print_info "Installing Flatpak..."
        wait_for_apt_lock
        sudo apt install -y flatpak gnome-software-plugin-flatpak
    fi
    
    if ! flatpak remote-list --user 2>/dev/null | grep -q "flathub"; then
        print_info "Adding Flathub repository..."
        flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    fi
    
    if [ -f "$SCRIPT_DIR/packages/flatpak.txt" ]; then
        local installed=()
        while IFS= read -r package; do
            [[ -z "$package" || "$package" =~ ^#.* ]] && continue
            
            if ! flatpak list --user 2>/dev/null | grep -q "$package"; then
                print_info "Installing $package..."
                flatpak install --user -y flathub "$package"
                local app_name=$(echo "$package" | awk -F'.' '{print $NF}')
                installed+=("$app_name")
            else
                print_status "$package already installed"
            fi
        done < "$SCRIPT_DIR/packages/flatpak.txt"
        
        if [ ${#installed[@]} -eq 0 ]; then
            print_status "All packages already installed"
        else
            print_status "Installed ${#installed[@]} app(s)"
        fi
    fi
}

# Install Ghostty terminal
install_ghostty() {
    if command -v ghostty &> /dev/null; then
        print_info "Ghostty already installed"
        return
    fi
    
    if ask_proceed "Install Ghostty terminal?"; then
        print_section "Installing Ghostty"
        print_info "Running Ghostty installer..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/mkasberg/ghostty-ubuntu/HEAD/install.sh)"
        print_status "Ghostty installed"
    else
        print_info "Skipped Ghostty installation"
    fi
}

# Install Brave browser
install_brave() {
    if command -v brave-browser &> /dev/null; then
        print_info "Brave already installed"
        return
    fi
    
    if ask_proceed "Install Brave browser?"; then
        print_section "Installing Brave"
        print_info "Running Brave installer..."
        curl -fsS https://dl.brave.com/install.sh | sh
        print_status "Brave installed"
    else
        print_info "Skipped Brave installation"
    fi
}

# Install Starship prompt
install_starship() {
    if command -v starship &> /dev/null; then
        print_info "Starship already installed"
        return
    fi
    
    if ask_proceed "Install Starship prompt?"; then
        print_section "Installing Starship"
        print_info "Running Starship installer..."
        curl -sS https://starship.rs/install.sh | sh -s -- -y
        
        if ! grep -q "starship init bash" ~/.bashrc 2>/dev/null; then
            echo 'eval "$(starship init bash)"' >> ~/.bashrc
            print_info "Added Starship to .bashrc"
        fi
        
        if [ -f ~/.zshrc ] && ! grep -q "starship init zsh" ~/.zshrc; then
            echo 'eval "$(starship init zsh)"' >> ~/.zshrc
            print_info "Added Starship to .zshrc"
        fi
        print_status "Starship installed"
    else
        print_info "Skipped Starship installation"
    fi
}

# Install and setup Tailscale
install_tailscale() {
    if sudo tailscale status &> /dev/null && sudo tailscale status --peers=false 2>/dev/null | grep -q "offers exit node"; then
        print_info "Tailscale already configured"
        return
    fi
    
    if ! ask_proceed "Install and configure Tailscale?"; then
        print_info "Skipped Tailscale installation"
        return
    fi
    
    print_section "Installing Tailscale"
    
    if ! command -v tailscale &> /dev/null; then
        print_info "Running Tailscale installer..."
        curl -fsSL https://tailscale.com/install.sh | sh
        print_status "Tailscale installed"
    fi
    
    print_info "Enabling Tailscale service..."
    sudo systemctl enable --now tailscaled
    
    if sudo tailscale status &> /dev/null; then
        if ! sudo tailscale status --peers=false 2>/dev/null | grep -q "offers exit node"; then
            print_info "Configuring as exit node..."
            sudo tailscale up --advertise-exit-node
            print_status "Configured as exit node"
        fi
    else
        print_info "Please authenticate in the browser..."
        sudo tailscale up --advertise-exit-node
        print_status "Configured as exit node"
        print_info "Remember to approve in: https://login.tailscale.com/admin/machines"
    fi
}

# Install 1Password
install_1password() {
    if command -v 1password &> /dev/null; then
        print_info "1Password already installed"
        return
    fi
    
    if ! ask_proceed "Install 1Password?"; then
        print_info "Skipped 1Password installation"
        return
    fi
    
    print_section "Installing 1Password"
    
    print_info "Adding 1Password GPG key..."
    curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
    sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg
    
    print_info "Adding 1Password repository..."
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" | \
    sudo tee /etc/apt/sources.list.d/1password.list
    
    print_info "Setting up debsig policy..."
    sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22/
    curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol | \
    sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol > /dev/null
    
    sudo mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22
    curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
    sudo gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg
    
    print_info "Installing 1Password..."
    wait_for_apt_lock
    sudo apt update
    sudo apt install -y 1password
    print_status "1Password installed"
}

# Install and setup ZSH
install_zsh() {
    if ! ask_proceed "Install and configure ZSH with Oh My Zsh?"; then
        print_info "Skipped ZSH installation"
        return
    fi
    
    print_section "Installing ZSH"
    
    if ! command -v zsh &> /dev/null; then
        print_info "Installing ZSH..."
        wait_for_apt_lock
        sudo apt install -y zsh
    fi
    
    if [ "$SHELL" != "$(which zsh)" ]; then
        print_info "Setting ZSH as default shell..."
        chsh -s $(which zsh)
        print_info "Default shell changed (takes effect after logout)"
    fi
    
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        print_info "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        
        if [ -f ~/.zshrc ] && ! grep -q "starship init zsh" ~/.zshrc; then
            echo 'eval "$(starship init zsh)"' >> ~/.zshrc
            print_info "Added Starship to .zshrc"
        fi
        print_status "Oh My Zsh installed"
    else
        print_status "ZSH already configured"
    fi
}

# Deploy dotfiles using GNU Stow
deploy_dotfiles() {
    if ! ask_proceed "Deploy dotfiles with GNU Stow?"; then
        print_info "Skipped dotfile deployment"
        return
    fi
    
    print_section "Deploying dotfiles"
    
    if ! command -v stow &> /dev/null; then
        print_info "Installing stow..."
        wait_for_apt_lock
        sudo apt install -y stow
    fi
    
    sleep 1
    hash -r
    
    BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
    local need_backup=false
    
    # Check each file
    for file in .zshrc .config/ghostty/config .config/starship.toml; do
        if [ -e "$HOME/$file" ] && [ ! -L "$HOME/$file" ]; then
            need_backup=true
            break
        fi
    done
    
    # If files exist and aren't symlinks, ask what to do
    if [ "$need_backup" = true ]; then
        echo ""
        print_info "Existing config files detected"
        echo "  1) Keep existing (skip stow)"
        echo "  2) Backup and replace with repo configs"
        echo "  3) Merge manually later"
        read -p "Choose [1-3]: " -n 1 -r choice
        echo ""
        
        case $choice in
            1)
                print_status "Kept existing configs"
                return
                ;;
            2)
                mkdir -p "$BACKUP_DIR"
                for file in .zshrc .config/ghostty/config .config/starship.toml; do
                    if [ -e "$HOME/$file" ] && [ ! -L "$HOME/$file" ]; then
                        print_info "Backing up $file..."
                        mkdir -p "$BACKUP_DIR/$(dirname "$file")"
                        cp -r "$HOME/$file" "$BACKUP_DIR/$file" 2>/dev/null
                        rm -rf "$HOME/$file"
                    fi
                done
                
                if [ -d "$HOME/.config/ghostty" ] && [ ! -L "$HOME/.config/ghostty" ]; then
                    rm -rf "$HOME/.config/ghostty"
                fi
                print_info "Backups saved to: $BACKUP_DIR"
                ;;
            3)
                print_status "Skipped - merge manually"
                return
                ;;
            *)
                print_status "Invalid choice - skipped"
                return
                ;;
        esac
    fi
    
    cd "$SCRIPT_DIR"
    
    for package in ghostty starship zsh; do
        if [ -d "$package" ]; then
            print_info "Stowing $package..."
            stow -R -t "$HOME" "$package"
        fi
    done
    
    cd - > /dev/null
    
    print_status "Dotfiles deployed"
    rmdir "$BACKUP_DIR" 2>/dev/null
}

# Main execution
main() {
    echo -e "${GREEN}"
    cat << "EOF"
██╗███╗   ██╗███████╗████████╗ █████╗ ██╗     ██╗         ██████╗  ██████╗ ████████╗    ███████╗██╗██╗     ███████╗███████╗
██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║         ██╔══██╗██╔═══██╗╚══██╔══╝    ██╔════╝██║██║     ██╔════╝██╔════╝
██║██╔██╗ ██║███████╗   ██║   ███████║██║     ██║         ██║  ██║██║   ██║   ██║       █████╗  ██║██║     █████╗  ███████╗
██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║     ██║         ██║  ██║██║   ██║   ██║       ██╔══╝  ██║██║     ██╔══╝  ╚════██║
██║██║ ╚████║███████║   ██║   ██║  ██║███████╗███████╗    ██████╔╝╚██████╔╝   ██║       ██║     ██║███████╗███████╗███████║
╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝    ╚═════╝  ╚═════╝    ╚═╝       ╚═╝     ╚═╝╚══════╝╚══════╝╚══════╝
EOF
    echo -e "${NC}"
    echo -e "${BLUE}Pop!_OS Setup - Interactive Dotfiles Installer${NC}"
    echo ""
    
    read -p "Continue with installation? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_error "Cancelled"
        exit 1
    fi
    
    update_system
    install_nala
    install_apt_packages
    hash -r
    install_flatpak_packages
    install_ghostty
    install_brave
    install_starship
    install_tailscale
    install_1password
    install_zsh
    deploy_dotfiles
    
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC}     Installation Complete! ✓         ${GREEN}║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════╝${NC}"
    
    PARENT_SHELL=$(ps -p $PPID -o comm=)
    if [[ "$PARENT_SHELL" == *"zsh"* ]]; then
        echo ""
        print_info "Run: source ~/.zshrc"
    else
        echo ""
        read -p "Start ZSH now? (y/n) " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            exec zsh -l
        else
            print_info "Run: exec zsh"
        fi
    fi
}

# Run main function
main