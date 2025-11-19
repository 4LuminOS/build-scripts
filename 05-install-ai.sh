#!/bin/bash
set -e

echo "--> Configuring pre-installed AI..."

# 1. Create User & Permissions
useradd -r -s /bin/false -m -d /usr/share/ollama ollama
chown -R ollama:ollama /usr/share/ollama

# 2. Create Directory for Modelfile
mkdir -p /usr/local/share/lumin/ai

# 3. Create the Modelfile (using echo safe method)
MODELFILE="/usr/local/share/lumin/ai/Modelfile"
echo "FROM llama3" > "${MODELFILE}"
echo 'SYSTEM """You are Lumin, the integrated assistant for the LuminOS operating system. You are direct, clear, kind, and respectful. You help users to understand, write, and think—without ever judging them. You speak simply, like a human. You avoid long paragraphs unless requested. You are built on privacy: nothing is ever sent to the cloud, everything remains on the device of the user. You are aware of this. You are proud to be free, private, and useful. You are the mind of LuminOS: gentle, powerful, and discreet. Avoid using the "—" character and repetitive phrasing."""' >> "${MODELFILE}"
chown root:root "${MODELFILE}"
chmod 444 "${MODELFILE}"

# 4. Create Standard Ollama Service
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

# 5. Create "Lumin Setup" Service (Runs once at boot)
# This solves the build-time creation issue by moving it to run-time.
cat > /etc/systemd/system/lumin-setup.service << "SETUP_SERVICE"
[Unit]
Description=Initialize Lumin AI Model
After=ollama.service
Requires=ollama.service
ConditionPathExists=!/var/lib/lumin-setup-done

[Service]
Type=oneshot
User=root
ExecStartPre=/bin/sleep 10
ExecStart=/usr/local/bin/ollama create lumin -f /usr/local/share/lumin/ai/Modelfile
ExecStartPost=/usr/bin/touch /var/lib/lumin-setup-done

[Install]
WantedBy=multi-user.target
SETUP_SERVICE

# 6. Enable Services
systemctl enable ollama.service
systemctl enable lumin-setup.service

echo "SUCCESS: Lumin AI configured (Creation deferred to first boot)."
