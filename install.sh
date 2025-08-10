#!/bin/bash

set -euo pipefail

readonly src_dir="$(dirname "$(realpath "$0")")"
# shellcheck disable=SC1091
if ! source "${src_dir}/utils.sh"; then
    echo "Error: unable to source utils.sh..."
    exit 1
fi

deploy_common_packages() {
    print_log -stat "Deploying common packages..."
    
    # Git configuration
    # safe_remove "$HOME/.gitignore"
    # safe_remove "$HOME/.config/git"
    # safe_stow "git"
    
    # startship
    safe_stow "starship"
    # fastfetch
    safe_stow "fastfetch"
    # Zsh configuration
    safe_remove "$HOME/.zshenv"
    safe_remove "$HOME/.zshrc"
    safe_stow "zsh"
    
    # Neovim configuration
    # safe_remove "$HOME/.config/nvim"
    # safe_stow "nvim"
    
    # OpenCode configuration
    # safe_remove "$HOME/.config/opencode"
    # safe_stow "opencode"
    
    # Scripts
    # safe_remove "$HOME/.local/bin"
    # safe_stow "scripts"
}

if is_archlinux;then
    "${src_dir}/config_arch.sh"
    deploy_common_packages
fi
