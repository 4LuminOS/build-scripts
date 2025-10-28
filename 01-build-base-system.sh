#!/bin/bash
# ==============================================================================
# LuminOS Build Script, Phase 1: Base System
# Author: Gabriel, Project Leader @ LuminOS
# Version: 0.1.5
# ==============================================================================
set -e
LUMINOS_CHROOT_DIR="chroot"
LUMINOS_DISTRIBUTION="trixie"
LUMINOS_ARCH="amd64"
LUMINOS_COMPONENTS="main,contrib,non-free-firmware"
# Added apt-transport-https and ca-certificates for robust apt function
LUMINOS_PACKAGES="build-essential,git,curl,wget,ssh,htop,unzip,p7zip-full,neovim,locales,apt-transport-https,ca-certificates"

if [ "$(id -u)" -ne 0 ]; then echo "ERROR: Must run as root."; exit 1; fi
if ! command -v debootstrap &> /dev/null; then
    echo "INFO: debootstrap is not installed. Installing now..."
    apt-get update
    apt-get install -y debootstrap
fi
if [ -d "$LUMINOS_CHROOT_DIR" ]; then
    echo "INFO: Removing previous build directory: $LUMINOS_CHROOT_DIR"
    rm -rf "$LUMINOS_CHROOT_DIR"
fi
echo "====================================================="
echo "PHASE 1: Creating LuminOS Base System"
echo "====================================================="
debootstrap --arch=$LUMINOS_ARCH --include=$LUMINOS_PACKAGES --components=$LUMINOS_COMPONENTS $LUMINOS_DISTRIBUTION $LUMINOS_CHROOT_DIR http://deb.debian.org/debian

echo ""
echo "SUCCESS: LuminOS base system created in '$LUMINOS_CHROOT_DIR'."
echo "Next step: 02-configure-system.sh"
exit 0
