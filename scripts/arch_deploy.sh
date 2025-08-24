#!/usr/bin/env bash

set -euo pipefail
source ./utils/utils.sh
ROOT_DIR="$(dirname $(dirname "$(realpath "$0")"))"
readonly stow_dir="$ROOT_DIR/config"
readonly stow_target="$HOME"

backup_config() {
  local path="$1"
  local backup_dir
  backup_dir="$HOME/dotfiles-backup/$(date +%Y%m%d_%H%M%S)"
  if [[ -e "$path" ]]; then
    mkdir -p "$backup_dir"
    print_log -g "[backup]" -b "::" "Backing up config $path"
    cp -r "$path" "$backup_dir/$(basename "${path}")"
  fi
}

# Safe remove function with logging and confirmation
safe_remove() {
  local path="$1"
  if [[ ! -e "$path" ]]; then
    return
  fi
  backup_config "$path"
  print_log -g "[remove] " -b "::" "Removing existing config: $path"
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
    return 0
  else
    print_log -err "Failed to stow: $package"
    return 1
  fi
}

deploy() {
  print_log -g "[deploy] " -b "::" "Deploying config ..."
  # Git configuration
  # safe_remove "$HOME/.gitignore"
  # safe_remove "$HOME/.config/git"
  # safe_stow "git"

  # zsh
  safe_remove "$HOME/.config/zsh"
  safe_remove "$HOME/.zshrc"
  safe_stow "zsh"

  # Neovim configuration
  safe_remove "$HOME/.config/nvim"
  safe_stow "nvim"

  # startship
  safe_remove "$HOME/.config/starship"
  safe_stow "starship"

  # kitty
  safe_remove "$HOME/.config/kitty"
  safe_stow "kitty"

  # fcitx5
  safe_remove "$HOME/.local/share/fcitx5/rime"
  safe_stow "fcitx5"
  # fastfetch
  #safe_remove "$HOME/.config/fastfetch"
  #safe_stow "fastfetch"

  # yazi
  #safe_remove "$HOME/.config/yazi"
  #safe_stow "yazi"

  # OpenCode configuration
  # safe_remove "$HOME/.config/opencode"
  # safe_stow "opencode"

  # Scripts
  # safe_remove "$HOME/.local/bin"
  # safe_stow "scripts"
}

deploy
