#!/bin/bash
set -e

echo "===== LUMINOS MASTER BUILD SCRIPT ====="
if [ "$(id -u)" -ne 0 ]; then echo "ERROR: This script must be run as root."; exit 1; fi

# Install build dependencies
echo "--> Installing build dependencies (live-build, etc.)..."
apt-get update
apt-get install -y live-build debootstrap debian-archive-keyring plymouth

# Run build phases in logical order
./01-build-base-system.sh
./02-configure-system.sh
./03-install-desktop.sh
./04-customize-desktop.sh
./05-install-ai.sh
# Plymouth theme must be installed before cleanup
./07-install-plymouth-theme.sh
# Final cleanup is the last step before packaging
./06-final-cleanup.sh

# --- ISO Building ---
echo "--> Configuring live-build for ISO creation..."
# Create a temporary directory for live-build
mkdir -p live-build-config
cd live-build-config

# lb config is deprecated, using lb config noauto is the modern way
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
echo "SUCCESS: LuminOS ISO build is complete!"
echo "Find your image in the main project folder."
echo "========================================="
exit 0
