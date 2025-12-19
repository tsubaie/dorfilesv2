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

print_info "Pushing dotfiles to GitHub..."
echo ""

# Check if there are changes
if [[ -z $(git status -s) ]]; then
    print_info "No changes to commit"
    exit 0
fi

# Show status
print_info "Changes detected:"
git status -s
echo ""

# Ask for commit message
read -p "Enter commit message (or press Enter for default): " commit_msg

if [ -z "$commit_msg" ]; then
    commit_msg="Update dotfiles $(date +'%Y-%m-%d %H:%M:%S')"
fi

# Add all changes
print_info "Adding changes..."
git add .

# Commit
print_info "Committing changes..."
git commit -m "$commit_msg"

if [ $? -ne 0 ]; then
    print_error "Commit failed"
    exit 1
fi

print_status "Changes committed"

# Push to remote
print_info "Pushing to GitHub..."
git push

if [ $? -ne 0 ]; then
    print_error "Push failed"
    exit 1
fi

print_status "Successfully pushed to GitHub!"
