#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail


LOG_TIME="$(date +'%y%m%d_%Hh%Mm%Ss')"

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
  local log_file="${XDG_CACHE_HOME}/logs/${LOG_TIME}/${executable}"
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


