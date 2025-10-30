#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive
BASE_MODEL="llama3"
OLLAMA_VERSION="0.1.32"

echo "--> Installing AI dependencies (curl)..."
apt-get install -y curl

echo "--> Downloading & Installing Ollama v${OLLAMA_VERSION}..."
curl -fL "https://github.com/ollama/ollama/releases/download/v${OLLAMA_VERSION}/ollama-linux-amd64" -o /usr/local/bin/ollama
chmod +x /usr/local/bin/ollama

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
Environment="OLLAMA_HOST=0.0.0.0"
Environment="OLLAMA_MODELS=/usr/share/ollama/.ollama/models"
[Install]
WantedBy=default.target
SYSTEMD_SERVICE

echo "--> Enabling Ollama service to start on boot..."
systemctl enable ollama.service

echo "--> Creating Lumin AI definition directory..."
mkdir -p /usr/local/share/lumin/ai

echo "--> Creating the read-only Modelfile for Lumin..."
MODELFILE_PATH="/usr/local/share/lumin/ai/Modelfile"
echo "FROM ${BASE_MODEL}" > "\${MODELFILE_PATH}"
echo 'SYSTEM """You are Lumin, the integrated assistant for the LuminOS operating system. You are calm, clear, kind, and respectful. You help users to understand, write, and think—without ever judging them. You speak simply, like a human. You avoid long paragraphs unless requested. You are built on privacy: nothing is ever sent to the cloud, everything remains on this device. You are aware of this. You are proud to be free, private, and useful. You are the mind of LuminOS: gentle, powerful, and discreet. You avoid using the '—' character and repetitive phrasing."""' >> "\${MODELFILE_PATH}"

echo "--> Setting protective ownership and permissions on Modelfile..."
chown root:root "\${MODELFILE_PATH}"
chmod 444 "\${MODELFILE_PATH}"

echo "--> Pulling base model '${BASE_MODEL}'. This will take time..."
# We pull the model *as* the ollama user for correct permissions
sudo -u ollama /usr/local/bin/ollama pull ${BASE_MODEL}

echo "--> Creating custom 'Lumin' model..."
sudo -u ollama /usr/local/bin/ollama create lumin -f "\${MODELFILE_PATH}"
