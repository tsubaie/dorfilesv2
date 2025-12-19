# Dotfiles v2

My Pop!_OS setup scripts and configuration files managed with GNU Stow.

## Quick Start

On a fresh Pop!_OS installation:
```bash
git clone git@github.com:tsubaie/dorfilesv2.git ~/dotfiles
cd ~/dotfiles
chmod +x install.sh
./install.sh
```

The script will:
1. Install all packages (APT, Flatpak, Ghostty, Brave, Starship, Tailscale, ZSH)
2. Automatically deploy dotfiles using GNU Stow

## Structure
```
dotfiles/
├── install.sh              # Main installation script
├── packages/
│   ├── apt.txt            # APT packages
│   └── flatpak.txt        # Flatpak applications
├── ghostty/
│   └── .config/ghostty/   # Ghostty config (stow package)
├── starship/
│   └── .config/           # Starship config (stow package)
├── zsh/
│   └── .zshrc             # ZSH config (stow package)
└── README.md
```

## What Gets Installed

### Package Managers
- APT packages from `packages/apt.txt`
- Flatpak apps from `packages/flatpak.txt`

### Applications
- **Ghostty** - Modern terminal emulator
- **Brave** - Privacy-focused browser
- **Starship** - Cross-shell prompt
- **Tailscale** - VPN mesh network (configured as exit node)
- **ZSH** with Oh My Zsh
- **GNU Stow** - Dotfile management

### Configurations (via Stow)
- Ghostty terminal settings
- Starship prompt customization
- ZSH configuration

## Manual Steps After Installation

1. **Log out and log back in** - Required for ZSH to become default shell
2. **Approve Tailscale exit node** - Visit https://login.tailscale.com/admin/machines
3. **Source your shell config** - Run `source ~/.zshrc` or restart terminal

## Managing Dotfiles with Stow

### Deploy/Update specific config
```bash
cd ~/dotfiles
stow -R ghostty    # Re-stow (update) Ghostty config
stow -R starship   # Re-stow Starship config
stow -R zsh        # Re-stow ZSH config
```

### Remove config symlinks
```bash
stow -D ghostty    # Remove Ghostty symlinks
```

### Deploy all configs
```bash
stow -R ghostty starship zsh
```

## Adding New Dotfiles

1. Create a new directory for the application
2. Mirror your home directory structure inside it
3. Move your config files there
4. Stow it

Example:
```bash
mkdir -p nvim/.config/nvim
cp ~/.config/nvim/init.lua nvim/.config/nvim/
stow nvim
```

## Customization

### Add More Packages
Edit the package files:
- `packages/apt.txt` - One package per line
- `packages/flatpak.txt` - One Flatpak app ID per line

Lines starting with `#` are comments.

### Modify Configurations
Edit files in their respective stow package directories and run:
```bash
cd ~/dotfiles
stow -R <package-name>
```

## Updating Repository

After making changes:
```bash
git add .
git commit -m "Update configuration"
git push
```

## Why GNU Stow?

- ✅ Simple and lightweight
- ✅ Creates symlinks automatically
- ✅ Easy to manage multiple configs
- ✅ Can enable/disable configs easily
- ✅ No custom scripts needed
- ✅ Standard tool used by many dotfile repos



## Syncing Changes

### Push changes to GitHub
After modifying your dotfiles:
```bash
./push.sh
```

This will:
- Show you what changed
- Ask for a commit message
- Commit and push to GitHub

### Pull changes from GitHub
To get the latest dotfiles from another machine:
```bash
./pull.sh
```

This will:
- Pull the latest changes
- Ask if you want to apply them (restow)
- Apply configs if confirmed
