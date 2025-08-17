#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

# 定义全局变量
readonly XDG_CONFIG_HOME=$HOME/.config
readonly XDG_CACHE_HOME=$HOME/.cache
readonly XDG_DATA_HOME=$HOME/.local/share
readonly XDG_DATA_HOME=$HOME/.local/state

readonly AUR_HELPER="yay"
LOG_TIME="$(date +'%y%m%d_%Hh%Mm%Ss')"
# readonly src_dir="$(dirname "$(realpath "$0")")"
# readonly conf_dir="${XDG_CONFIG_HOME:-$HOME/.config}"
# readonly cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/install_stow"
# readonly log_time="$(date +'%y%m%d_%Hh%Mm%Ss')"

is_archlinux() {
  # 检查标志性文件 /etc/arch-release
  if [ -f "/etc/arch-release" ]; then
    return 0 # 是 Arch Linux，返回成功状态码
  fi
  # 辅助检查 /etc/os-release 确认
  if grep -q "Arch Linux" /etc/os-release 2>/dev/null; then
    return 0
  fi
  return 1 # 不是 Arch Linux，返回失败状态码
}

is_macos() {
  # 方法1：检查内核名称（最可靠）
  # macOS 的内核名称为 "Darwin"，而 Linux 为 "Linux"，Windows WSL 可能为 "Linux" 等
  if [ "$(uname -s)" = "Darwin" ]; then
    return 0
  fi
  # 方法2：检查 macOS 特有的目录（辅助验证）
  # /System/Library/CoreServices 是 macOS 核心服务目录，Linux 等系统无此路径
  if [ -d "/System/Library/CoreServices" ]; then
    return 0
  fi
  # 以上条件均不满足，返回非 macOS
  return 1
}

pkg_installed() {
  local pkg=$1
  if pacman -Q "${pkg}" &>/dev/null; then
    return 0
  else
    return 1
  fi
}

pkg_available() {
  local pkg=$1
  if pacman -Si "${pkg}" &>/dev/null; then
    return 0
  else
    return 1
  fi
}

aur_available() {
  local pkg=$1
  # shellcheck disable=SC2154
  if ${AUR_HELPER} -Si "${pkg}" &>/dev/null; then
    return 0
  else
    return 1
  fi
}

nvidia_detect() {
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

handle_legacy_service() {
  local service="$1"
  # Use the original logic for backward compatibility
  if [[ $(systemctl list-units --all -t service --full --no-legend "${service}.service" | sed 's/^\s*//g' | cut -f1 -d' ') == "${service}.service" ]]; then
    print_log -y "[skip] " -b "active " "Service ${service}"
  else
    print_log -y "enable " "Service ${service}"
    sudo systemctl enable "${service}.service"
  fi
}

print_log() {
  local executable="${0##*/}"
  local log_file="${CACHE_DIR}/logs/${LOG_TIME}/${executable}"
  mkdir -p "$(dirname "${log_file}")"
  local section=${log_section:-}
  {
    [ -n "${section}" ] && echo -ne "\e[32m[$section] \e[0m"
    while (("$#")); do
      case "$1" in
      -r | +r)
        echo -ne "\e[31m$2\e[0m"
        shift 2
        ;; # Red
      -g | +g)
        echo -ne "\e[32m$2\e[0m"
        shift 2
        ;; # Green
      -y | +y)
        echo -ne "\e[33m$2\e[0m"
        shift 2
        ;; # Yellow
      -b | +b)
        echo -ne "\e[34m$2\e[0m"
        shift 2
        ;; # Blue
      -m | +m)
        echo -ne "\e[35m$2\e[0m"
        shift 2
        ;; # Magenta
      -c | +c)
        echo -ne "\e[36m$2\e[0m"
        shift 2
        ;; # Cyan
      -wt | +w)
        echo -ne "\e[37m$2\e[0m"
        shift 2
        ;; # White
      -n | +n)
        echo -ne "\e[96m$2\e[0m"
        shift 2
        ;; # Neon
      -stat)
        echo -ne "\e[30;46m $2 \e[0m :: "
        shift 2
        ;; # status
      -crit)
        echo -ne "\e[97;41m $2 \e[0m :: "
        shift 2
        ;; # critical
      -warn)
        echo -ne "WARNING :: \e[30;43m $2 \e[0m :: "
        shift 2
        ;; # warning
      +)
        echo -ne "\e[38;5;$2m$3\e[0m"
        shift 3
        ;; # Set color manually
      -err)
        echo -ne "ERROR :: \e[4;31m$2 \e[0m"
        shift 2
        ;; #error
      *)
        echo -ne "$1"
        shift
        ;;
      esac
    done
    echo ""
  } | if [ -n "${LOG_TIME}" ]; then
    tee >(sed 's/\x1b\[[0-9;]*m//g' >>"${log_file}")
  else
    cat
  fi
}



