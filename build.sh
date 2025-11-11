#!/bin/bash
set -e

echo "===== LUMINOS MASTER BUILD SCRIPT (v3.2) ====="
if [ "$(id -u)" -ne 0 ]; then echo "ERROR: This script must be run as root."; exit 1; fi

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
mkdir -p live-build-config
cd live-build-config

DEBIAN_MIRROR="http://deb.debian.org/debian/"
SECURITY_MIRROR="http://security.debian.org/debian-security/"

# Using 'lb config'
lb config \
    --mode debian \
    --architectures amd64 \
    --distribution trixie \
    --archive-areas "main contrib non-free-firmware" \
    --security false \
    --mirror-bootstrap "${DEBIAN_MIRROR}" \
    --mirror-chroot "${DEBIAN_MIRROR} | ${SECURITY_MIRROR} trixie-security main contrib non-free-firmware" \
    --mirror-binary "${DEBIAN_MIRROR} | ${SECURITY_MIRROR} trixie-security main contrib non-free-firmware" \
    --bootappend-live "boot=live components locales=en_US.UTF-8" \
    --iso-application "LuminOS" \
    --iso-publisher "LuminOS Project" \
    --iso-volume "LuminOS 0.2" \
    --memtest none \
    --debian-installer false \
    "${@}"

cd .. # Go back to root of build-scripts

# --- Prepare Hooks and Assets ---
echo "--> Preparing build hooks and assets..."
# THIS IS THE CORRECT DIRECTORY FOR SCRIPTS RUN DURING THE BUILD
mkdir -p live-build-config/config/hooks/chroot/

# Copy all our customization scripts into the chroot hook directory
cp 00-pre-install-fixes.sh live-build-config/config/hooks/chroot/0001_no-contents.hook.chroot
cp 02-configure-system.sh live-build-config/config/hooks/chroot/0200_configure-system.hook.chroot
cp 03-install-desktop.sh live-build-config/config/hooks/chroot/0300_install-desktop.hook.chroot
cp 04-customize-desktop.sh live-build-config/config/hooks/chroot/0400_customize-desktop.hook.chroot
cp 05-install-ai.sh live-build-config/config/hooks/chroot/0500_install-ai.hook.chroot
cp 07-install-plymouth-theme.sh live-build-config/config/hooks/chroot/0700_install-plymouth.hook.chroot
cp 06-final-cleanup.sh live-build-config/config/hooks/chroot/9999_final-cleanup.hook.chroot

# This directory is for files to be COPIED into the finished OS
mkdir -p live-build-config/config/includes.chroot/usr/share/wallpapers/luminos
cp assets/* live-build-config/config/includes.chroot/usr/share/wallpapers/luminos/

echo "--> Building the ISO. This will take a significant amount of time..."
cd live-build-config
sudo lb build
cd .. # Go back to root of build-scripts

mv live-build-config/live-image-amd64.iso LuminOS-0.2-amd64.iso

echo "--> Cleaning up live-build configuration directory..."
sudo rm -rf live-build-config

echo ""
echo "========================================="
echo "SUCCESS: LuminOS ISO build is complete!"
echo "Find your image at: LuminOS-0.2-amd64.iso"
echo "========================================="
exit 0
