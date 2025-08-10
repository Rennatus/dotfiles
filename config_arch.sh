#!/bin/bash

src_dir="$(dirname "$(realpath "$0")")"
# shellcheck disable=SC1091
if ! source "${src_dir}/utils.sh"; then
    echo "Error: unable to source utils.sh..."
    exit 1
fi
aur_helper="yay"

# pacman
if [ -f /etc/pacman.conf ];then
    print_log -g "[PACMAN] " -b "modify :: " "adding extra spice to pacman..."
    sudo sed -i "/^#Color/c\Color\nILoveCandy
    /^#VerbosePkgLists/c\VerbosePkgLists
    /^#ParallelDownloads/c\ParallelDownloads = 5" /etc/pacman.conf
    sudo sed -i '/^#\[multilib\]/,+1 s/^#//' /etc/pacman.conf

    if grep -q '\[archlinuxcn\]' /etc/pacman.conf; then
        print_log -sec "Archlinuxcn" -stat "skipped" "Archlinuxcn AUR entry found in pacman.conf..."
    else
        echo -e "\n[archlinuxcn]\nServer = https://mirrors.ustc.edu.cn/archlinuxcn/\$arch" | sudo tee -a /etc/pacman.conf
        sudo pacman -Sy archlinuxcn-keyring --noconfirm
    fi

    print_log -g "[PACMAN] " -b "update :: " "packages..."
    sudo pacman -Syyu --noconfirm
    sudo pacman -Fy --noconfirm
fi

# aur
if pkg_installed "${aur_helper}";then
    print_log -sec "AUR" -stat "skipped" "${aur_helper} aready installed"
else
    if [ -d "$HOME/clone" ]; then
        print_log -sec "AUR" -stat "exist" "$HOME/clone directory..."
        rm -rf "$HOME/clone/${aur_helper}"
    else
        mkdir "$HOME/clone"
        echo -e "[Desktop Entry]\nIcon=default-folder-git" >"$HOME/clone/.directory"
        print_log -sec "AUR" -stat "created" "$HOME/clone directory..."
    fi

    if pkg_installed git; then
        git clone "https://aur.archlinux.org/${aur_helper}.git" "$HOME/clone/${aur_helper}"
    else
        print_log -sec "AUR" -stat "missing" "'git' as dependency..."
        exit 1
    fi

    cd "$HOME/clone/${aur_helper}" || exit
    if makepkg "${use_default}" -si; then
        print_log -sec "AUR" -stat "installed" "${aur_helper} aur helper..."
    else
        print_log -r "AUR" -stat "failed" "${aur_helper} installation failed..."
        echo "${aur_helper} installation failed..."
        exit 1
    fi
fi

# install package
print_log -g "[Install]" -b " :: " "install packages..."
"${src_dir}/install_pkg.sh" "${src_dir}/pkglist/pkg_core.lst"



