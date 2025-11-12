#!/bin/bash
set -e

echo "Starting the LuminOS build process..."
echo "This may take a significant time depending on your system and network speed."
echo ""

# Define base directory relative to the script location
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
BASE_DIR=$(realpath "$SCRIPT_DIR/..")
LB_CONFIG_DIR="$SCRIPT_DIR"

# Ensure we are in the base directory
cd "$BASE_DIR"

# --- 1. Clean previous build environment ---
echo "Cleaning previous build environment..."
# We must be in the base dir to run lb clean
cd "$LB_CONFIG_DIR"
lb clean
cd "$BASE_DIR"

echo "P: Cleaning chroot"
# The 'lb clean' command might not remove everything, especially on failure.
# We'll manually clean the chroot and binary directories just in case.
sudo rm -rf "$BASE_DIR/chroot"
sudo rm -rf "$BASE_DIR/binary"
# Recreate directories for subsequent steps
mkdir -p "$BASE_DIR/chroot"
mkdir -p "$BASE_DIR/binary"


# --- 2. Configure the build environment ---
echo "Configuring the build environment..."
cd "$LB_CONFIG_DIR"

# Define Mirrors
DEBIAN_MIRROR="http://deb.debian.org/debian/"
SECURITY_MIRROR="http://security.debian.org/ trixie-security main contrib non-free-firmware"

# Run lb config
# Note: --apt-options requires a single string argument.
# We pass --yes (or -y) to apt to auto-confirm,
# and disable Contents-deb/Contents-src to speed up updates.
lb_config \
    -mode debian \
    --architectures amd64 \
    --distribution trixie \
    --archive-areas "main contrib non-free-firmware" \
    --security false \
    --mirror-bootstrap "$DEBIAN_MIRROR" \
    --mirror-chroot "$DEBIAN_MIRROR | $SECURITY_MIRROR" \
    --mirror-binary "$DEBIAN_MIRROR | $SECURITY_MIRROR" \
    --bootappend-live "boot=live components locales=en_US.UTF-8" \
    --iso-application "LuminOS Project" \
    --iso-publisher "LuminOS Project" \
    --iso-volume "LuminOS 0.2" \
    --memtest none \
    --debian-installer false \
    --apt-options '--yes -o "Acquire::IndexTargets::deb::Contents-deb=false" -o "Acquire::IndexTargets::deb::src::Contents-src=false"'


# --- 3. Run the build ---
echo "Running the build (lb build)..."
# We run build from inside the config dir
sudo lb build --verbose --debug

cd "$BASE_DIR"

# --- 4. Post-build cleanup or artifact handling (if any) ---
echo "Build process finished."
echo "ISO image should be located in the main project directory."

exit 0
