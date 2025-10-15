#!/bin/bash
set -e

echo "===== LUMINOS MASTER BUILD SCRIPT ====="
if [ "$(id -u)" -ne 0 ]; then echo "ERROR: This script must be run as root."; exit 1; fi

# Install build dependencies
echo "--> Installing build dependencies (live-build, debootstrap)..."
apt-get update
apt-get install -y live-build debootstrap debian-archive-keyring

# Run build phases
./01-build-base-system.sh
./02-configure-system.sh
./03-install-desktop.sh
./04-customize-desktop.sh
./05-install-ai.sh
./06-final-cleanup.sh

# Mount virtual filesystems for the final phases that need it
mount --bind /dev "chroot/dev"; mount --bind /dev/pts "chroot/dev/pts"; mount -t proc /proc "chroot/proc"; mount -t sysfs /sys "chroot/sys"
./07-install-plymouth-theme.sh
# Unmount everything cleanly at the end
umount "chroot/sys"; umount "chroot/proc"; umount "chroot/dev/pts"; umount "chroot/dev"

# --- ISO Building ---
echo "--> Configuring live-build for ISO creation..."
# Create a temporary directory for live-build
mkdir -p live-build-config
cd live-build-config

lb config noauto \
    --architectures amd64 \
    --distribution trixie \
    --archive-areas "main contrib non-free-firmware" \
    --bootappend-live "boot=live components locales=en_US.UTF-8" \
    --iso-application "LuminOS" \
    --iso-publisher "LuminOS Project" \
    --iso-volume "LuminOS 0.2" \
    --memtest none \
    --debian-installer false

# Copy our custom-built system into the live-build chroot
echo "--> Copying the customized LuminOS system into the build environment..."
sudo cp -a ../chroot/* config/includes.chroot/

echo "--> Building the ISO. This will take a significant amount of time..."
sudo lb build

# Move the final ISO to the root of the project directory
mv *.iso ..

cd ..
sudo rm -rf live-build-config

echo ""
echo "========================================="
echo "SUCCESS: LuminOS ISO build is complete!!!"
echo "Find your image in the main project folder."
echo "========================================="
exit 0
