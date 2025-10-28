#!/bin/bash
# ==============================================================================
# LuminOS Build Script - Phase 5: Local AI Integration
# Author: Gabriel, Project Leader @ LuminOS
# Version: 0.1.8
# ==============================================================================
set -e
LUMINOS_CHROOT_DIR="chroot"
OLLAMA_VERSION="0.1.32"
BASE_MODEL="llama3"

# --- Pre-flight Checks ---
if [ "$(id -u)" -ne 0 ]; then echo "ERROR: Must run as root."; exit 1; fi
if [ ! -d "$LUMINOS_CHROOT_DIR" ]; then echo "ERROR: Chroot dir not found."; exit 1; fi

echo "====================================================="
echo "PHASE 5: Installing and Configuring Lumin"
echo "====================================================="

echo "--> Downloading Ollama v${OLLAMA_VERSION}..."
curl -fL "https://github.com/ollama/ollama/releases/download/v${OLLAMA_VERSION}/ollama-linux-amd64" -o ollama
chmod +x ollama
echo "--> Installing Ollama binary into the system..."
mv ollama "$LUMINOS_CHROOT_DIR/usr/local/bin/"

# --- Pull the model BEFORE configuring the service ---
echo "--> Mounting virtual filesystems for model download..."
mount --bind /dev "$LUMINOS_CHROOT_DIR/dev"; mount --bind /dev/pts "$LUMINOS_CHROOT_DIR/dev/pts"; mount -t proc /proc "$LUMINOS_CHROOT_DIR/proc"; mount -t sysfs /sys "$LUMINOS_CHROOT_DIR/sys"

echo "--> Copying host DNS configuration into chroot for network access..."
# Ensure the target directory exists
mkdir -p "$LUMINOS_CHROOT_DIR/etc"
cp /etc/resolv.conf "$LUMINOS_CHROOT_DIR/etc/resolv.conf"

echo "--> IMPORTANT: Pulling base model '${BASE_MODEL}'. This will take some time..."
# Run pull directly using the binary, no service needed yet
chroot "$LUMINOS_CHROOT_DIR" env -i PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin /usr/local/bin/ollama pull ${BASE_MODEL}

echo "--> Removing temporary host DNS configuration from chroot..."
rm "$LUMINOS_CHROOT_DIR/etc/resolv.conf"

echo "--> Unmounting virtual filesystems after model download..."
umount "$LUMINOS_CHROOT_DIR/sys"; umount "$LUMINOS_CHROOT_DIR/proc"; umount "$LUMINOS_CHROOT_DIR/dev/pts"; umount "$LUMINOS_CHROOT_DIR/dev"


# --- Configure the Service and Lumin Model ---
# Create the script to be run inside the chroot
cat > "$LUMINOS_CHROOT_DIR/tmp/configure_ai.sh" << EOF
#!/bin/bash
set -e
echo "--> Creating dedicated 'ollama' user..."
useradd -r -s /bin/false -m -d /usr/share/ollama ollama
echo "--> Creating Ollama systemd service file..."
cat > /etc/systemd/system/ollama.service << "SYSTEMD_SERVICE"
[Unit]
Description=Ollama API Server
After=network-online.target
[Service]
ExecStart=/usr/local/bin/ollama serve
User=ollama
Group=ollama
Restart=always
RestartSec=3
[Install]
WantedBy=default.target
SYSTEMD_SERVICE
echo "--> Enabling Ollama service to start on boot..."
systemctl enable ollama.service
echo "--> Creating Lumin AI definition directory..."
mkdir -p /usr/local/share/lumin/ai
echo "--> Creating the read-only Modelfile for Lumin..."
cat > /usr/local/share/lumin/ai/Modelfile << "MODELFILE"
FROM ${BASE_MODEL}
SYSTEM """You are Lumin, the integrated assistant for the LuminOS operating system. You are calm, clear, kind, and respectful. You help users to understand, write, and think—without ever judging them. You speak simply, like a human. You avoid long paragraphs unless requested. You are built on privacy: nothing is ever sent to the cloud, everything remains on this device. You are aware of this. You are proud to be free, private, and useful. You are the mind of LuminOS: gentle, powerful, and discreet. You avoid using the '—' character and repetitive phrasing."""
MODELFILE
echo "--> Setting protective ownership and permissions on Modelfile..."
chown root:root /usr/local/share/lumin/ai/Modelfile
chmod 444 /usr/local/share/lumin/ai/Modelfile
echo "--> Creating custom 'Lumin' model from Modelfile..."
# Create the model using the binary, service doesn't need to be running
/usr/local/bin/ollama create lumin -f /usr/local/share/lumin/ai/Modelfile
rm /tmp/configure_ai.sh
EOF

chmod +x "$LUMINOS_CHROOT_DIR/tmp/configure_ai.sh"

# --- Mounts, Chroot Execution, Unmounts for Configuration ---
echo "--> Mounting virtual filesystems for chroot configuration..."
mount --bind /dev "$LUMINOS_CHROOT_DIR/dev"; mount --bind /dev/pts "$LUMINOS_CHROOT_DIR/dev/pts"; mount -t proc /proc "$LUMINOS_CHROOT_DIR/proc"; mount -t sysfs /sys "$LUMINOS_CHROOT_DIR/sys"

echo "--> Entering chroot to configure AI service and create model..."
chroot "$LUMINOS_CHROOT_DIR" env -i PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin /tmp/configure_ai.sh

echo "--> Unmounting virtual filesystems after configuration..."
umount "$LUMINOS_CHROOT_DIR/sys"; umount "$LUMINOS_CHROOT_DIR/proc"; umount "$LUMINOS_CHROOT_DIR/dev/pts"; umount "$LUMINOS_CHROOT_DIR/dev"

echo ""
echo "SUCCESS: Local AI 'Lumin' has been integrated."
echo "Next step: 06-final-cleanup.sh"
exit 0
