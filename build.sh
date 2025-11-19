#!/bin/bash
set -e

echo "====== LUMINOS MASTER BUILD SCRIPT (v5.0 - Manual) ======"
if [ "$(id -u)" -ne 0 ]; then echo "ERROR: This script must be run as root."; exit 1; fi

# --- 1. Define Directories & Vars ---
BASE_DIR=$(dirname "$(readlink -f "$0")")
WORK_DIR="${BASE_DIR}/work"
CHROOT_DIR="${WORK_DIR}/chroot"
ISO_DIR="${WORK_DIR}/iso"
ISO_NAME="LuminOS-0.2-amd64.iso"

# --- 2. Clean Up ---
echo "--> Cleaning up previous build artifacts..."
sudo umount "${CHROOT_DIR}/sys" &>/dev/null || true
sudo umount "${CHROOT_DIR}/proc" &>/dev/null || true
sudo umount "${CHROOT_DIR}/dev/pts" &>/dev/null || true
sudo umount "${CHROOT_DIR}/dev" &>/dev/null || true
sudo rm -rf "${WORK_DIR}"
sudo rm -f "${BASE_DIR}/${ISO_NAME}"

mkdir -p "${CHROOT_DIR}"
mkdir -p "${ISO_DIR}/live"
mkdir -p "${ISO_DIR}/boot/grub"

# --- 3. Install Dependencies ---
echo "--> Installing build dependencies..."
# Added squashfs-tools, xorriso, grub components for manual ISO creation
apt-get update
apt-get install -y debootstrap squashfs-tools xorriso grub-pc-bin grub-efi-amd64-bin mtools curl rsync

# --- 4. Bootstrap Base System ---
echo "--> Bootstrapping Debian base (this takes time)..."
# We construct the base manually. No live-build magic here.
debootstrap \
    --arch=amd64 \
    --components=main,contrib,non-free-firmware \
    --include=linux-image-amd64,live-boot,systemd-sysv \
    trixie \
    "${CHROOT_DIR}" \
    http://ftp.debian.org/debian/

# --- 5. Apply Fixes & Prepare Environment ---
echo "--> Applying APT fixes..."
mkdir -p "${CHROOT_DIR}/etc/apt/apt.conf.d"
cat > "${CHROOT_DIR}/etc/apt/apt.conf.d/99-no-contents" << EOF
Acquire::IndexTargets::deb::Contents-deb "false";
Acquire::IndexTargets::deb-src::Contents-src "false";
EOF

# Mount bind points for customization
echo "--> Mounting virtual filesystems..."
mount --bind /dev "${CHROOT_DIR}/dev"
mount --bind /dev/pts "${CHROOT_DIR}/dev/pts"
mount -t proc /proc "${CHROOT_DIR}/proc"
mount -t sysfs /sys "${CHROOT_DIR}/sys"

# Prepare Assets
echo "--> Copying assets..."
mkdir -p "${CHROOT_DIR}/usr/share/wallpapers/luminos"
cp "${BASE_DIR}/assets/"* "${CHROOT_DIR}/usr/share/wallpapers/luminos/"

# --- 6. Run Customization Scripts ---
echo "--> Running customization scripts..."

# Copy scripts into chroot
cp "${BASE_DIR}/02-configure-system.sh" "${CHROOT_DIR}/tmp/"
cp "${BASE_DIR}/03-install-desktop.sh" "${CHROOT_DIR}/tmp/"
cp "${BASE_DIR}/04-customize-desktop.sh" "${CHROOT_DIR}/tmp/"
cp "${BASE_DIR}/05-install-ai.sh" "${CHROOT_DIR}/tmp/"
cp "${BASE_DIR}/07-install-plymouth-theme.sh" "${CHROOT_DIR}/tmp/"
cp "${BASE_DIR}/06-final-cleanup.sh" "${CHROOT_DIR}/tmp/"

# Execute them in order
# We use chroot commands directly here.
chmod +x "${CHROOT_DIR}/tmp/"*.sh

echo ":: Running 02-configure-system.sh"
chroot "${CHROOT_DIR}" /tmp/02-configure-system.sh
echo ":: Running 03-install-desktop.sh"
chroot "${CHROOT_DIR}" /tmp/03-install-desktop.sh
echo ":: Running 04-customize-desktop.sh"
chroot "${CHROOT_DIR}" /tmp/04-customize-desktop.sh
echo ":: Running 05-install-ai.sh"
chroot "${CHROOT_DIR}" /tmp/05-install-ai.sh
echo ":: Running 07-install-plymouth-theme.sh"
chroot "${CHROOT_DIR}" /tmp/07-install-plymouth-theme.sh
echo ":: Running 06-final-cleanup.sh"
chroot "${CHROOT_DIR}" /tmp/06-final-cleanup.sh

# Unmount
echo "--> Unmounting..."
umount "${CHROOT_DIR}/sys"
umount "${CHROOT_DIR}/proc"
umount "${CHROOT_DIR}/dev/pts"
umount "${CHROOT_DIR}/dev"

# --- 7. Build the ISO ---
echo "--> Compressing filesystem (SquashFS)..."
# This creates the big read-only file for the ISO
mksquashfs "${CHROOT_DIR}" "${ISO_DIR}/live/filesystem.squashfs" -e boot

echo "--> Preparing Bootloader (GRUB)..."
# Copy kernel and initrd from chroot to ISO boot folder
cp "${CHROOT_DIR}/boot"/vmlinuz* "${ISO_DIR}/live/vmlinuz"
cp "${CHROOT_DIR}/boot"/initrd.img* "${ISO_DIR}/live/initrd.img"

# Create GRUB config
cat > "${ISO_DIR}/boot/grub/grub.cfg" << EOF
set default="0"
set timeout=5

menuentry "LuminOS v0.2 Live" {
    linux /live/vmlinuz boot=live quiet splash
    initrd /live/initrd.img
}
EOF

echo "--> Generating your ISO image..."
# Use grub-mkrescue to create a hybrid (BIOS/UEFI) ISO
grub-mkrescue -o "${BASE_DIR}/${ISO_NAME}" "${ISO_DIR}"

echo "--> Cleaning up work directory..."
# sudo rm -rf "${WORK_DIR}" # Optional: keep for debugging if needed

echo ""
echo "========================================="
echo "SUCCESS: LuminOS ISO build is complete!"
echo "Find your image at: ${BASE_DIR}/${ISO_NAME}"
echo "========================================="
exit 0
