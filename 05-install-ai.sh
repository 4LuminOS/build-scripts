#!/bin/bash
set -e

echo "--> Configuring AI..."
useradd -r -s /bin/false -m -d /usr/share/ollama ollama
chown -R ollama:ollama /usr/share/ollama
mkdir -p /usr/local/share/lumin/ai

# Modelfile
MODELFILE="/usr/local/share/lumin/ai/Modelfile"
echo "FROM llama3" > "${MODELFILE}"
echo 'SYSTEM """You are Lumin, the integrated assistant for the LuminOS operating system. You are calm, clear, kind, and respectful."""' >> "${MODELFILE}"
chown root:root "${MODELFILE}"
chmod 444 "${MODELFILE}"

# Reassemble Script
cat > /usr/local/bin/luminos-reassemble.sh << "EOF"
#!/bin/bash
# Find files marked as split
while IFS= read -r -d '' marker; do
    ORIG_FILE="${marker%.is_split}"
    if [ ! -f "$ORIG_FILE" ]; then
        echo "Reassembling $ORIG_FILE..."
        # Combine parts .partaa, .partab...
        cat "${ORIG_FILE}.part"* > "$ORIG_FILE"
        chown ollama:ollama "$ORIG_FILE"
    fi
done < <(find /usr/share/ollama/.ollama -name "*.is_split" -print0)
EOF
chmod +x /usr/local/bin/luminos-reassemble.sh

# Reassemble Service
cat > /etc/systemd/system/lumin-reassemble.service << "SERVICE"
[Unit]
Description=Reassemble AI Models
Before=ollama.service
[Service]
Type=oneshot
ExecStart=/usr/local/bin/luminos-reassemble.sh
[Install]
WantedBy=multi-user.target
SERVICE

# Ollama Service
cat > /etc/systemd/system/ollama.service << "SERVICE"
[Unit]
Description=Ollama API Server
After=network-online.target lumin-reassemble.service
[Service]
ExecStart=/usr/local/bin/ollama serve
User=ollama
Group=ollama
Restart=always
Environment="OLLAMA_HOST=0.0.0.0"
Environment="OLLAMA_MODELS=/usr/share/ollama/.ollama/models"
[Install]
WantedBy=default.target
SERVICE

# Lumin Setup Service
cat > /etc/systemd/system/lumin-setup.service << "SERVICE"
[Unit]
Description=Init Lumin AI
After=ollama.service
Requires=ollama.service
ConditionPathExists=!/var/lib/lumin-setup-done
[Service]
Type=oneshot
ExecStartPre=/bin/sleep 10
ExecStart=/usr/local/bin/ollama create lumin -f /usr/local/share/lumin/ai/Modelfile
ExecStartPost=/usr/bin/touch /var/lib/lumin-setup-done
[Install]
WantedBy=multi-user.target
SERVICE

systemctl enable lumin-reassemble.service
systemctl enable ollama.service
systemctl enable lumin-setup.service
