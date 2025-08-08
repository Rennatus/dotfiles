#!/usr/bin/env zsh
if ! . "$ZDOTDIR/conf.d/env.zsh"; then
    echo "Error: Could not source $ZDOTDIR/conf.d/env.zsh"
    return 1
fi
if [[ $- == *i* ]] && [ -f "$ZDOTDIR/conf.d/binds.zsh" ]; then
    . "$ZDOTDIR/conf.d/prompt.zsh" || echo "Error: Could not source $ZDOTDIR/conf.d/binds.zsh"
fi

if [[ $- == *i* ]] && [ -f "$ZDOTDIR/conf.d/prompt.zsh" ]; then
    . "$ZDOTDIR/conf.d/prompt.zsh" || echo "Error: Could not source $ZDOTDIR/conf.d/prompt.zsh"
fi

if [[ $- == *i* ]] && [ -f "$ZDOTDIR/conf.d/terminal.zsh" ]; then
    . "$ZDOTDIR/conf.d/terminal.zsh" || echo "Error: Could not source $ZDOTDIR/conf.d/terminal.zsh"
fi