#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive
echo "--> Removing unwanted packages..."
PACKAGES_TO_REMOVE="kmahjongg kmines kpat ksnake kmail kontact akregator"
for pkg in $PACKAGES_TO_REMOVE; do
    apt-get purge -y "$pkg" || true
done
apt-get autoremove -y
echo "--> Applying system-wide dark theme (Breeze Dark)..."
mkdir -p /etc/skel/.config
cat > /etc/skel/.config/kdeglobals << "KDEGLOBALS"
[General]
ColorScheme=BreezeDark
Name=BreezeDark
[Icons]
Theme=breeze-dark
KDEGLOBALS
echo "--> Setting default desktop wallpaper..."
cat > /etc/skel/.config/plasma-org.kde.plasma.desktop-appletsrc << "WALLPAPER_CONF"
[Containments][1]
wallpaperplugin=org.kde.image
[Containments][1][Wallpaper][org.kde.image][General]
Image=file:///usr/share/wallpapers/luminos/luminos-wallpaper-default.png
WALLPAPER_CONF
echo "--> Setting SDDM login screen background..."
mkdir -p /etc/sddm.conf.d/
cat > /etc/sddm.conf.d/luminos-theme.conf << "SDDM_CONF"
[Theme]
Current=breeze
Background=/usr/share/wallpapers/luminos/luminos-sddm-background.png
SDDM_CONF
echo "--> Branding the system as LuminOS..."
cat > /etc/os-release << "OSRELEASE"
PRETTY_NAME="LuminOS"
NAME="LuminOS"
VERSION_ID="0.2"
VERSION="0.2 (Rebirth)"
ID=luminos
HOME_URL="https://github.com/4LuminOS/build-scripts"
OSRELEASE
echo "LuminOS 0.2 \n \l" > /etc/issue
