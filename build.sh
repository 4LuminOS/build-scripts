#!/bin/bash
set -e

echo "====== LUMINOS MASTER BUILD SCRIPT ======"
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

# Explicitly clean any previous live-build state
echo "--> Forcing clean of live-build environment..."
sudo lb clean --purge

# Configure live-build
echo "--> Running lb config..."
lb config \
    --mode debian \
    --architectures amd64 \
    --distribution trixie \
    --archive-areas "main contrib non-free-firmware" \
    --security true \
    --mirror-bootstrap "http://deb.debian.org/debian/" \
    --mirror-binary "http://deb.debian.org/debian/" \
    --mirror-binary-security "http://security.debian.org/debian-security/" \
    --bootappend-live "boot=live components locales=en_US.UTF-8" \
    --iso-application "LuminOS" \
    --iso-publisher "LuminOS Project" \
    --iso-volume "LuminOS 0.2" \
    --memtest none \
    --debian-installer false \
    "${@}"

# Copy our custom-built system into the live-build chroot overlay
echo "--> Copying the customized LuminOS system into the build environment..."
# Ensure the target directory exists WITHIN the config structure lb expects
mkdir -p config/includes.chroot/
rsync -a ../chroot/ config/includes.chroot/

echo "--> Building the ISO (DEBUG MODE). This will could a significant amount of time..."
# Run build with sudo and debug flags
sudo lb build --debug --verbose

# Move the final ISO to the root of the project directory
# Check if ISO exists before moving
if ls *.iso 1> /dev/null 2>&1; then
    echo "--> Moving ISO to project root..."
    mv *.iso ..
else
    echo "ERROR: ISO file was not found after build!"
    # Optionally: keep build dir for inspection
    # exit 1
fi

cd ..
echo "--> Cleaning up live-build configuration directory..."
sudo rm -rf live-build-config

echo ""
echo "========================================="
# Check again if ISO exists in parent dir
if ls *.iso 1> /dev/null 2>&1; then
    echo "SUCCESS: LuminOS ISO build is complete!"
    echo "Find your image in the main project folder"
else
    echo "ERROR: Build finished but ISO file is missing!"
fi
echo "========================================="
exit 0
