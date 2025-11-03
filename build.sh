#!/bin/bash
set -e

echo "===== LUMINOS MASTER BUILD SCRIPT (v2.1) ====="
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
SECURITY_COMPONENT="trixie-security" # This is the distribution name for security

lb config \
    --mode debian \
    --architectures amd64 \
    --distribution trixie \
    --archive-areas "main contrib non-free-firmware" \
    --security true \
    --mirror-bootstrap "${DEBIAN_MIRROR}" \
    --mirror-chroot "${DEBIAN_MIRROR}" \
    --mirror-binary "${DEBIAN_MIRROR}" \
    # Corrected line: Space between security component and 'main'
    --mirror-binary-security "http://security.debian.org/debian-security/ ${SECURITY_COMPONENT} main contrib non-free-firmware" \
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
# Create directories for hooks
mkdir -p live-build-config/config/hooks/live
# Copy our scripts into the hooks directory, renaming them for execution order
cp 02-configure-system.sh live-build-config/config/hooks/live/0200_configure-system.hook.chroot
cp 03-install-desktop.sh live-build-config/config/hooks/live/0300_install-desktop.hook.chroot
cp 04-customize-desktop.sh live-build-config/config/hooks/live/0400_customize-desktop.hook.chroot
cp 05-install-ai.sh live-build-config/config/hooks/live/0500_install-ai.hook.chroot
cp 07-install-
