#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

CURRENT_DIR="$(dirname "$(realpath "$0")")"
source ./utils/utils.sh

# pacman
print_log -g "[pacman] " -b "configuration pacman..."
if [ -f /etc/pacman.conf ]; then
  print_log -g "[pacman] " -b "adding extra spice to pacman."
  sudo sed -i "/^#Color/c\Color\nILoveCandy
    /^#VerbosePkgLists/c\VerbosePkgLists
    /^#ParallelDownloads/c\ParallelDownloads = 5" /etc/pacman.conf
  sudo sed -i '/^#\[multilib\]/,+1 s/^#//' /etc/pacman.conf
  print_log -g "[pacman] " -b "adding archlinuxcn."
  if grep -q "\[archlinuxcn\]" /etc/pacman.conf; then
    print_log -stat "skipped" -y "archlinuxcn entry found in pacman.conf."
  else
    echo -e "\n[archlinuxcn\]\nServer = https://mirrors.ustc.edu.cn/archlinuxcn/\$arch" | sudo tee -a /etc/pacman.conf
  fi
  print_log -g "[pacman] " -b "update packages."
  sudo pacman -Syyu --noconfirm
fi

# aur
print_log -g "[aur] " -b "configuration aur..."
if pkg_installed "${AUR_HELPER}"; then
  print_log -stat "skipped" -y "${AUR_HELPER} aready installed"
else
  if pkg_installed git; then
    git clone "https://aur.archlinux.org/${AUR_HELPER}.git" "${CACHE_DIR}/${AUR_HELPER}"
  else
    print_log -err "missing git as dependency..."
    exit 1
  fi
  cd "${CACHE_DIR}/${AUR_HELPER}" || exit
  if makepkg -si; then
    print_log -g "[aur] " -b "installed ${AUR_HELPER}"
  else
    print_log -err "${AUR_HELPER} installation failed..."
    exit 1
  fi
fi


