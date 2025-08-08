#!/usr/bin/env zsh
export CONFIG_HOME="${CONFIG_HOME:-$HOME/.config}"
export ZDOTDIR="${ZDOTDIR:-$CONFIG_HOME/zsh}"

# 检测操作系统类型
OS_TYPE=$(uname)
case "$OS_TYPE" in
    Linux)
        [[ -f $ZDOTDIR/linux/linux.zsh ]] && source $ZDOTDIR/linux/linux.zsh
        ;;
    Darwin)
        [[ -f $ZDOTDIR/mac/mac.zsh ]] && source $ZDOTDIR/mac/mac.zsh
        ;;
    CYGWIN*|MINGW32*|MSYS*|MINGW*) # 可能有问题
        [[ -f $ZDOTDIR/win/wsl.zsh ]] && source $ZDOTDIR/win/wsl.zsh
        ;;
    *)
        echo "Unknown OS type: $OS_TYPE"
        ;;
esac