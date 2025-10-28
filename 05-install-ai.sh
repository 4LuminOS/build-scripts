#!/bin/bash
# ==============================================================================
# LuminOS Build Script - Phase 5: Local AI Integration
# Author: Gabriel, Project Leader @ LuminOS
# Version: 0.3.1
# ==============================================================================
set -e
LUMINOS_CHROOT_DIR="chroot"
OLLAMA_VERSION="0.1.32" # Version of the binary to install in chroot
BASE_MODEL="llama3" # Name of the model we expect to find on host
HOST_MODEL_DIR="/usr/share/ollama/.ollama/models" # Standard root location

# --- Pre-flight Checks ---
if [ "$(id -u)" -ne 0 ]; then echo "ERROR: Must run as root."; exit 1; fi
if [ ! -d "$LUMINOS_CHROOT_DIR" ]; then echo "ERROR: Chroot dir not found."; exit 1; fi
if [ ! -d "${HOST_MODEL_DIR}" ]; then
    ALT_HOST_MODEL_DIR="$HOME/.ollama/models" # User location
    if [ -d "$ALT_HOST_MODEL_DIR" ]; then
         echo "INFO: Using Ollama models found at $ALT_HOST_MODEL_DIR."
         HOST_MODEL_DIR="$ALT_HOST_MODEL_DIR"
    else
         echo "ERROR: Ollama model directory not found on host at ${HOST_MODEL_DIR} or ${ALT_HOST_MODEL_DIR}."
         echo "Please ensure you have run 'ollama pull ${BASE_MODEL}' successfully on the host."
         exit 1
    fi
fi
echo "--> Found Ollama models on host system at ${HOST_MODEL_DIR}."

echo "====================================================="
echo "PHASE 5: Installing and Configuring Lumin"
echo "====================================================="

# --- Install Ollama Binary in Chroot ---
echo "--> Downloading Ollama v${OLLAMA_VERSION} binary..."
curl -fL "https://github.com/ollama/ollama/releases/download/v${OLLAMA_VERSION}/ollama-linux-amd64" -o ollama_binary_temp
chmod +x ollama_binary_temp
echo "--> Installing Ollama binary into the chroot system..."
mv ollama_binary_temp "$LUMINOS_CHROOT_DIR/usr/local/bin/ollama"

# --- Copy Pre-Downloaded Model into Chroot ---
echo "--> Copying pre-downloaded model files from host (${HOST_MODEL_DIR}) into chroot..."
mkdir -p "$LUMINOS_CHROOT_DIR/usr/share/ollama/.ollama"
cp -r "${HOST_MODEL_DIR}/." "$LUMINOS_CHROOT_DIR/usr/share/ollama/.ollama/models/"
echo "--> Model files copied into chroot."


# --- Configure Service and Lumin Model inside Chroot ---
cat > "$LUMINOS_CHROOT_DIR/tmp/configure_ai.sh" << EOF
#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive
echo "--> Creating dedicated 'ollama' user inside chroot..."
useradd -r -s /bin/false -m -d /usr/share/ollama ollama
echo "--> Setting ownership of copied model files for ollama user..."
chown -R ollama:ollama /usr/share/ollama/.ollama
echo "--> Creating Ollama systemd service file inside chroot..."
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
Environment="OLLAMA_HOST=0.0.0.0"
Environment="OLLAMA_MODELS=/usr/share/ollama/.ollama/models"
[Install]
WantedBy=default.target
SYSTEMD_SERVICE
echo "--> Enabling Ollama service to start on boot inside chroot..."
systemctl enable ollama.service
echo "--> Creating Lumin AI definition directory inside chroot..."
mkdir -p /usr/local/share/lumin/ai
echo "--> Creating the read-only Modelfile for Lumin inside chroot..."
cat > /usr/local/share/lumin/ai/Modelfile << "MODELFILE"
FROM ${BASE_MODEL}
SYSTEM """You are Lumin, the integrated assistant for the LuminOS operating system. You are calm, clear, kind, and respectful. You help users to understand, write, and think—without ever judging them. You speak simply, like a human. You avoid long paragraphs unless requested. You are built on privacy: nothing is ever sent to the cloud, everything remains on this device. You are aware of this. You are proud to be free, private, and useful. You are the mind of LuminOS: gentle, powerful, and discreet. You avoid using the '—' character and repetitive phrasing."""
MODELFILE
echo "--> Setting protective ownership and permissions on Modelfile inside chroot..."
chown root:root /usr/local/share/lumin/ai/Modelfile
chmod 444 /usr/local/share/lumin/ai/Modelfile
echo "--> Creating custom 'Lumin' model from pre-copied base model inside chroot..."
/usr/local/bin/ollama create lumin -f /usr/local/share/lumin/ai/Modelfile
rm /tmp/configure_ai.sh
EOF

chmod +x "$LUMINOS_CHROOT_DIR/tmp/configure_ai.sh"

# --- Mounts, Chroot Execution, Unmounts for Configuration ---
echo "--> Mounting virtual filesystems for chroot configuration..."
mount --bind /dev "$LUMINOS_CHROOT_DIR/dev"; mount --bind /dev/pts "$LUMINOS_CHROOT_DIR/dev/pts"; mount -t proc /proc "$LUMINOS_CHROOT_DIR/proc"; mount -t sysfs /sys "$LUMINOS_CHROOT_DIR/sys"

echo "--> Entering chroot to configure AI service and create model..."
# Added HOME=/root to the environment variables passed into chroot
chroot "$LUMINOS_CHROOT_DIR" env -i HOME=/root PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin /tmp/configure_ai.sh

echo "--> Unmounting virtual filesystems after configuration..."
umount "$LUMINOS_CHROOT_DIR/sys"; umount "$LUMINOS_CHROOT_DIR/proc"; umount "$LUMINOS_CHROOT_DIR/dev/pts"; umount "$LUMINOS_CHROOT_DIR/dev"

echo ""
echo "SUCCESS: Local AI 'Lumin' has been integrated."
echo "Next step: 06-final-cleanup.sh"
exit 0
