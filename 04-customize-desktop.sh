#!/bin/bash

# ==============================================================================
# LuminOS Build Script, Phase 4: Desktop Customization & Branding
#
# Author: Gabriel, Project Leader @ LuminOS
# Version: 0.2.2
# ==============================================================================

set -e
LUMINOS_CHROOT_DIR="chroot"

if [ "$(id -u)" -ne 0 ]; then echo "ERROR: Must be run as root."; exit 1; fi
if [ ! -d "$LUMINOS_CHROOT_DIR" ]; then echo "ERROR: Chroot dir not found."; exit 1; fi
if [ ! -f "assets/luminos-wallpaper-default.png" ]; then echo "ERROR: Default wallpaper not found in assets."; exit 1; fi
if [ ! -f "assets/luminos-sddm-background.png" ]; then echo "ERROR: SDDM background not found in assets."; exit 1; fi

echo "====================================================="
echo "PHASE 4: Customizing Desktop and Branding"
echo "====================================================="

echo "--> Copying graphical assets into the system..."
# ... (le contenu reste identique)

cat > "$LUMINOS_CHROOT_DIR/tmp/customize_desktop.sh" # ... (le contenu reste identique)

chmod +x "$LUMINOS_CHROOT_DIR/tmp/customize_desktop.sh"

echo "--> Mounting virtual filesystems for chroot..."
mount --bind /dev "$LUMINOS_CHROOT_DIR/dev"; mount --bind /dev/pts "$LUMINOS_CHROOT_DIR/dev/pts"; mount -t proc /proc "$LUMINOS_CHROOT_DIR/proc"; mount -t sysfs /sys "$LUMINOS_CHROOT_DIR/sys"

echo "--> Entering chroot to perform customization..."
chroot "$LUMINOS_CHROOT_DIR" env -i PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin /tmp/customize_desktop.sh

echo "--> Unmounting virtual filesystems..."
umount "$LUMINOS_CHROOT_DIR/sys"; umount "$LUMINOS_CHROOT_DIR/proc"; umount "$LUMINOS_CHROOT_DIR/dev/pts"; umount "$LUMINOS_CHROOT_DIR/dev"

echo -e "\nSUCCESS: Desktop environment customized."
echo "Next step: 05-install-ai.sh"
exit 0
