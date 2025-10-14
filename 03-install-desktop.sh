#!/bin/bash

# ==============================================================================
# LuminOS Build Script, Phase 3: Desktop Environment Installation
#
# Description: This script installs the Linux kernel, the bootloader (GRUB, for your information),
#              and the KDE Plasma desktop environment.
#
# Author: Gabriel, Project Leader @ LuminOS
# Version: 0.1.0
# ==============================================================================

# --- Configuration ---
set -e

# --- Variables ---
LUMINOS_CHROOT_DIR="chroot"

# --- Pre-flight Checks ---
if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: This script must be run as root (or with sudo)."
    exit 1
fi
if [ ! -d "$LUMINOS_CHROOT_DIR" ]; then
    echo "ERROR: The chroot directory '$LUMINOS_CHROOT_DIR' does not exist."
    echo "Please run the previous scripts first."
    exit 1
fi

# --- Main Logic ---
echo "====================================================="
echo "PHASE 3: Installing Kernel and Desktop"
echo "====================================================="

# Create the script to be run inside the chroot
cat > "$LUMINOS_CHROOT_DIR/tmp/install_desktop.sh" << "EOF"
#!/bin/bash
set -e

echo "--> Installing Linux kernel and GRUB bootloader..."
# DEBIAN_FRONTEND=noninteractive avoids prompts during installation
export DEBIAN_FRONTEND=noninteractive
apt-get install -y linux-image-amd64 grub-pc

echo "--> Installing KDE Plasma desktop and essential services..."
# We install the standard desktop, Konsole, SDDM (display manager), and Network Manager
apt-get install -y plasma-desktop konsole sddm network-manager

echo "--> Cleaning up APT cache..."
apt-get clean

rm /tmp/install_desktop.sh
EOF

# Make the temporary script executable
chmod +x "$LUMINOS_CHROOT_DIR/tmp/install_desktop.sh"

# Execute the installation script inside the chroot
echo "--> Entering chroot to perform installation..."
chroot "$LUMINOS_CHROOT_DIR" /tmp/install_desktop.sh

echo ""
echo "We're all good: Kernel and desktop environment installed!"
echo "Next step: 04-customize-desktop.sh"

exit 0

