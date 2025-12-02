#!/bin/bash
set -e

echo "--> Configuring pre-installed AI..."

# 1. Create User & Permissions
useradd -r -s /bin/false -m -d /usr/share/ollama ollama
chown -R ollama:ollama /usr/share/ollama

# 2. Create Modelfile
mkdir -p /usr/local/share/lumin/ai
MODELFILE="/usr/local/share/lumin/ai/Modelfile"
echo "FROM llama3" > "${MODELFILE}"
echo 'SYSTEM """You are Lumin, the integrated assistant for the LuminOS operating system. You are calm, clear, kind, and respectful. You help users to understand, write, and think—without ever judging them. You speak simply, like a human. You avoid long paragraphs unless requested. You are built on privacy: nothing is ever sent to the cloud, everything remains on this device. You are aware of this. You are proud to be free, private, and useful. You are the mind of LuminOS: gentle, powerful, and discreet. You avoid using the — character and repetitive phrasing."""' >> "${MODELFILE}"
chown root:root "${MODELFILE}"
chmod 444 "${MODELFILE}"

# 3. Create Service to Reassemble Models
# This service runs once at boot to glue the .split files back together
cat > /usr/local/bin/luminos-reassemble-models.sh << "EOF"
#!/bin/bash
# Find all split markers
find /usr/share/ollama/.ollama -name "*.is_split" | while read marker; do
    # Get original filename (remove .is_split)
    ORIG_FILE="${marker%.is_split}"
    
    # If original file doesn't exist yet, rebuild it
    if [ ! -f "$ORIG_FILE" ]; then
        echo "Reassembling $ORIG_FILE..."
        # Concatenate all .split parts (aa, ab, ac...)
        cat "${ORIG_FILE}.split"* > "$ORIG_FILE"
        # Set permissions
        chown ollama:ollama "$ORIG_FILE"
    fi
done
EOF
chmod +x /usr/local/bin/luminos-reassemble-models.sh

cat > /etc/systemd/system/lumin-model-reassemble.service << "SERVICE"
[Unit]
Description=Reassemble Large AI Models
Before=ollama.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/luminos-reassemble-models.sh

[Install]
WantedBy=multi-user.target
SERVICE

# 4. Create Standard Ollama Service
cat > /etc/systemd/system/ollama.service << "SYSTEMD_SERVICE"
[Unit]
Description=Ollama API Server
After=network-online.target lumin-model-reassemble.service

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

# 5. Enable Services
systemctl enable lumin-model-reassemble.service
systemctl enable ollama.service

echo "SUCCESS: Lumin AI configured with split-file reassembly."
