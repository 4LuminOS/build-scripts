#!/bin/bash

# ==============================================================================
# LuminOS Build Script, Phase 5: Local AI Integration
#
# Author: Gabriel, Project Leader @ LuminOS
# Version: 0.1.3
# ==============================================================================

set -e
LUMINOS_CHROOT_DIR="chroot"
OLLAMA_VERSION="0.1.32"
BASE_MODEL="llama3"

if [ "$(id -u)" -ne 0 ]; then echo "ERROR: Must be run as root."; exit 1; fi
if [ ! -d "$LUMINOS_CHROOT_DIR" ]; then echo "ERROR: Chroot dir not found."; exit 1; fi

echo "====================================================="
echo "PHASE 5: Installing and Configuring Lumin"
echo "====================================================="

echo "--> Downloading Ollama v${OLLAMA_VERSION}..."
# ... (le contenu reste identique)
mv ollama "$LUMINOS_CHROOT_DIR/usr/local/bin/"

cat > "$LUMINOS_CHROOT_DIR/tmp/configure_ai.sh" # ... (le contenu reste identique)

chmod +x "$LUMINOS_CHROOT_DIR/tmp/configure_ai.sh"

echo "--> Mounting virtual filesystems for chroot..."
mount --bind /dev "$LUMINOS_CHROOT_DIR/dev"; mount --bind /dev/pts "$LUMINOS_CHROOT_DIR/dev/pts"; mount -t proc /proc "$LUMINOS_CHROOT_DIR/proc"; mount -t sysfs /sys "$LUMINOS_CHROOT_DIR/sys"

echo "--> Entering chroot to configure AI service..."
chroot "$LUMINOS_CHROOT_DIR" env -i PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin /tmp/configure_ai.sh

echo "--> IMPORTANT: Pulling base model '${BASE_MODEL}' inside chroot. This will take some time..."
chroot "$LUMINOS_CHROOT_DIR" env -i PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin /usr/local/bin/ollama pull ${BASE_MODEL}

echo "--> Creating custom 'Lumin' model from Modelfile..."
chroot "$LUMINOS_CHROOT_DIR" env -i PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin /usr/local/bin/ollama create lumin -f /usr/local/share/lumin/ai/Modelfile

echo "--> Unmounting virtual filesystems..."
umount "$LUMINOS_CHROOT_DIR/sys"; umount "$LUMINOS_CHROOT_DIR/proc"; umount "$LUMINOS_CHROOT_DIR/dev/pts"; umount "$LUMINOS_CHROOT_DIR/dev"

echo -e "\nSUCCESS: Local AI 'Lumin' has been integrated."
echo "Next step: 06-final-cleanup.sh"
exit 0
