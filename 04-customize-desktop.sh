#!/bin/bash

# ==============================================================================
# LuminOS Build Script, Phase 4: Desktop Customization & Branding
#
# Author: Gabriel, Project Leader @ LuminOS
# Version: 0.2.3
# ==============================================================================

set -e
LUMINOS_CHROOT_DIR="chroot"

if [ "$(id -u)" -ne 0 ]; then echo "ERROR: Must be run as root."; exit 1; fi
if [ ! -d "$LUMINOS_CHROOT_DIR" ]; then echo "ERROR: Chroot dir not found."; exit 1; fi
if [ ! -f "assets/luminos-wallpaper-default.png" ]; then echo "ERROR: Default wallpaper not found in assets."; exit 1; fi
if [ ! -f "assets/luminos-sddm-background.png" ]; then echo "ERROR: SDDM background not found in assets."; exit 1; fi

echo "====================================================="
echo "PHASE 4: Customizing Desktop and Branding"
echo "====================================================="

echo "--> Copying graphical assets into the system..."
mkdir -p "$LUMINOS_CHROOT_DIR/usr/share/wallpapers/luminos/"
cp "assets/luminos-wallpaper-default.png" "$LUMINOS_CHROOT_DIR/usr/share/wallpapers/luminos/"
cp "assets/luminos-sddm-background.png" "$LUMINOS_CHROOT_DIR/usr/share/wallpapers/luminos/"

cat > "$LUMINOS_CHROOT_DIR/tmp/customize_desktop.sh" << "EOF"
#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive
echo "--> Removing unwanted packages..."
PACKAGES_TO_REMOVE="kmahjongg kmines kpat ksnake kmail kontact akregator"
# Added --ignore-missing to prevent errors if a package is not installed
apt-get purge -y --ignore-missing $PACKAGES_TO_REMOVE
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
activityId=
formfactor=0
immutability=1
lastScreen=0
location=0
plugin=org.kde.plasma.folder
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
echo "--> Cleaning up..."
apt-get clean
rm /tmp/customize_desktop.sh
EOF

chmod +x "$LUMINOS_CHROOT_DIR/tmp/customize_desktop.sh"

echo "--> Mounting virtual filesystems for chroot..."
mount --bind /dev "$LUMINOS_CHROOT_DIR/dev"; mount --bind /dev/pts "$LUMINOS_CHROOT_DIR/dev/pts"; mount -t proc /proc "$LUMINOS_CHROOT_DIR/proc"; mount -t sysfs /sys "$LUMINOS_CHROOT_DIR/sys"

echo "--> Entering chroot to perform customization..."
chroot "$LUMINOS_CHROOT_DIR" env -i PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin /tmp/customize_desktop.sh

echo "--> Unmounting virtual filesystems..."
umount "$LUMINOS_CHROOT_DIR/sys"; umount "$LUMINOS_CHROOT_DIR/proc"; umount "$LUMINOS_CHROOT_DIR/dev/pts"; umount "$LUMINOS_CHROOT_DIR/dev"

echo ""
echo "SUCCESS: Desktop environment customized."
echo "Next step: 05-install-ai.sh"
exit 0
