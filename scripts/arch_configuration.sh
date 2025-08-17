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

# packages
print_log -g "[packages] " -b "preparation install packages list..."
cp "${CURRENT_DIR}/packages/core.lst" "${CURRENT_DIR}/arch_install_pkg.lst"
cat "${CURRENT_DIR}/packages/arch.lst" >>"${CURRENT_DIR}/arch_install_pkg.lst"

if nvidia_detect; then
  nvidia_detect --verbose
  echo "# nvidia" >>"${CURRENT_DIR}/arch_install_pkg.lst"
  print_log -g "[packages] " -b "adding nvidia packages"
  cat /usr/lib/modules/*/pkgbase | while read -r kernel; do
    echo "${kernel}-headers" >>"${CURRENT_DIR}/arch_install_pkg.lst"
  done
  nvidia_detect --driver >>"${CURRENT_DIR}/arch_install_pkg.lst"
  if pkg_installed grub; then
    print_log -g "[bootloader] " -b "nvidia detected, adding nvidia_drm.modeset=1 to boot options"
    gcld=$(grep "^GRUB_CMDLINE_LINUX_DEFAULT=" "/etc/default/grub" | cut -d '"' -f2 | sed 's/\b nvidia_drm.modeset=.\b//g')
    sudo sed -i "/^GRUB_CMDLINE_LINUX_DEFAULT=/c\GRUB_CMDLINE_LINUX_DEFAULT=\"${gcld} nvidia_drm.modeset=1\"" /etc/default/grub
    print_log -g "[bootloader] " -b "grub-mkconfig..."
    sudo grub-mkconfig -o /boot/grub/grub.cfg
  fi
fi

print_log -g "[packages] " -b "install packages..."
"${CURRENT_DIR}/arch_install_packages.sh" "${CURRENT_DIR}/arch_install_pkg.lst"
