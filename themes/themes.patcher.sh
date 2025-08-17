#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

print_prompt() {
  while (("$#")); do
    case "$1" in
    -r)
      echo -ne "\e[31m$2\e[0m"
      shift 2
      ;; # Red
    -g)
      echo -ne "\e[32m$2\e[0m"
      shift 2
      ;; # Green
    -y)
      echo -ne "\e[33m$2\e[0m"
      shift 2
      ;; # Yellow
    -b)
      echo -ne "\e[34m$2\e[0m"
      shift 2
      ;; # Blue
    -m)
      echo -ne "\e[35m$2\e[0m"
      shift 2
      ;; # Magenta
    -c)
      echo -ne "\e[36m$2\e[0m"
      shift 2
      ;; # Cyan
    -w)
      echo -ne "\e[37m$2\e[0m"
      shift 2
      ;; # White
    -n)
      echo -ne "\e[96m$2\e[0m"
      shift 2
      ;; # Neon
    *)
      echo -ne "$1"
      shift
      ;;
    esac
  done
  echo ""
}

if [[ $# -eq 0 ]]; then
  exit 1
fi

theme_dir="$1"

wallbash_dir=$HOME/.config/hyde/wallbash
config=$(
  find "${wallbash_dir}" -type f -path "*/theme*" -name "*.dcol" 2>/dev/null |
    awk '!seen[substr($0,match($0,/[^/]+$/))]++' |
    awk -v theme="${theme_dir}" -F 'theme/' '{gsub(/\.dcol$/,".theme");print ".config/hyde/themes/" theme $2}'
)

fav_theme_dir=$HOME/.config/hyde/themes/${theme_dir}
declare -A config_map
while IFS= read -r file_path; do
  file=$(basename "$file_path")
  if [[ -e "${theme_dir}/${file}" ]]; then
    print_prompt -g "[found] " "$file"
    config_map["${file}"]="$HOME/$file_path"
  else
    print_prompt -y "[warn] " "${file_path} do not exist in ${theme_dir}"
  fi
done <<<"${config}"

wallpapers=""
if [ -d "${theme_dir}/wallpapers" ]; then
  wallpapers=$(find "${theme_dir}/wallpapers" -type f \( -iname "*.gif" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \))
  if [ -z "${wallpapers}" ]; then
    print_prompt -r "[error] " "No wallpapers found"
  else
    readonly wallpapers
    wallpaper_count="$(wc -l <<<"${wallpapers}")"
    print_prompt -g "[ok] " "wallpapers count ${wallpaper_count} (.gif .jpg .jpeg .png)"
  fi
fi

logos=""
if [ -d "${theme_dir}/logo" ]; then
  logos=$(find "${theme_dir}/logo" -type f \( -iname "*.gif" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \))
  if [ -z "${logos}" ]; then
    print_prompt -y "[warn] " "No logos found"
  else
    readonly logos
    logo_count="$(wc -l <<<"${logos}")"
    print_prompt -g "[ok] " "logos count ${logo_count}"
  fi
fi

declare -A archive_map=(
  ["Gtk"]="${HOME}/.local/share/themes"
  ["Icon"]="${HOME}/.local/share/icons"
  ["Cursor"]="${HOME}/.local/share/icons"
  ["Sddm"]="/usr/share/sddm/themes"
  ["Font"]="${HOME}/.local/share/fonts"
  ["Document-Font"]="${HOME}/.local/share/fonts"
  ["Monospace-Font"]="${HOME}/.local/share/fonts"
  ["Bar-Font"]="${HOME}/.local/share/fonts"
  ["Menu-Font"]="${HOME}/.local/share/fonts"
  ["Notification-Font"]="${HOME}/.local/share/fonts"
)

for prefix in "${!archive_map[@]}"; do
  tar_file="$(find "${theme_dir}" -type f -name "${prefix}_*.tar.*")"
  [ -f "${tar_file}" ] || continue

  tar_dir="${archive_map[$prefix]}"
  if [ ! -d "${tar_dir}" ]; then
    if ! mkdir -p "${tar_dir}"; then
      print_prompt -y "Creating directory as root instead..."
      sudo mkdir -p "$tar_dir"
    fi
  fi

  tar_check="$(basename "$(tar -tf "${tar_file}" | cut -d '/' -f1 | sort -u)")"
  [ -d "${tar_dir}/${tar_check}" ] && print_prompt -y "[skip]" "\"${tar_dir}/${tar_check}\" already exists"
  if [ -w "${tar_dir}" ]; then
    tar -xf "${tar_file}" -C "${tar_dir}"
  else
    print_prompt -y "Not writable. Extracting as root : ${tar_dir}"
    if ! sudo tar -xf "${tar_file}" -C "${tar_dir}" 2>/dev/null; then
      print_prompt - r "Extraction by root failed."
    fi
  fi
done

config_dir=${XDG_CONFIG_HOME:-"$HOME/.config"}

theme_wall_dir="${config_dir}/hyde/themes/${theme_dir}/wallpapers"
[ ! -d "#{theme_wall_dir}" ] && mkdir -p "${theme_wall_dir}"
while IFS= read -r wallpaper; do
  cp -f "${wallpaper}" "${theme_wall_dir}"
done <<<"${wallpapers}"

theme_logo_dir="${config_dir}/hyde/themes/${theme_dir}/logo"
if [ -n "${logos}" ]; then
  [ ! -d "${theme_logo_dir}" ] && mkdir -p "${theme_logo_dir}"
  while IFS= read -r logo; do
    if [ -f "${logo}" ]; then
      cp -f "${logo}" "${theme_logo_dir}"
    else
      print_prompt -y "[warn]" "${logo} do not exist"
    fi
  done <<<"${logos}"
fi

[ ! -d "${fav_theme_dir}" ] && mkdir -p "${fav_theme_dir}"
for file in "${!config_map[@]}"; do
  if [[ -e "${theme_dir}/${file}" ]]; then
    cp "${theme_dir}/${file}" "${config_map["${file}"]}"
  fi
done
