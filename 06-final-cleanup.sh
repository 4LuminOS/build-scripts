#!/bin/bash

# ==============================================================================
# LuminOS Build Script, Phase 6: Final Cleanup
#
# Author: Gabriel, Project Leader @ LuminOS
# Version: 0.1.4
# ==============================================================================

set -e
LUMINOS_CHROOT_DIR="chroot"

if [ "$(id -u)" -ne 0 ]; then echo "ERROR: Must be run as root."; exit 1; fi
if [ ! -d "$LUMINOS_CHROOT_DIR" ]; then echo "ERROR: Chroot dir not found."; exit 1; fi

echo "====================================================="
echo "PHASE 6: Final System Cleanup"
echo "====================================================="

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
# No mounts are needed for these simple cleanup operations
chroot "$LUMINOS_CHROOT_DIR" env -i PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin /tmp/cleanup.sh

# The unmounts are removed as they were already done by the previous script.

echo ""
echo "SUCCESS: Final cleanup is complete."
echo "The system is ready for ISO packaging."

exit 0
