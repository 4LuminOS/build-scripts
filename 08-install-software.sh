#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive

echo "--> Installing Essential Software..."

# 1. Multimedia & Codecs (The "Play Everything" Pack)
# ffmpeg, gstreamer plugins for wide format support, and VLC
echo "--> Installing Codecs and VLC..."
apt-get install -y \
    ffmpeg \
    libavcodec-extra \
    gstreamer1.0-libav \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-vaapi \
    vlc

# 2. System Tools
# Timeshift for backups, Flatpak for app store, unrar for archives
echo "--> Installing System Tools..."
apt-get install -y \
    timeshift \
    flatpak \
    plasma-discover-backend-flatpak \
    unrar-free \
    p7zip-full

# Configure Flathub (so the user has apps right away)
echo "--> Adding Flathub repository..."
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# 3. Productivity: OnlyOffice
# We download the latest .deb directly from OnlyOffice servers
echo "--> Downloading & Installing OnlyOffice..."
ONLYOFFICE_URL="https://download.onlyoffice.com/install/desktop/editors/linux/onlyoffice-desktopeditors_amd64.deb"
curl -L -o /tmp/onlyoffice.deb "$ONLYOFFICE_URL"

# Install via apt to handle dependencies automatically
apt-get install -y /tmp/onlyoffice.deb
rm /tmp/onlyoffice.deb

echo "SUCCESS: Essential software installed."
