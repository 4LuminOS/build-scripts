#!/bin/bash

# ==============================================================================
# LuminOS Build Script, Phase 6: Final Cleanup
#
# Author: Gabriel, Project Leader @ LuminOS
# Version: 0.1.3
# ==============================================================================

set -e
LUMINOS_CHROOT_DIR="chroot"

if [ "$(id -u)" -ne 0 ]; then echo "ERROR: Must be run as root."; exit 1; fi
if [ ! -d "$LUMINOS_CHROOT_DIR" ]; then echo "ERROR: Chroot dir not found."; exit 1; fi

echo "====================================================="
echo "PHASE 6: Final System Cleanup"
echo "====================================================="

# The self-destruct line has been removed from this inner script.
cat > "$LUMINOS_CHROOT_DIR/tmp/cleanup.sh" << "EOF"
#!/bin/bash
set -e

echo "--> Cleaning APT cache..."
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "--> Cleaning temporary files..."
# This will also delete the script itself, but the script will continue
rm -rf /tmp/*

echo "--> Cleaning machine-id..."
truncate -s 0 /etc/machine-id
mkdir -p /var/lib/dbus
rm -f /var/lib/dbus/machine-id
ln -s /etc/machine-id /var/lib/dbus/machine-id

echo "--> Cleaning bash history..."
unset HISTFILE
rm -f /root/.bash_history
rm -f /home/liveuser/.bash_history
EOF

chmod +x "$LUMINOS_CHROOT_DIR/tmp/cleanup.sh"

echo "--> Entering chroot to perform cleanup..."
chroot "$LUMINOS_CHROOT_DIR" env -i PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin /tmp/cleanup.sh

# The temporary script is now gone from inside the chroot, so we don't need to clean it up.

echo "--> Unmounting virtual filesystems..."
umount "$LUMINOS_CHROOT_DIR/sys"
umount "$LUMINOS_CHROOT_DIR/proc"
umount "$LUMINOS_CHROOT_DIR/dev/pts"
umount "$LUMINOS_CHROOT_DIR/dev"

echo ""
echo "SUCCESS: Final cleanup is complete."
echo "The system is ready for ISO packaging."

exit 0
