#!/bin/bash
set -e

echo "===== LUMINOS MASTER BUILD SCRIPT ====="
if [ "$(id -u)" -ne 0 ]; then echo "ERROR: This script must be run as root."; exit 1; fi

# Clean up previous build attempts first
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

# Run build phases in logical order
./01-build-base-system.sh
./02-configure-system.sh
./03-install-desktop.sh
./04-customize-desktop.sh
./05-install-ai.sh
./07-install-plymouth-theme.sh
./06-final-cleanup.sh # Final cleanup must be last before packaging


# --- ISO Building ---
echo "--> Configuring live-build for ISO creation..."
mkdir -p live-build-config
cd live-build-config

# Explicitly set Debian mirrors and force Debian mode
DEBIAN_MIRROR="http://deb.debian.org/debian/"
SECURITY_COMPONENT="trixie-security"

lb config \
    --mode debian \
    --architectures amd64 \
    --distribution trixie \
    --archive-areas "main contrib non-free-firmware" \
    --security true \
    --mirror-bootstrap "${DEBIAN_MIRROR}" \
    --mirror-chroot "${DEBIAN_MIRROR}" \
    --mirror-binary "${DEBIAN_MIRROR}" \
    --mirror-binary-security "http://security.debian.org/debian-security/ ${SECURITY_COMPONENT}/main contrib non-free-firmware" \ # Corrected security mirror path with components
    --bootappend-live "boot=live components locales=en_US.UTF-8" \
    --iso-application "LuminOS" \
    --iso-publisher "LuminOS Project" \
    --iso-volume "LuminOS 0.2" \
    --memtest none \
    --debian-installer false \
    "${@}"

# Copy our custom-built system into the live-build chroot overlay
echo "--> Copying the customized LuminOS system into the build environment..."
mkdir -p config/includes.chroot/
rsync -a ../chroot/ config/includes.chroot/

echo "--> Building the ISO. This could take a significant amount of time..."
# Run build with sudo
sudo lb build

# Move the final ISO to the root of the project directory
mv *.iso ..

cd ..
echo "--> Cleaning up live-build configuration directory..."
sudo rm -rf live-build-config

echo ""
echo "========================================="
echo "SUCCESS: LuminOS ISO build is complete!"
echo "Find your image in the main project folder"
echo "========================================="
exit 0
