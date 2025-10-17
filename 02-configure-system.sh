#!/bin/bash

# ==============================================================================
# LuminOS Build Script,Phase 2: System Configuration
#
# Author: Gabriel, Project Leader @ LuminOS
# Version: 0.2.2
# ==============================================================================

set -e
LUMINOS_CHROOT_DIR="chroot"

if [ "$(id -u)" -ne 0 ]; then echo "ERROR: Must be run as root."; exit 1; fi
if [ ! -d "$LUMINOS_CHROOT_DIR" ]; then echo "ERROR: Chroot dir not found."; exit 1; fi

echo "====================================================="
echo "PHASE 2: Configuring LuminOS Base System"
echo "====================================================="

cat > "$LUMINOS_CHROOT_DIR/tmp/configure.sh" # ... (Le contenu du script interne reste identique)

chmod +x "$LUMINOS_CHROOT_DIR/tmp/configure.sh"

echo "--> Mounting virtual filesystems for chroot..."
mount --bind /dev "$LUMINOS_CHROOT_DIR/dev"; mount --bind /dev/pts "$LUMINOS_CHROOT_DIR/dev/pts"; mount -t proc /proc "$LUMINOS_CHROOT_DIR/proc"; mount -t sysfs /sys "$LUMINOS_CHROOT_DIR/sys"

echo "--> Entering chroot to perform configuration..."
chroot "$LUMINOS_CHROOT_DIR" env -i PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin CI="$CI" /tmp/configure.sh

echo "--> Unmounting virtual filesystems..."
umount "$LUMINOS_CHROOT_DIR/sys"; umount "$LUMINOS_CHROOT_DIR/proc"; umount "$LUMINOS_CHROOT_DIR/dev/pts"; umount "$LUMINOS_CHROOT_DIR/dev"

echo -e "\nSUCCESS: LuminOS base system configured."
echo "Next step: 03-install-desktop.sh"
exit 0
