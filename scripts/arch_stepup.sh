#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

source ./utils/utils.sh
# 定义全局变量
CURRENT_DIR="$(dirname "$(realpath "$0")")"
XDG_CONFIG_HOME=$HOME/.config
XDG_CACHE_HOME=$HOME/.cache
XDG_DATA_HOME=$HOME/.local/share
XDG_STATE_HOME=$HOME/.local/state

LOG_TIME="$(date +'%y%m%d_%Hh%Mm%Ss')"

_install_packages() {
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

_config_pacman(){
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
      echo -e "\n[archlinuxcn]\nServer = https://mirrors.ustc.edu.cn/archlinuxcn/\$arch" | sudo tee -a /etc/pacman.conf
      sudo pacman-key --init
      sudo pacman-key --recv-keys 3056513887B78AEB
      sudo pacman-key --lsign-key 3056513887B78AEB
      sudo pacman -Sy archlinuxcn-keyring --noconfirm --needed 
    fi

    print_log -g "[pacman] " -b "update packages."
    sudo pacman -Syyu --noconfirm --needed
  fi
}

_install_yay() {
  print_log -g "[yay] " -b "install yay..."
  if pkg_installed yay; then
    print_log -stat "skipped" -y "yay aready installed"
  else
    if [[ ! $(_isInstalled "base-devel") == 0 ]]; then
        sudo pacman --noconfirm -S "base-devel"
    fi
    if [[ ! $(_isInstalled "git") == 0 ]]; then
        sudo pacman --noconfirm -S "git"
    fi
    if [ -d "${XDG_CACHE_HOME}/yay-bin" ]; then
        rm -rf "${XDG_CACHE_HOME}/yay-bin"
    fi
    git clone https://aur.archlinux.org/yay-bin.git "${XDG_CACHE_HOME}/yay-bin"
    cd "${XDG_CACHE_HOME}/yay-bin" || exit
    makepkg -si
    print_log -g "[aur] " -b "yay has been installed successfully"
  fi
}

_pkg_installed() {
  local pkg=$1
  if pacman -Q "${pkg}" &>/dev/null; then
    return 0
  else
    return 1
  fi
}

_pkg_available() {
  local pkg=$1
  if pacman -Si "${pkg}" &>/dev/null; then
    return 0
  else
    return 1
  fi
}

_yay_available() {
  local pkg=$1
  # shellcheck disable=SC2154
  if yay -Si "${pkg}" &>/dev/null; then
    return 0
  else
    return 1
  fi
}

_nvidia_detect() {
  readarray -t dGPU < <(lspci -k | grep -E "(VGA|3D)" | awk -F ': ' '{print $NF}')
  if [ $# -eq 0 ]; then
    if grep -iq nvidia <<<"${dGPU[@]}"; then
      return 0
    else
      return 1
    fi
  fi
  if [ "${1}" == '--verbose' ]; then
    for indx in "${!dGPU[@]}"; do
      echo -e "\033[0;32m [gpu$indx] \033[0m detected :: ${dGPU[indx]}"
    done
    return 0
  fi
  if [ "${1}" == "--driver" ]; then
    echo -e "nvidia-dkms\nnvidia-utils"
    return 0
  fi
}

_config_pacman
_install_yay

# --------------------------------------------------------------
# Inatall Packages
# --------------------------------------------------------------

arch_pkg=()
aur_pkg=()
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
  if pkg_installed "${pkg}"; then
    print_log -g "[packages] " -stat "[skip]" -y "${pkg}"
  elif pkg_available "${pkg}"; then
    repo=$(pacman -Si "${pkg}" | awk -F ': ' '/Repository / {print $2}' | tr '\n' ' ')
    print_log -g "[packages] " -stat "[queue]" -b "${pkg}--" -g "${repo}"
    arch_pkg+=("${pkg}")
  elif aur_available "${pkg}"; then
    print_log -g "[packages] " -stat "[queue]" -b "${pkg}" -g "aur"
    aur_pkg+=("${pkg}")
  else
    print_log -r "unknown package ${pkg}"
  fi
done < <(cut -d '#' -f1 < arch_install_pkg.lst)

echo ""
install_packages arch_pkg "arch" "sudo pacman" --noconfirm --needed
install_packages aur_pkg "aur" "yay" --noconfirm --needed

# --------------------------------------------------------------
# cursor
# --------------------------------------------------------------
print_log -g "[cursor] " -b "download cursor..."

download_folder="${XDG_CACHE_HOME}/bibata-cursors"
bibata_url="https://github.com/ful1e5/Bibata_Cursor/releases/download/v2.0.7/"

if [ -d $download_folder ]; then
    rm -rf $download_folder
fi
mkdir -p $download_folder
wget -P $download_folder $bibata_url/Bibata-Modern-Amber.tar.xz
wget -P $download_folder $bibata_url/Bibata-Modern-Classic.tar.xz
wget -P $download_folder $bibata_url/Bibata-Modern-Ice.tar.xz

if [ ! -d ~/.local/share/icons/ ]; then
    mkdir -p ~/.local/share/icons/
fi
if [ -d ~/.local/share/icons/Bibata-Modern-Amber ]; then
    rm -rf ~/.local/share/icons/Bibata-Modern-Amber
fi
if [ -d ~/.local/share/icons/Bibata-Modern-Classic ]; then
    rm -rf ~/.local/share/icons/Bibata-Modern-Classic
fi
if [ -d ~/.local/share/icons/Bibata-Modern-Amber ]; then
    rm -rf ~/.local/share/icons/Bibata-Modern-Ice
fi
tar -xf $download_folder/Bibata-Modern-Amber.tar.xz -C ~/.local/share/icons/
tar -xf $download_folder/Bibata-Modern-Classic.tar.xz -C ~/.local/share/icons/
tar -xf $download_folder/Bibata-Modern-Ice.tar.xz -C ~/.local/share/icons/