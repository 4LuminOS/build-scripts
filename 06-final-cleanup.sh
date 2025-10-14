#!/bin/bash

# ==============================================================================
# LuminOS Build Script, Phase 6: "Final" Cleanup
#
# Description: This script performs "final" cleanup operations on the chroot
#              environment before packaging it into a bootable ISO. 
#
# Author: Gabriel, Project Leader @ LuminOS
# Version: 0.1.0
# ==============================================================================

# --- Configuration ---
set -e

# --- Variables ---
LUMINOS_CHROOT_DIR="chroot"

# --- Pre-flight Checks ---
if [ "$(id -u)" -ne 0 ]; then echo "ERROR: Must be run as root."; exit 1; fi
if [ ! -d "$LUMINOS_CHROOT_DIR" ]; then echo "ERROR: Chroot dir not found."; exit 1; fi

# --- Main Logic ---
echo "====================================================="
echo "PHASE 6: Final System Cleanup"
echo "====================================================="

# Create the script to be run inside the chroot
cat > "$LUMINOS_CHROOT_DIR/tmp/cleanup.sh" << "EOF"
#!/bin/bash
set -e

echo "--> Cleaning APT cache..."
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "--> Cleaning temporary files..."
rm -rf /tmp/*

echo "--> Cleaning machine-id..."
truncate -s 0 /etc/machine-id
rm /var/lib/dbus/machine-id
ln -s /etc/machine-id /var/lib/dbus/machine-id

echo "--> Cleaning bash history..."
unset HISTFILE
rm -f /root/.bash_history
rm -f /home/liveuser/.bash_history

# Clean up this script itself
rm /tmp/cleanup.sh
EOF

chmod +x "$LUMINOS_CHROOT_DIR/tmp/cleanup.sh"
echo "--> Entering chroot to perform cleanup..."
chroot "$LUMINOS_CHROOT_DIR" /tmp/cleanup.sh

echo ""
echo "SUCCESS: Final cleanup is complete."
echo "The system is ready for ISO packaging."

exit 0
