#!/bin/bash
set -e

echo "--> Configuring pre-installed Lumin AI..."

# 1. Create User
echo "--> Creating dedicated 'ollama' user..."
# We assume the files are already copied to /usr/share/ollama/.ollama by build.sh
useradd -r -s /bin/false -m -d /usr/share/ollama ollama

# 2. Fix Permissions
echo "--> Setting ownership of model files..."
chown -R ollama:ollama /usr/share/ollama

# 3. Create Service
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

# 4. Enable Service
echo "--> Enabling Ollama service..."
systemctl enable ollama.service

echo "SUCCESS: Lumin AI configured."
