#!/bin/bash
# ==============================================================================
# LuminOS Build Script - Phase 5: Local AI Integration
# Author: Gabriel, Project Leader @ LuminOS
# Version: 0.3.3 (Create Modelfile with echo)
# ==============================================================================
set -e
LUMINOS_CHROOT_DIR="chroot"
OLLAMA_VERSION="0.1.32"
BASE_MODEL="llama3"
HOST_MODEL_DIR="/usr/share/ollama/.ollama/models"

# --- Pre-flight Checks ---
# ... (Checks remain the same) ...
echo "--> Found Ollama models on host system at ${HOST_MODEL_DIR}."

echo "====================================================="
echo "PHASE 5: Installing and Configuring Lumin"
echo "====================================================="

# --- Install Ollama Binary & Copy Model (remain the same) ---
# ... (Download binary, copy model) ...

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

# --- Create Modelfile using echo (NEW METHOD) ---
echo "--> Creating the read-only Modelfile for Lumin inside chroot (using echo)..."
MODELFILE_PATH="/usr/local/share/lumin/ai/Modelfile"
# Create/overwrite the file with the FROM line
echo "FROM ${BASE_MODEL}" > "\${MODELFILE_PATH}"
# Append the SYSTEM line (using single quotes to prevent premature expansion)
echo 'SYSTEM """You are Lumin, the integrated assistant for the LuminOS operating system. You are calm, clear, kind, and respectful. You help users to understand, write, and think—without ever judging them. You speak simply, like a human. You avoid long paragraphs unless requested. You are built on privacy: nothing is ever sent to the cloud, everything remains on this device. You are aware of this. You are proud to be free, private, and useful. You are the mind of LuminOS: gentle, powerful, and discreet. You avoid using the '—' character and repetitive phrasing."""' >> "\${MODELFILE_PATH}"
# --- End New Method ---

echo "--> Setting protective ownership and permissions on Modelfile inside chroot..."
chown root:root "\${MODELFILE_PATH}"
chmod 444 "\${MODELFILE_PATH}"

# --- Debugging Modelfile (Keep for now) ---
echo "--> Verifying Modelfile content and permissions:"
echo "--- Modelfile Content START ---"
cat "\${MODELFILE_PATH}" || echo "ERROR: Could not cat Modelfile"
echo "--- Modelfile Content END ---"
echo "--- Modelfile Permissions ---"
ls -l "\${MODELFILE_PATH}" || echo "ERROR: Could not ls Modelfile"
echo "---------------------------"
# --- End Debugging ---

echo "--> Creating custom 'Lumin' model from pre-copied base model inside chroot..."
/usr/local/bin/ollama create lumin -f "\${MODELFILE_PATH}"

rm /tmp/configure_ai.sh
EOF

chmod +x "$LUMINOS_CHROOT_DIR/tmp/configure_ai.sh"

# --- Mounts, Chroot Execution, Unmounts for Configuration ---
# ... (remain the same) ...

echo ""
echo "SUCCESS: Local AI 'Lumin' has been integrated."
echo "Next step: 06-final-cleanup.sh"
exit 0
