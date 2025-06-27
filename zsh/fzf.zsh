# Setup fzf
# ---------
if [[ ! "$PATH" == */home/renatus/.fzf/bin* ]]; then
  PATH="${PATH:+${PATH}:}/home/renatus/.fzf/bin"
fi

source <(fzf --zsh)
