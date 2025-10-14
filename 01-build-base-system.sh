#!/bin/bash

# ==============================================================================
# LuminOS Build Script, Phase 1: Base System
#
# Description: This script creates a minimal Debian "Trixie" base system
#              using debootstrap.
#
# Author: Gabriel, Project Leader @ LuminOS
# Version: 0.1.2
# ==============================================================================

# --- Configuration ---
# Stop script on any error
set -e

# --- Variables ---
LUMINOS_CHROOT_DIR="chroot"
LUMINOS_DISTRIBUTION="trixie" # Debian 13
LUMINOS_ARCH="amd64"
# neofetch has been removed from this list to keep the base minimal
LUMINOS_PACKAGES="build-essential,git,curl,wget,ssh,htop,unzip,p7zip-full,neovim"

# --- Script Logic ---
if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: This script must be run as root (or with sudo)."
    exit 1
fi
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
debootstrap --arch=$LUMINOS_ARCH --include=$LUMINOS_PACKAGES $LUMINOS_DISTRIBUTION $LUMINOS_CHROOT_DIR http://deb.debian.org/debian
echo ""
echo "SUCCESS: LuminOS base system created in '$LUMINOS_CHROOT_DIR'."
echo "Next step: 02-configure-system.sh"
exit 0
