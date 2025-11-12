#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "Starting the LuminOS build process..."
echo "This may take a significant amount of time depending on your system and network speed."

# Define our Debian mirror
DEBIAN_MIRROR="http://deb.debian.org/debian/"
SECURITY_MIRROR="http://security.debian.org/"

# NOTE: We assume this script is already running from
# inside the 'live-build-config' directory.

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

# Run the build
echo "Starting the build... This is the long part."
# We run 'lb build' directly. It will build in the current directory.
lb build --verbose --debug

echo "-------------------------------------"
echo "Build complete!"
echo "Your ISO file should be in this directory."
echo "-------------------------------------"
