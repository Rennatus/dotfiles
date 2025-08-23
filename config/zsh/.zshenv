#!/usr/bin/env zsh

export ZDOTDIR="${ZDODTDIR:-$HOME/.config/zsh}"

if ! source $ZDOTDIR/.zshenv; then
    echo "FATAL Error: Could not source $ZDOTDIR/.zshenv"
    return 1
fi
. $ZDOTDIR/.zshenv
