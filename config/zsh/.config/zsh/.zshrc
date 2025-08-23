#!/usr/bin/env zsh

if command -v starship &>/dev/null; then
    eval "$(starship init zsh)"
    export STARSHIP_CACHE=${XDG_CACHE_HOME:-$HOME/.cache}/starship
    export STARSHIP_CONFIG=${XDG_CONFIG_HOME:-$HOME/.config}/starship/starship.toml
fi

if is_archlinux;then 
  # XDG Base Directory
  # export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
  # export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
  # export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
  # export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
  # export XDG_DATA_DIRS="${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
  # export XDG_CONFIG_DIRS="${XDG_DATA_DIRS:-/etc/xdg}"
  [ -f ${ZDOTDIR}/linux.zsh ] && source ${ZDOTDIR}/linux.zsh
fi

if is_macos;then
    [ -f ${ZDOTDIR}/mac.zsh ] && source ${ZDOTDIR}/mac.zsh
fi

