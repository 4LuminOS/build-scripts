#!/bin/bash

# ==============================================================================
# LuminOS Build Script - Phase 5: Local AI Integration
#
# Author: Gabriel, Project Leader @ LuminOS
# Version: 0.1.4
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
# Added -f to fail fast on server errors (like 404)
curl -fL "https://github.com/ollama/ollama/releases/download/v${OLLAMA_VERSION}/ollama-linux-amd64" -o ollama
chmod +x ollama
echo "--> Installing Ollama binary into the system..."
mv ollama "$LUMINOS_CHROOT_DIR/usr/local/bin/"

# ... (le reste du script est identique)
cat > "$LUMINOS_CHROOT_DIR/tmp/configure_ai.sh" # ... (contenu identique)
# ... (la fin du script est identique)
