#!/usr/bin/env bash

src_dir="$(dirname "$(realpath "$0")")"
# shellcheck disable=SC1091
if ! source "${src_dir}/utils.sh"; then
    echo "Error: unable to source utils.sh..."
    exit 1
fi

packages="${1}"
arch_pkg=()
aurh_pkg=()

install_packages() {
    local -n pkg_array=$1
    local pkg_type=$2
    local install_cmd=$3

    if [[ ${#pkg_array[@]} -gt 0 ]]; then
        print_log -b "[install] " "$pkg_type packages..."
        for pkg in "${pkg_array[@]}"; do
            print_log -b "[pkg] " "${pkg}"
        done
        $install_cmd ${use_default:+"$use_default"} -S "${pkg_array[@]}" --noconfirm
    fi
}

while read -r pkg deps; do
    # 清除包名中可能存在的空格（处理格式不规范的行）
    pkg="${pkg// /}"
    # 如果包名为空（可能是纯注释行或空行），跳过当前循环
    if [ -z "${pkg}" ]; then
        continue
    fi
    # 如果存在依赖项（deps不为空），则检查依赖是否满足
    if [ -n "${deps}" ]; then
        # 清除依赖字符串末尾的所有空格（处理格式问题）
        deps="${deps%"${deps##*[![:space:]]}"}"
        while read -r cdep; do
            # cut过滤注释，awk匹配第一个字段是否等于cdep，存在则输出1
            pass=$(cut -d '#' -f 1 "${packages}" | awk -F '|' -v chk="${cdep}" '{if($1 == chk) {print 1;exit}}')
            # 如果包列表中没有该依赖，检查系统是否已安装该依赖
            if [ -z "${pass}" ]; then
                if pkg_installed "${cdep}"; then
                    pass=1
                else
                    break
                fi
            fi
        done < <(xargs -n1 <<<"${deps}")

        if [[ ${pass} -ne 1 ]]; then
            print_log -warn "missing" "dependency [ ${deps} ] for ${pkg}..."
            continue
        fi
    fi
    # 处理当前包：检查安装状态和可用来源
    if pkg_installed "${pkg}"; then  
        print_log -y "[skip] " "${pkg}"
    elif pkg_available "${pkg}"; then  # 官方仓库可用：获取所属仓库，记录并加入官方包队列
        repo=$(pacman -Si "${pkg}" | awk -F ': ' '/Repository / {print $2}' | tr '\n' ' ')
        print_log -b "[queue] " "${pkg}" -b " :: " -g "${repo}"
        arch_pkg+=("${pkg}")
    elif aur_available "${pkg}"; then # AUR可用：记录并加入AUR包队列
        print_log -b "[queue] " "${pkg}" -b " :: " -g "aur"
        aurh_pkg+=("${pkg}")
    else
        print_log -r "[error] " "unknown package ${pkg}..."
    fi
done <  <(cut -d '#' -f 1 "${packages}")

echo ""
install_packages arch_pkg "arch" "sudo pacman"
echo ""
install_packages aurh_pkg "aur" "${aurhlpr}"