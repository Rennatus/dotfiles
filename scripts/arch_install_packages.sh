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
if [ $# -eq 0 ]; then
  print_log -err "no provided a install packages list"
  exit 1
fi

packages="${1}"
arch_pkg=()
aur_pkg=()

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
done < <(cut -d '#' -f1 "${packages}")

echo ""
install_packages arch_pkg "arch" "sudo pacman"
install_packages aur_pkg "aur" "${AUR_HELPER}"
