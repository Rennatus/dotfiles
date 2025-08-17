#!/bin/bash

set -euo pipefail
source ./scripts/utils/utils.sh

CURRENT_DIR="$(dirname "$(realpath "$0")")"
readonly stow_dir="$CURRENT_DIR/config"
readonly stow_target="$HOME"

backup_config() {
  local path="$1"
  local backup_dir
  backup_dir="$HOME/.config/dotfiles-backup/$(date +%Y%m%d_%H%M%S)"

  if [[ -e "$path" ]]; then
    mkdir -p "$backup_dir"
    print_log -g "[config]" -b "::" "Backing up config $path"
    cp -r "$path" "$backup_dir/$(basename "${path}")"
  fi
}

# Safe remove function with logging and confirmation
safe_remove() {
  local path="$1"
  if [[ ! -e "$path" ]]; then
    return 0
  fi
  backup_config "$path"
  print_log -g "[config]" -b "::" "Removing existing config: $path"
  rm -rf "$path"
}

# Safe stow function with error handling
safe_stow() {
  local package="${1}"
  local package_path="$stow_dir/$package"

  if [[ ! -d "$package_path" ]]; then
    print_log -warn "Package '$package' not found in $stow_dir"
    return 1
  fi
  if stow --dir="${stow_dir}" --target="${stow_target}" "$package" 2>/dev/null; then
    print_log -g "[config]" -b "Successfully stowed package: $package"
  else
    print_log -err "Failed to stow: $package"
    return 1
  fi
}

deploy_common_packages() {
  print_log -stat "Deploying common packages..."
  # Git configuration
  # safe_remove "$HOME/.gitignore"
  # safe_remove "$HOME/.config/git"
  # safe_stow "git"

  # fastfetch
  safe_remove "$HOME/.config/fastfetch"
  safe_stow "fastfetch"

  # startship
  safe_remove "$HOME/.config/starship"
  safe_stow "starship"

  # zsh
  safe_remove "$HOME/.config/zsh"
  safe_remove "$HOME/.zshenv"
  safe_remove "$HOME/.zshrc"
  safe_stow "zsh"

  # kitty
  safe_remove "$HOME/kitty"
  safe_stow "kitty"

  # Neovim configuration
  safe_remove "$HOME/.config/nvim"
  safe_stow "nvim"

  # yazi
  safe_remove "$HOME/.config/yazi"
  safe_stow "yazi"

  # OpenCode configuration
  # safe_remove "$HOME/.config/opencode"
  # safe_stow "opencode"

  # Scripts
  # safe_remove "$HOME/.local/bin"
  # safe_stow "scripts"
}
deploy_arch_packages() {
  # fcitx5
  safe_remove "$HOME/.local/share/fcitx5"
  safe_stow "fcitx5"
  # waybar
  safe_remove "$HOME/.config/waybar"
  safe_stow "waybar"
  #xdg-terminal-exec
  safe_remove "$HOME/xdg-terminals.list"
  safe_stow "xdg-terminal-exec"
  # gtk3.0
  safe_remove "$HOME/.config/gtk-3.0"
  safe_stow "gtk-3.0"
  # hypr
  safe_remove "$HOME/.config/hypr"
  safe_stow "hypr"
  # hyde
  safe_remove "$HOME/.config/hyde"
  safe_stow "hyde"
  print_log -g "[python env]" -b " :: " "Rebuilding HyDE Python environment..."
  "${HOME}"/.config/hyde/hyde-shell pyinit
}

deploy_common_packages
if is_archlinux; then
  deploy_arch_packages
fi
