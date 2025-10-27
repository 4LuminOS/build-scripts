#!/bin/bash
# ==============================================================================
# LuminOS Build Script - Phase 2: System Configuration
#
# Author: Gabriel, Project Leader @ LuminOS
# Version: 0.3.0
# ==============================================================================
set -e
LUMINOS_CHROOT_DIR="chroot"

if [ "$(id -u)" -ne 0 ]; then echo "ERROR: Must be run as root."; exit 1; fi
if [ ! -d "$LUMINOS_CHROOT_DIR" ]; then echo "ERROR: Chroot dir not found."; exit 1; fi

echo "====================================================="
echo "PHASE 2: Configuring LuminOS Base System"
echo "====================================================="

cat > "$LUMINOS_CHROOT_DIR/tmp/configure.sh" << "EOF"
#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive

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

# --- Non-Interactive Password Setting ---
echo "--> Creating live user 'liveuser'..."
useradd -m -s /bin/bash -G sudo,audio,video,netdev,plugdev liveuser

echo "--> Setting default passwords to 'luminos' for root and liveuser..."
echo "root:luminos" | chpasswd
echo "liveuser:luminos" | chpasswd

rm /tmp/configure.sh
EOF

chmod +x "$LUMINOS_CHROOT_DIR/tmp/configure.sh"

echo "--> Mounting virtual filesystems for chroot..."
mount --bind /dev "$LUMINOS_CHROOT_DIR/dev"; mount --bind /dev/pts "$LUMINOS_CHROOT_DIR/dev/pts"; mount -t proc /proc "$LUMINOS_CHROOT_DIR/proc"; mount -t sysfs /sys "$LUMINOS_CHROOT_DIR/sys"

echo "--> Entering chroot to perform configuration..."
# The PATH is now the only variable needed.
chroot "$LUMINOS_CHROOT_DIR" env -i PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin /tmp/configure.sh

echo "--> Unmounting virtual filesystems..."
umount "$LUMINOS_CHROOT_DIR/sys"; umount "$LUMINOS_CHROOT_DIR/proc"; umount "$LUMINOS_CHROOT_DIR/dev/pts"; umount "$LUMINOS_CHROOT_DIR/dev"

echo ""
echo "SUCCESS: LuminOS base system configured."
echo "Next step: 03-install-desktop.sh"
exit 0
