#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

. ./utils/utils.sh

install_packages() {
  local -n pkg_array=$1
  local pkg_type=$2
  local install_cmd=$3

  if [[ ${#pkg_array[@]} -gt 0 ]]; then
    print_log -b "[install] " "$pkg_type packages..."
    for pkg in "${pkg_array[@]}"; do
      print_log -b "[pkg] " "${pkg}"
    done
    $install_cmd ${use_default:+"$use_default"} -S "${pkg_array[@]}" --noconfirm
  fi
}

arch_pkg=()
aur_pkg=()

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
while read -r pkg; do
  pkg="${pkg// /}"
  if [[ -z "$pkg" ]]; then
    continue
  fi
  #print_log -g "[packages] " -stat "installing" -b "${pkg}"
  if pkg_installed "${pkg}"; then
    print_log -g "[packages] " -stat "[skip]" -y "${pkg}"
  elif pkg_available "${pkg}"; then
    repo=$(pacman -Si "${pkg}" | awk -F ': ' '/Repository / {print $2}' | tr '\n' ' ')
    print_log -g "[packages] " -stat "[queue]" -b "${pkg}" -g "${repo}"
    arch_pkg+=("${pkg}")
  elif aur_available "${pkg}"; then
    print_log -g "[packages] " -stat "[queue]" -b "${pkg}" -g "aur"
    aur_pkg+=("${pkg}")
  else
    print_log -r "unknown package ${pkg}"
  fi
done < <(cut -d '#' -f1 < arch_install_pkg.lst)

echo ""
install_packages arch_pkg "arch" "sudo pacman"
install_packages aur_pkg "aur" "${AUR_HELPER}"
