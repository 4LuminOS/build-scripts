#!/bin/bash
set -e

echo "--> INSTALLING SOFTWARE (Zen Browser & Tools)..."

# 1. Base Tools & UI Assets
# REMOVED: neofetch (I assume package is dead/archived in Debian Trixie, i'll try with fastfetch later)
apt-get update
apt-get install -y \
    htop \
    w3m \
    curl \
    wget \
    unzip \
    bzip2 \
    vlc \
    dmz-cursor-theme \
    papirus-icon-theme

# 2. ZEN BROWSER INSTALLATION
echo "--> Installing Zen Browser..."
mkdir -p /opt/zen-browser
# URL dynamique vers la dernière release Linux
ZEN_URL="https://github.com/zen-browser/desktop/releases/latest/download/zen.linux-x86_64.tar.bz2"

wget -O /tmp/zen.tar.bz2 "$ZEN_URL"
# Extraction
tar -xjf /tmp/zen.tar.bz2 -C /opt/zen-browser --strip-components=1

# Symbolic link
ln -sf /opt/zen-browser/zen /usr/local/bin/zen-browser

# Shortcut (.desktop)
cat > /usr/share/applications/zen-browser.desktop <<EOF
[Desktop Entry]
Name=Zen Browser
Comment=Experience tranquility
Exec=zen-browser %u
Icon=/opt/zen-browser/browser/chrome/icons/default/default128.png
Terminal=false
Type=Application
Categories=Network;WebBrowser;
StartupNotify=true
EOF

# Set Zen as default web browser
update-alternatives --install /usr/bin/x-www-browser x-www-browser /usr/local/bin/zen-browser 200
update-alternatives --set x-www-browser /usr/local/bin/zen-browser

# Clean up
rm -f /tmp/zen.tar.bz2

echo "--> Software installation complete."
