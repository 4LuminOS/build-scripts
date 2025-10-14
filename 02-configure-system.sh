#!/bin/bash

# ==============================================================================
# LuminOS Build Script - Phase 2: System Configuration
#
# Description: This script configures the base Debian system created in "Phase 1"
#              It sets the hostname, configures APT, sets passwords,
#              creates the live user and and sets timezone/locale.
#
# Author: Gabriel, Project Leader @ LuminOS
# Version: 0.1.0
# ==============================================================================

# --- Configuration ---
set -e

# --- Variables ---
LUMINOS_CHROOT_DIR="chroot"

# --- Pre-flight Checks ---
if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: This script must be run as root (or with sudo)."
    exit 1
fi
if [ ! -d "$LUMINOS_CHROOT_DIR" ]; then
    echo "ERROR: The chroot directory '$LUMINOS_CHROOT_DIR' does not exist."
    echo "Please run 01-build-base-system.sh first."
    exit 1
fi

# --- Main Logic ---
echo "====================================================="
echo "PHASE 2: Configuring LuminOS Base System"
echo "====================================================="

cat > "$LUMINOS_CHROOT_DIR/tmp/configure.sh" << "EOF"
#!/bin/bash
set -e
echo "--> Configuring APT sources..."
cat > /etc/apt/sources.list << "SOURCES"
deb http://deb.debian.org/debian trixie main contrib non-free-firmware
deb-src http://deb.debian.org/debian trixie main contrib non-free-firmware
deb http://security.debian.org/debian-security trixie-security main contrib non-free-firmware
deb-src http://security.debian.org/debian-security trixie-security main contrib non-free-firmware
deb http://deb.debian.org/debian trixie-updates main contrib non-free-firmware
deb-src http://deb.debian.org/debian trixie-updates main contrib non-free-firmware
SOURCES
echo "--> Updating package lists and upgrading system..."
apt-get update
apt-get -y upgrade
echo "--> Setting hostname to LuminOS..."
echo "LuminOS" > /etc/hostname
echo "--> Setting timezone to Europe/Zurich..."
ln -sf /usr/share/zoneinfo/Europe/Zurich /etc/localtime
echo "--> Configuring locales..."
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
update-locale LANG="en_US.UTF-8"
echo "--> Setting root password..."
passwd root
echo "--> Creating live user 'liveuser'..."
useradd -m -s /bin/bash -G sudo,audio,video,netdev,plugdev liveuser
echo "--> Setting password for 'liveuser'..."
passwd liveuser
rm /tmp/configure.sh
EOF

chmod +x "$LUMINOS_CHROOT_DIR/tmp/configure.sh"
echo "--> Entering chroot to perform configuration..."
chroot "$LUMINOS_CHROOT_DIR" /tmp/configure.sh
echo ""
echo "SUCCESS: LuminOS base system configured."
echo "Next step: 03-install-kernel-and-desktop.sh"
exit 0
