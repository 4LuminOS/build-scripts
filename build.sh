#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

echo "Starting the LuminOS build process..."
echo "This may take a significant amount of time depending on your system and network speed."

# Define the Debian mirror
DEBIAN_MIRROR="http://deb.debian.org/debian/"
SECURITY_MIRROR="http://security.debian.org/"

# Ensure we are in the 'live-build-config' directory
if [ ! -d "live-build-config" ]; then
    echo "Error: 'live-build-config' directory not found."
    echo "Please run this script from the root of the 'build-scripts' repository."
    exit 1
fi

cd live-build-config

# Start from a clean slate
echo "Cleaning previous build environment..."
lb clean

# Using 'lb config'
echo "Configuring the build environment..."
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
    --apt-options "-o Acquire::IndexTargets::deb::Contents-deb=false -o Acquire::IndexTargets::deb-src::Contents-src=false" \
    --apt-get-options "-y" \
    "${@}"

cd .. # Go back to root of build-scripts

# Run the build
echo "Starting the build... This is the long part."
# This command is relative to the root of the build-scripts directory
# and tells live-build to run inside the 'live-build-config' subdirectory.
lb build --verbose --debug -d live-build-config

echo "-------------------------------------"
echo "Build complete!"
echo "Your ISO file should be in the 'live-build-config' directory."
echo "-------------------------------------"
