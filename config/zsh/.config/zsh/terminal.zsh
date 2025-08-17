#!/usr/bin/env zsh

function _load_compinit() {
    # Initialize completions with optimized performance
    autoload -Uz compinit

    # Enable extended glob for the qualifier to work
    setopt EXTENDED_GLOB

    # Fastest - use glob qualifiers on directory pattern
    if [[ -n ${ZDOTDIR}/.zcompdump(#qN.mh+${HYDE_ZSH_COMPINIT_CHECK:-1}) ]]; then
        compinit
    else
        compinit -C
    fi

    _comp_options+=(globdots) # tab complete hidden files
}
function _load_functions() {
    # Load all custom function files // Directories are ignored
    for file in "${ZDOTDIR:-$HOME/.config/zsh}/functions/"*.zsh; do
        [ -r "$file" ] && source "$file"
    done
}
function _load_completions() {
    for file in "${ZDOTDIR:-$HOME/.config/zsh}/completions/"*.zsh; do
        [ -r "$file" ] && source "$file"
    done
}
function _load_plugin(){
    [ -f "${ZDOTDIR:-$HOME/.config/zsh}/plugin.zsh" ] && source "${ZDOTDIR:-$HOME/.config/zsh}/plugin.zsh"
}
function _load_prompt(){
     [ -f "${ZDOTDIR:-$HOME/.config/zsh}/prompt.zsh" ] && source "${ZDOTDIR:-$HOME/.config/zsh}/prompt.zsh"
}
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
HISTFILE=${HISTFILE:-${ZDOTDIR}/.zsh_history}
HISTSIZE=10000
SAVEHIST=10000
export HISTFILE ZSH_AUTOSUGGEST_STRATEGY HISTSIZE SAVEHIST

_load_compinit
_load_plugin
_load_prompt
_load_functions
_load_completions
