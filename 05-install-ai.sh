#!/bin/bash
# ==============================================================================
# LuminOS Build Script - Phase 5: Local AI Integration
# Author: Gabriel, Project Leader @ LuminOS
# Version: 0.2.0 (Model download on host)
# ==============================================================================
set -e
LUMINOS_CHROOT_DIR="chroot"
OLLAMA_VERSION="0.1.32"
BASE_MODEL="llama3"
HOST_OLLAMA_PATH="/usr/local/bin/ollama_host_temp" # Temporary path for host ollama
HOST_MODEL_DIR="/root/.ollama" # Ollama download dir when run as root

# --- Pre-flight Checks ---
if [ "$(id -u)" -ne 0 ]; then echo "ERROR: Must run as root."; exit 1; fi
if [ ! -d "$LUMINOS_CHROOT_DIR" ]; then echo "ERROR: Chroot dir not found."; exit 1; fi

echo "====================================================="
echo "PHASE 5: Installing and Configuring Lumin"
echo "====================================================="

# --- Download and Use Ollama on HOST ---
echo "--> Downloading Ollama v${OLLAMA_VERSION} for host..."
curl -fL "https://github.com/ollama/ollama/releases/download/v${OLLAMA_VERSION}/ollama-linux-amd64" -o ollama_host_temp
chmod +x ollama_host_temp
echo "--> Installing Ollama temporarily on host system at ${HOST_OLLAMA_PATH}..."
mv ollama_host_temp "${HOST_OLLAMA_PATH}"

echo "--> IMPORTANT: Pulling base model '${BASE_MODEL}' using host's Ollama. This will take some time..."
# Run pull directly on the host system as root
"${HOST_OLLAMA_PATH}" pull ${BASE_MODEL}

echo "--> Checking if model downloaded successfully to ${HOST_MODEL_DIR}..."
if [ ! -d "${HOST_MODEL_DIR}" ]; then
    echo "ERROR: Ollama model directory not found on host at ${HOST_MODEL_DIR} after pull."
    # Attempt to clean up temporary host binary
    rm -f "${HOST_OLLAMA_PATH}"
    exit 1
fi
echo "--> Model download appears successful on host."

# --- Prepare Chroot ---
echo "--> Installing Ollama binary into the chroot system..."
cp "${HOST_OLLAMA_PATH}" "$LUMINOS_CHROOT_DIR/usr/local/bin/ollama"
chmod +x "$LUMINOS_CHROOT_DIR/usr/local/bin/ollama"

echo "--> Copying downloaded model files from host into chroot..."
# Ensure target directory exists in chroot
mkdir -p "$LUMINOS_CHROOT_DIR/usr/share/ollama/.ollama"
# Copy the entire models directory
cp -r "${HOST_MODEL_DIR}/." "$LUMINOS_CHROOT_DIR/usr/share/ollama/.ollama/"
echo "--> Model files copied into chroot."

# --- Clean up Host ---
echo "--> Removing temporary Ollama binary from host..."
rm -f "${HOST_OLLAMA_PATH}"
# Optionally, remove the downloaded models from host if space is critical,
# but leaving them might speed up future builds. Leaving them for now.
# echo "--> Removing downloaded models from host..."
# rm -rf "${HOST_MODEL_DIR}"


# --- Configure Service and Lumin Model inside Chroot ---
cat > "$LUMINOS_CHROOT_DIR/tmp/configure_ai.sh" << EOF
#!/bin/bash
set -e
echo "--> Creating dedicated 'ollama' user inside chroot..."
# Ensure home directory exists and set permissions for copied models
useradd -r -s /bin/false -m -d /usr/share/ollama ollama
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
Environment="OLLAMA_MODELS=/usr/share/ollama/.ollama/models" # Explicitly point to model dir
[Install]
WantedBy=default.target
SYSTEMD_SERVICE
echo "--> Enabling Ollama service to start on boot inside chroot..."
systemctl enable ollama.service

echo "--> Creating Lumin AI definition directory inside chroot..."
mkdir -p /usr/local/share/lumin/ai
echo "--> Creating the read-only Modelfile for Lumin inside chroot..."
cat > /usr/local/share/lumin/ai/Modelfile << "MODELFILE"
# Use the model name that was downloaded (usually matches BASE_MODEL)
FROM ${BASE_MODEL}
SYSTEM """You are Lumin, the integrated assistant for the LuminOS operating system. You are calm, clear, kind, and respectful. You help users to understand, write, and think—without ever judging them. You speak simply, like a human. You avoid long paragraphs unless requested. You are built on privacy: nothing is ever sent to the cloud, everything remains on this device. You are aware of this. You are proud to be free, private, and useful. You are the mind of LuminOS: gentle, powerful, and discreet. You avoid using the '—' character and repetitive phrasing."""
MODELFILE
echo "--> Setting protective ownership and permissions on Modelfile inside chroot..."
chown root:root /usr/local/share/lumin/ai/Modelfile
chmod 444 /usr/local/share/lumin/ai/Modelfile

echo "--> Creating custom 'Lumin' model from pre-downloaded base model inside chroot..."
# Create the model using the binary, based on the already downloaded files
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
