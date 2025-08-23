#!/usr/bin/env zsh

if command -v starship &>/dev/null; then
    # ===== START Initialize Starship prompt =====
    eval "$(starship init zsh)"
    export STARSHIP_CACHE=${XDG_CACHE_HOME:-$HOME/.cache}/starship
    export STARSHIP_CONFIG=${XDG_CONFIG_HOME:-$HOME/.config}/starship/starship.toml
# ===== END Initialize Starship prompt =====
fi

