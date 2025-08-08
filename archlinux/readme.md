# 系统配置 install.sys

# hyde 安装分析

前置：

处理 grub 显卡、grub主题
处理 systemd-boot 显卡相关处理
处理 pacman Color multilib ParallelDownloads Chaotic AUR

准备包列表：
添加用户自定义包

针对nvidia显卡需要的包做了处理（内核头文件和驱动）
自动收集系统中已安装的所有内核对应的内核头文件包名
```
cat /usr/lib/modules/*/pkgbase | while read -r kernel; do
  echo "${kernel}-headers" >>"${scrDir}/install_pkg.lst"
done
nvidia_detect --drivers >>"${scrDir}/install_pkg.lst"
```
设置了 
myaur 
myshell 应该存在于包列表


安装包
调用 install_aur.sh

if pkg_installed git; then
    git clone "https://aur.archlinux.org/${aurhlpr}.git" "$HOME/Clone/${aurhlpr}"
else
    print_log -sec "AUR" -stat "missing" "'git' as dependency..."
    exit 1
fi

cd "$HOME/Clone/${aurhlpr}" || exit
# shellcheck disable=SC2154
if makepkg "${use_default}" -si; then
    print_log -sec "AUR" -stat "installed" "${aurhlpr} aur helper..."
    exit 0
else
    print_log -r "AUR" -stat "failed" "${aurhlpr} installation failed..."
    echo "${aurhlpr} installation failed..."
    exit 1
fi


    if [ "${flg_DryRun}" -ne 1 ] && [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
        hyprctl keyword misc:disable_autoreload 1 -q
    fi

#字体和主题
