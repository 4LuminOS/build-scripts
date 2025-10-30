#!/bin/bash
set -e

echo "====== LUMINOS MASTER BUILD SCRIPT (v2) ======"
if [ "$(id -u)" -ne 0 ]; then echo "ERROR: This script must be run as root. Sorry."; exit 1; fi

# Clean up all previous build artifacts
echo "--> Cleaning up previous build artifacts..."
sudo umount chroot/sys &>/dev/null || true
sudo umount chroot/proc &>/dev/null || true
sudo umount chroot/dev/pts &>/dev/null || true
sudo umount chroot/dev &>/dev/null || true
sudo rm -rf chroot live-build-config *.iso

# Install build dependencies
echo "--> Installing build dependencies (live-build, etc.)..."
apt-get update
apt-get install -y live-build debootstrap debian-archive-keyring plymouth curl rsync

# --- Live-Build Configuration ---
echo "--> Configuring live-build for ISO creation..."
lb config \
    --mode debian \
    --architectures amd64 \
    --distribution trixie \
    --archive-areas "main contrib non-free-firmware" \
    --security true \
    --mirror-bootstrap "http://deb.debian.org/debian/" \
    --mirror-binary "http://deb.debian.org/debian/" \
    --mirror-binary-security "http://security.debian.org/debian-security/ trixie-security/main contrib non-free-firmware" \
    --bootappend-live "boot=live components locales=en_US.UTF-8" \
    --iso-application "LuminOS" \
    --iso-publisher "LuminOS Project" \
    --iso-volume "LuminOS 0.2" \
    --memtest none \
    --debian-installer false \
    "${@}"

# --- Prepare Hooks and Assets ---
echo "--> Preparing build hooks and assets..."
# Create directories for hooks
mkdir -p config/hooks/live
# Copy our scripts into the hooks directory, renaming them for execution order
cp 02-configure-system.sh config/hooks/live/0200_configure-system.hook.chroot
cp 03-install-desktop.sh config/hooks/live/0300_install-desktop.hook.chroot
cp 04-customize-desktop.sh config/hooks/live/0400_customize-desktop.hook.chroot
cp 05-install-ai.sh config/hooks/live/0500_install-ai.hook.chroot
cp 07-install-plymouth-theme.sh config/hooks/live/0700_install-plymouth.hook.chroot
cp 06-final-cleanup.sh config/hooks/live/9999_final-cleanup.hook.chroot

# Create directory for assets and copy them
mkdir -p config/includes.chroot/usr/share/wallpapers/luminos
cp assets/* config/includes.chroot/usr/share/wallpapers/luminos/

echo "--> Building the ISO. This could take a significant amount of time..."
# Run build with sudo
sudo lb build

# Move the final ISO to the root of the project directory
mv live-image-amd64.iso LuminOS-0.2-amd64.iso

echo "--> Cleaning up live-build configuration directory..."
sudo rm -rf config chroot cache binary .build

echo ""
echo "========================================="
echo "SUCCESS: LuminOS ISO build is complete!"
echo "Find your image at: LuminOS-0.2-amd64.iso"
echo "========================================="
exit 0
