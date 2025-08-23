#!/usr/bin/env bash

set -euo pipefail

CURRENT_DIR="$(dirname "$(realpath "$0")")"
ROOT_DIR="$(dirname "${CURRENT_DIR}")"
readonly stow_dir="$ROOT_DIR/config"
readonly stow_target="$HOME"

TIME="$(date +'%y%m%d_%Hh%Mm%Ss')"
export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.ustc.edu.cn/homebrew-bottles

print_log() {
  local executable="${0##*/}"
  local log_file="${XDG_CACHE_HOME:-$HOME/.cache}/logs/${TIME}/${executable}"
  mkdir -p "$(dirname "${log_file}")"
  local section=${log_section:-}
  {
    [ -n "${section}" ] && echo -ne "\033[32m[$section] \033[0m"
    while (("$#")); do
      case "$1" in
      -r | +r)
        echo -ne "\033[31m$2\033[0m"
        shift 2
        ;; # Red
      -g | +g)
        echo -ne "\033[32m$2\033[0m"
        shift 2
        ;; # Green
      -y | +y)
        echo -ne "\033[33m$2\033[0m"
        shift 2
        ;; # Yellow
      -b | +b)
        echo -ne "\033[34m$2\033[0m"
        shift 2
        ;; # Blue
      -m | +m)
        echo -ne "\033[35m$2\033[0m"
        shift 2
        ;; # Magenta
      -c | +c)
        echo -ne "\033[36m$2\033[0m"
        shift 2
        ;; # Cyan
      -wt | +w)
        echo -ne "\033[37m$2\033[0m"
        shift 2
        ;; # White
      -n | +n)
        echo -ne "\033[96m$2\033[0m"
        shift 2
        ;; # Neon
      -stat)
        echo -ne "\033[30;46m $2 \033[0m :: "
        shift 2
        ;; # status
      -crit)
        echo -ne "\033[97;41m $2 \033[0m :: "
        shift 2
        ;; # critical
      -warn)
        echo -ne "WARNING :: \033[30;43m $2 \033[0m :: "
        shift 2
        ;; # warning
      +)
        echo -ne "\033[38;5;$2m$3\033[0m"
        shift 3
        ;; # Set color manually
      -err)
        echo -ne "ERROR :: \033[4;31m$2 \033[0m"
        shift 2
        ;; #error
      *)
        echo -ne "$1"
        shift
        ;;
      esac
    done
    echo ""
  } | if [ -n "${TIME}" ]; then
    tee >(sed 's/\x1b\[[0-9;]*m//g' >>"${log_file}")
  else
    cat
  fi
}

install_packages() {
  local packages=("$@")
  if [[ ${#packages[@]} -gt 0 ]]; then
    print_log -g "[install] " -b "brew install packages.."
    for package in "${packages[@]}"; do
      print_log -g "[install] " -b "install ${package}"
      brew install -q "${package}"
    done
  fi
}

backup_config() {
  local path="$1"
  local backup_dir
  backup_dir="$HOME/.config/dotfiles-backup/${TIME}"

  if [[ -e "$path" ]]; then
    /bin/mkdir -p "$backup_dir"
    print_log -g "[config]" -b "::" "Backing up config $path"
    cp -r "$path" "$backup_dir/$(basename "${path}")"
  fi
}

# Safe remove function with logging and confirmation
safe_remove() {
  local path=$1
  if [[ ! -e "$path" ]]; then
    return
  fi
  backup_config "$path"
  print_log -g "[config]" -b "::" "Removing existing config: $path"
  rm -rf "$path"
}

# Safe stow function with error handling
safe_stow() {
  if [ $# -eq 0 ]; then
    return 1
  fi
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

deploy_config() {
  print_log -stat "Deploying common packages..."
  # Git configuration
  # safe_remove "$HOME/.gitignore"
  # safe_remove "$HOME/.config/git"
  # safe_stow "git"

  # zsh
  safe_remove "$HOME/.config/zsh"
  safe_remove "$HOME/.zshenv"
  safe_remove "$HOME/.zshrc"
  safe_stow "zsh"

  # fastfetch
  safe_remove "$HOME/.config/fastfetch"
  safe_stow "fastfetch"

  # startship
  safe_remove "$HOME/.config/starship"
  safe_stow "starship"

  # Neovim configuration
  safe_remove "$HOME/.config/nvim"
  safe_stow "nvim"

  # yazi
  safe_remove "$HOME/.config/yazi"
  safe_stow "yazi"

  # kitty
  safe_remove "$HOME/kitty"
  safe_stow "kitty"

  # matugen
  safe_remove "$HOME/matugen"
  safe_stow "matugen"

  # OpenCode configuration
  # safe_remove "$HOME/.config/opencode"
  # safe_stow "opencode"

  # Scripts
  # safe_remove "$HOME/.local/bin"
  # safe_stow "scripts"
}

packages=()
print_log -g "[packages] " -b "preparation install packages list..."
cp "${CURRENT_DIR}/packages/core.lst" "${CURRENT_DIR}/mac_install_pkg.lst"
cat "${CURRENT_DIR}/packages/mac.lst" >>"${CURRENT_DIR}/mac_install_pkg.lst"
while IFS='#' read -r package _; do
  package=$(echo "$package" | xargs)
  [ -z "$package" ] && continue
  packages+=("$package")
done <"${CURRENT_DIR}/mac_install_pkg.lst"

install_packages "${packages[@]}"

deploy_config
