#!/usr/bin/env zsh

ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git --depth=1 "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

zinit light zsh-users/zsh-autosuggestions
zinit light zdharma-continuum/fast-syntax-highlighting
zinit light zsh-users/zsh-completions

# Loads a collection of handy Zsh functions from a Gist.
# zinit snippet https://gist.githubusercontent.com/hightemp/5071909/raw/

# Enables quick directory jumping based on your usage history.
# just like zoxide, but for zsh
zinit light rupa/z

# Lets you search your history for commands containing a substring, similar to Oh My Zsh.
zinit light zsh-users/zsh-history-substring-search

# Loads useful git aliases and functions from Oh My Zsh's git plugin.
# zinit snippet https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/git/git.plugin.zsh

# Automatically inserts matching brackets, quotes, etc., as you type.
#zinit light hlissner/zsh-autopair

# Enhances tab completion with fzf-powered fuzzy search and a better UI.
zinit light Aloxaf/fzf-tab

# Shows tips for using defined aliases when you type commands, helping you learn and use your aliases.
#zinit light djui/alias-tips

