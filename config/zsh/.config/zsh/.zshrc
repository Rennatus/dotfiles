#!/usr/bin/env zsh
source "$ZDOTDIR/utils.zsh"
if is_archlinux; then
    [ -f "$ZDOTDIR/linux/linux.zsh" ] && source  "$ZDOTDIR/linux/linux.zsh"
elif is_macos;then
    [ -f "$ZDOTDIR/mac/mac.zsh" ] && source "$ZDOTDIR/mac/mac.zsh"
fi