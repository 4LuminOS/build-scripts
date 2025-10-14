#!/bin/bash

# ==============================================================================
# LuminOS Build Script - Phase 2: System Configuration
#
# Description: This script configures the base Debian system created in Phase 1.
#              It sets hostname, APT, passwords (interactively or not),
#              the live user, and timezone/locale.
#
# Author: Gabriel, Project Leader @ LuminOS
# Version: 0.2.0
# ==============================================================================

# --- Configuration ---
set -e

# --- Variables ---
LUMINOS_CHROOT_DIR="chroot"

# --- Pre-flight Checks ---
if [ "$(id -u)" -ne 0 ]; then echo "ERROR: Must be run as root."; exit 1; fi
if [ ! -d "$LUMINOS_CHROOT_DIR" ]; then echo "ERROR: Chroot dir not found."; exit 1; fi

# --- Main Logic ---
echo "====================================================="
echo "PHASE 2: Configuring LuminOS Base System"
echo "====================================================="

# Create the script to be run inside the chroot
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

# --- Password Management ---
# Check for the CI environment variable for non-interactive mode
if [ "$CI" = "true" ]; then
    echo "--> CI environment detected. Setting dummy passwords..."
    # Use chpasswd for non-interactive password setting
    echo "root:luminos-ci" | chpasswd
    useradd -m -s /bin/bash -G sudo,audio,video,netdev,plugdev liveuser
    echo "liveuser:luminos-ci" | chpasswd
else
    echo "--> Setting root password (interactive)..."
    passwd root
    echo "--> Creating live user 'liveuser' (interactive)..."
    useradd -m -s /bin/bash -G sudo,audio,video,netdev,plugdev liveuser
    echo "--> Setting password for 'liveuser' (interactive)..."
    passwd liveuser
fi

# Clean up
rm /tmp/configure.sh
EOF

chmod +x "$LUMINOS_CHROOT_DIR/tmp/configure.sh"
echo "--> Entering chroot to perform configuration..."
# Pass the CI variable into the chroot environment
chroot "$LUMINOS_CHROOT_DIR" env -i CI="$CI" /tmp/configure.sh

echo ""
echo "Yayy: LuminOS base system configured!"
echo "Next step: 03-install-kernel-and-desktop.sh"

exit 0
