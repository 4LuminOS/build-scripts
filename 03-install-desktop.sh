#!/bin/bash

# ==============================================================================
# LuminOS Build Script, Phase 3: Desktop Environment Installation
#
# Description: This script installs the Linux kernel, a bootloader (GRUB),
#              and the KDE Plasma desktop environment with its core applications.
#
# Author: Gabriel, Project Leader @ LuminOS
# Version: 0.1.2
# ==============================================================================

set -e
LUMINOS_CHROOT_DIR="chroot"

if [ "$(id -u)" -ne 0 ]; then echo "ERROR: This script must be run as root (or with sudo)."; exit 1; fi
if [ ! -d "$LUMINOS_CHROOT_DIR" ]; then echo "ERROR: The chroot directory '$LUMINOS_CHROOT_DIR' does not exist."; exit 1; fi

echo "====================================================="
echo "PHASE 3: Installing Kernel and Desktop"
echo "====================================================="

cat > "$LUMINOS_CHROOT_DIR/tmp/install_desktop.sh" << "EOF"
#!/bin/bash
set -e
echo "--> Installing Linux kernel and GRUB bootloader..."
export DEBIAN_FRONTEND=noninteractive
apt-get install -y linux-image-amd64 grub-pc
echo "--> Installing KDE Plasma desktop and essential services..."
DESKTOP_PACKAGES="plasma-desktop konsole sddm network-manager neofetch"
apt-get install -y $DESKTOP_PACKAGES
echo "--> Cleaning up APT cache..."
apt-get clean
rm /tmp/install_desktop.sh
EOF

chmod +x "$LUMINOS_CHROOT_DIR/tmp/install_desktop.sh"

echo "--> Mounting virtual filesystems for chroot..."
mount --bind /dev "$LUMINOS_CHROOT_DIR/dev"
mount --bind /dev/pts "$LUMINOS_CHROOT_DIR/dev/pts"
mount -t proc /proc "$LUMINOS_CHROOT_DIR/proc"
mount -t sysfs /sys "$LUMINOS_CHROOT_DIR/sys"

echo "--> Entering chroot to perform installation..."
chroot "$LUMINOS_CHROOT_DIR" /tmp/install_desktop.sh

echo "--> Unmounting virtual filesystems..."
umount "$LUMINOS_CHROOT_DIR/sys"
umount "$LUMINOS_CHROOT_DIR/proc"
umount "$LUMINOS_CHROOT_DIR/dev/pts"
umount "$LUMINOS_CHROOT_DIR/dev"

echo ""
echo "SUCCESS: Kernel and desktop environment installed."
echo "Next step: 04-customize-desktop.sh"
exit 0
