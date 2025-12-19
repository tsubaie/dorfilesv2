# Dotfiles v2

My Pop!_OS setup scripts and configuration files.

## Quick Start

On a fresh Pop!_OS installation:
```bash
git clone https://github.com/tsubaie/dorfilesv2.git ~/dotfiles
cd ~/dotfiles
chmod +x install.sh
./install.sh
```

## Structure

- `install.sh` - Main installation script
- `packages/apt.txt` - APT packages to install
- `packages/flatpak.txt` - Flatpak applications to install

## Usage

Run the installation script:
```bash
./install.sh
```

The script will:
1. Update system packages
2. Install all APT packages from `packages/apt.txt`
3. Install all Flatpak apps from `packages/flatpak.txt`

## Customization

Edit the package files to add or remove software:
- `packages/apt.txt` - One package name per line
- `packages/flatpak.txt` - One Flatpak application ID per line

Lines starting with `#` are treated as comments.
