#!/usr/bin/env zsh

# XDG Base Directory
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
XDG_DATA_DIRS="${XDG_DATA_DIRS:-$XDG_DATA_HOME:/usr/local/share:/usr/share}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# 检查当前 Shell 是否为交互式（interactive）
if [[ $- == *i* ]] && [ -f "$ZDOTDIR/terminal.zsh" ]; then
    . "$ZDOTDIR/terminal.zsh" || echo "Error: Could not source $ZDOTDIR/terminal.zsh"
fi

