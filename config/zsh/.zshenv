#!/usr/bin/env zsh



export ZDOTDIR="${ZDOTDIR:--$HOME/.config/zsh}"

if ! source $ZDOTDIR/.zshenv; then
    echo "FATAL Error: Could not source $ZDOTDIR/.zshenv"
    return 1
fi



