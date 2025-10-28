#!/bin/bash
# ==============================================================================
# LuminOS Build Script - Phase 3: Desktop Environment Installation
# Author: Gabriel, Project Leader @ LuminOS
# Version: 0.2.0 (Removed neofetch)
# ==============================================================================
set -e
LUMINOS_CHROOT_DIR="chroot"

# --- Pre-flight Checks ---
if [ "$(id -u)" -ne 0 ]; then echo "ERROR: Must run as root."; exit 1; fi
if [ ! -d "$LUMINOS_CHROOT_DIR" ]; then echo "ERROR: Chroot dir not found."; exit 1; fi

echo "====================================================="
echo "PHASE 3: Installing Kernel and Desktop"
echo "====================================================="

cat > "$LUMINOS_CHROOT_DIR/tmp/install_desktop.sh" << "EOF"
#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive

echo "--> Cleaning existing APT cache inside chroot..."
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "--> Updating package lists inside chroot..."
apt-get update

echo "--> Installing Linux kernel and GRUB bootloader..."
apt-get install -y linux-image-amd64 grub-pc

echo "--> Installing CORE KDE Plasma desktop and services..."
# neofetch removed from this list
CORE_DESKTOP_PACKAGES="plasma-desktop konsole sddm network-manager"
apt-get install -y $CORE_DESKTOP_PACKAGES

echo "--> Final cleaning of APT cache..."
apt-get clean
rm -rf /var/lib/apt/lists/*
rm /tmp/install_desktop.sh
EOF

chmod +x "$LUMINOS_CHROOT_DIR/tmp/install_desktop.sh"

# --- Mounts, Chroot Execution, Unmounts ---
echo "--> Mounting virtual filesystems for chroot..."
mount --bind /dev "$LUMINOS_CHROOT_DIR/dev"; mount --bind /dev/pts "$LUMINOS_CHROOT_DIR/dev/pts"; mount -t proc /proc "$LUMINOS_CHROOT_DIR/proc"; mount -t sysfs /sys "$LUMINOS_CHROOT_DIR/sys"

echo "--> Entering chroot to perform installation..."
chroot "$LUMINOS_CHROOT_DIR" env -i PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin /tmp/install_desktop.sh

echo "--> Unmounting virtual filesystems..."
umount "$LUMINOS_CHROOT_DIR/sys"; umount "$LUMINOS_CHROOT_DIR/proc"; umount "$LUMINOS_CHROOT_DIR/dev/pts"; umount "$LUMINOS_CHROOT_DIR/dev"

echo ""
echo "SUCCESS: Kernel and desktop environment installed."
echo "Next step: 04-customize-desktop.sh"
exit 0
