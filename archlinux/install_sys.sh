#!/bin/bash
set -euo pipefail

# ==================== Configuration Parameters (Modify as needed) ====================
DISK="/dev/sda"                  # Target disk (double-check this!)
SWAP_SIZE="1G"                   # Swap partition size
BOOT_SIZE="512M"                 # EFI boot partition size
HOSTNAME="arch-linux"            # System hostname
TIMEZONE="Asia/Shanghai"         # Timezone (e.g. America/New_York)
# System locale
LOCALES=(
  "en_US.UTF-8"
  "zh_CN.UTF-8"
  "zh_TW.UTF-8"
)
DEFAULT_LOCALE="en_US.UTF-8"                                 
ROOT_PASSWORD="1"                # Root user password
USER_NAME="selene"               # Regular username
USER_PASSWORD="1"                # Regular user password
# Chinese mirror sources (priority from high to low)
MIRRORS=(
  "https://mirrors.tuna.tsinghua.edu.cn/archlinux/\$repo/os/\$arch"
  "https://mirrors.ustc.edu.cn/archlinux/\$repo/os/\$arch"
  "https://mirror.sjtu.edu.cn/archlinux/\$repo/os/\$arch"
  "https://mirrors.cqu.edu.cn/archlinux/\$repo/os/\$arch"
)
# ====================================================================================

# Warning message
echo "============================================="
echo "WARNING: This script will erase all data on ${DISK} and automatically install Arch Linux"
echo "Starting in 3 seconds (press Ctrl+C to abort)..."
echo "============================================="
sleep 3
# ----------------------------
# 0. Configure Chinese mirrors (execute before installation)
# ----------------------------
echo "=== Configuring Chinese mirror sources ==="

systemctl stop reflector.service 
# Backup original mirror list
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak

# Clear existing mirror list
> /etc/pacman.d/mirrorlist

# Add Chinese sources to mirror list (use first)
for mirror in "${MIRRORS[@]}"; do
  echo "Server = $mirror" >> /etc/pacman.d/mirrorlist
  echo "Added mirror source: $mirror"
done

# Add default official sources (as fallback)
echo "Server = https://archive.archlinux.org/repos/\$repo/os/\$arch" >> /etc/pacman.d/mirrorlist

# Update source cache
pacman -Syy &>/dev/null
echo "Chinese mirror sources configured successfully"

# ----------------------------
# 1. Disk Partitioning & Formatting
# ----------------------------

# Check if required variables are defined
if [[ -z "${DISK}" || -z "${SWAP_SIZE}" || -z "${BOOT_SIZE}" ]]; then
    echo "Error: Please define DISK, SWAP_SIZE, and BOOT_SIZE variables"
    exit 1
fi

# Check if disk device exists
if [[ ! -b "${DISK}" ]]; then
    echo "Error: Disk device ${DISK} does not exist"
    exit 1
fi

# Warning message (no confirmation prompt)
echo "WARNING: All data on disk ${DISK} will be erased automatically!"

# Clear existing partition table
parted "${DISK}" -s mklabel gpt

# 统一转换为字节（1024进制），确保单位体系一致
SWAP_SIZE_BYTES=$(numfmt --from=iec "${SWAP_SIZE}")
BOOT_SIZE_BYTES=$(numfmt --from=iec "${BOOT_SIZE}")

# 转换为MiB（1024进制），保留单位字符串用于parted
SWAP_SIZE_MIB_STR=$(numfmt --from=iec --to=iec --suffix=MiB "${SWAP_SIZE_BYTES}")
BOOT_SIZE_MIB_STR=$(numfmt --from=iec --to=iec --suffix=MiB "${BOOT_SIZE_BYTES}")

# 计算分区位置（全部使用1024进制MiB，确保连续无间隙）
# 分区1结束位置 = 1MiB + SWAP_SIZE_MIB（与分区2起始位置严格对齐）
BOOT_START="${SWAP_SIZE_MIB_STR}"
# 分区2结束位置 = 分区1结束位置 + BOOT_SIZE_MIB
BOOT_END=$(numfmt --from=iec --to=iec --suffix=MiB $((SWAP_SIZE_BYTES + BOOT_SIZE_BYTES)))

# Partition 1: Swap partition
parted "${DISK}" -s -a optimal mkpart primary linux-swap 1MiB "${SWAP_SIZE}"
# Partition 2: EFI boot partition
parted "${DISK}" -s -a optimal mkpart primary fat32 "${BOOT_START}" "${BOOT_END}"
# Partition 3: Btrfs root partition (remaining space)
parted "${DISK}" -s -a optimal mkpart primary btrfs "${BOOT_END}" 100%

