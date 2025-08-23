#!/usr/bin/env zsh
if command -v "eza" &>/dev/null; then
    alias l='eza -lh --icons=auto'
    alias ll='eza -lha --icons=auto --sort=name --group-directories-first'  
    alias ld='eza -lhD --icons=auto'
    alias lt='eza --icons=auto --tree'
fi
