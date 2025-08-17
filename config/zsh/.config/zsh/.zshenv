#!/usr/bin/env zsh

# XDG Base Directory
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

XDG_DATA_DIRS="${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
XDG_CONFIG_DIRS="${XDG_DATA_DIRS:-/etc/xdg}"

# 检查当前 Shell 是否为交互式（interactive）
if [[ $- == *i* ]] && [ -f "$ZDOTDIR/terminal.zsh" ]; then
    . "$ZDOTDIR/terminal.zsh" || echo "Error: Could not source $ZDOTDIR/terminal.zsh"
fi

is_archlinux() {
    # 检查标志性文件 /etc/arch-release
    if [ -f "/etc/arch-release" ]; then
        return 0  # 是 Arch Linux，返回成功状态码
    fi
    # 辅助检查 /etc/os-release 确认
    if grep -q "Arch Linux" /etc/os-release 2>/dev/null; then
        return 0
    fi
    return 1  # 不是 Arch Linux，返回失败状态码
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

if is_archlinux;then
    [ -f ${ZDOTDIR}/linux/linux.zsh ] &&source ${ZDOTDIR}/linux/linux.zsh
fi