# Mark EFI partition as bootable
parted "${DISK}" -s set 2 esp on

# Define partition paths
SWAP_PART="${DISK}1"
BOOT_PART="${DISK}2"
ROOT_PART="${DISK}3"

# Format partitions
mkswap -L SWAP "${SWAP_PART}" &>/dev/null
mkfs.fat -F32 -n EFI "${BOOT_PART}" &>/dev/null
mkfs.btrfs -L ROOT -f "${ROOT_PART}" &>/dev/null

# ----------------------------
# 2. Btrfs Subvolume Configuration & Mounting
# ----------------------------
echo "=== Configuring Btrfs subvolumes ==="

# Temporarily mount root partition
mount "${ROOT_PART}" /mnt

# Create subvolumes
btrfs subvolume create /mnt/@ &>/dev/null
btrfs subvolume create /mnt/@home &>/dev/null
btrfs subvolume create /mnt/@var &>/dev/null
btrfs subvolume create /mnt/@tmp &>/dev/null
btrfs subvolume create /mnt/@snapshots &>/dev/null

# Unmount temporary mount
umount /mnt

# Remount subvolumes with optimized parameters
mount -o noatime,compress=zstd,space_cache=v2,subvol=@ "${ROOT_PART}" /mnt

# Create mount points
mkdir -p /mnt/{home,var,tmp,.snapshots,boot}

# Mount other subvolumes
mount -o noatime,compress=zstd,space_cache=v2,subvol=@home "${ROOT_PART}" /mnt/home
mount -o noatime,compress=zstd,space_cache=v2,subvol=@var "${ROOT_PART}" /mnt/var
mount -o noatime,compress=zstd,space_cache=v2,subvol=@tmp "${ROOT_PART}" /mnt/tmp
mount -o noatime,compress=zstd,space_cache=v2,subvol=@snapshots "${ROOT_PART}" /mnt/.snapshots

# Mount EFI partition and activate swap
mount "${BOOT_PART}" /mnt/boot
swapon "${SWAP_PART}"

# ----------------------------
# 3. Install Base System
# ----------------------------
echo "=== Installing system components ==="

# Install base system packages (add/remove as needed)
pacstrap -K /mnt \
  base base-devel linux linux-firmware \
  btrfs-progs \
  grub efibootmgr os-prober\
  networkmanager \
  vim sudo zsh \
  git \

# ----------------------------
# 4. Basic System Configuration
# ----------------------------
echo "=== Configuring system ==="

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Configure Chinese mirrors for the new system

echo "=== Configuring Chinese mirrors for new system ==="
mkdir -p /mnt/etc/pacman.d
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist

# Chroot into new system to execute configuration
arch-chroot /mnt /bin/bash -euo pipefail <<EOF
  # Set timezone
  ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
  hwclock --systohc
  
  # Configure localization (add multiple languages via loop)
  LOCALES_STR=(${LOCALES})
  for locale in "${LOCALES_STR[@]}"; do
    sed -i "s/^#${locale} UTF-8/${locale} UTF-8/" /etc/locale.gen
  done
  locale-gen 
  echo "LANG=${DEFAULT_LOCALE}" > /etc/locale.conf

  # Set hostname
  echo "${HOSTNAME}" > /etc/hostname
  echo "127.0.0.1 localhost" >> /etc/hosts
  echo "::1       localhost" >> /etc/hosts
  echo "127.0.1.1 ${HOSTNAME}.localdomain ${HOSTNAME}" >> /etc/hosts

  # Set root password
  echo "root:${ROOT_PASSWORD}" | chpasswd

  # Create regular user and add to sudo group
  useradd -m -G wheel -s /bin/zsh ${USER_NAME} 
  echo "${USER_NAME}:${USER_PASSWORD}" | chpasswd 
  echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers

  # Install bootloader (GRUB)
  sed -i 's/^#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub
  grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=ArchLinux
  grub-mkconfig -o /boot/grub/grub.cfg 

  # Enable necessary services
  systemctl enable NetworkManager
EOF
# ----------------------------
# 5. Cleanup and completion
# ----------------------------
echo "=== Installation completed ==="

# Unmount partitions
umount -R /mnt
swapoff "${SWAP_PART}"
echo "Arch Linux has been successfully installed to ${DISK}"
echo "Chinese mirror sources used:"
for mirror in "${MIRRORS[@]}"; do
  echo "  - $mirror"
done
echo "You can log in with these credentials after reboot:"
echo "  - root: ${ROOT_PASSWORD}"
echo "  - ${USER_NAME}: ${USER_PASSWORD}"
echo "It's recommended to remove installation media before rebooting"
