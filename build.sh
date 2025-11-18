#!/bin/bash
set -e

echo "===== LUMINOS MASTER BUILD SCRIPT (v4.3) ====="
if [ "$(id -u)" -ne 0 ]; then echo "ERROR: This script must be run as root."; exit 1; fi

# --- 1. Define Directories ---
BASE_DIR=$(dirname "$(readlink -f "$0")")
LB_CONFIG_DIR="${BASE_DIR}/live-build-config"

# --- 2. Clean Up ---
echo "--> Cleaning up previous build artifacts..."
sudo umount "${LB_CONFIG_DIR}/chroot/sys" &>/dev/null || true
sudo umount "${LB_CONFIG_DIR}/chroot/proc" &>/dev/null || true
sudo umount "${LB_CONFIG_DIR}/chroot/dev/pts" &>/dev/null || true
sudo umount "${LB_CONFIG_DIR}/chroot/dev" &>/dev/null || true
sudo rm -rf "${LB_CONFIG_DIR}"
sudo rm -rf "${BASE_DIR}/chroot"
sudo rm -f "${BASE_DIR}"/*.iso

mkdir -p "${LB_CONFIG_DIR}"

# --- 3. Install Dependencies ---
echo "--> Installing build dependencies..."
apt-get update
apt-get install -y live-build debootstrap debian-archive-keyring plymouth curl rsync

# --- 4. Configure Live-Build ---
echo "--> Configuring live-build..."
cd "${LB_CONFIG_DIR}"

DEBIAN_MIRROR="http://deb.debian.org/debian/"
SECURITY_MIRROR="http://security.debian.org/ trixie-security main contrib non-free-firmware"

lb config \
    --mode debian \
    --architectures amd64 \
    --distribution trixie \
    --archive-areas "main contrib non-free-firmware" \
    --security false \
    --mirror-bootstrap "${DEBIAN_MIRROR}" \
    --mirror-chroot "${DEBIAN_MIRROR} | ${SECURITY_MIRROR}" \
    --mirror-binary "${DEBIAN_MIRROR} | ${SECURITY_MIRROR}" \
    --bootappend-live "boot=live components locales=en_US.UTF-8" \
    --iso-application "LuminOS" \
    --iso-publisher "LuminOS Project" \
    --iso-volume "LuminOS 0.2" \
    --memtest none \
    --debian-installer false \
    "${@}"

# --- 5. Apply Fixes & Prepare Assets ---

# FIX: Manually create apt configuration to ignore Contents files (Fixes 404/gzip error)
echo "--> Applying APT configuration fix..."
mkdir -p config/apt
cat > config/apt/apt.conf << EOF
Acquire::IndexTargets::deb::Contents-deb "false";
Acquire::IndexTargets::deb-src::Contents-src "false";
EOF

# Prepare Hooks
HOOK_DIR="${LB_CONFIG_DIR}/config/hooks/chroot"
echo "--> Preparing build hooks in ${HOOK_DIR}"
mkdir -p "${HOOK_DIR}"

cp "${BASE_DIR}/02-configure-system.sh" "${HOOK_DIR}/0200_configure-system.hook.chroot"
cp "${BASE_DIR}/03-install-desktop.sh" "${HOOK_DIR}/0300_install-desktop.hook.chroot"
cp "${BASE_DIR}/04-customize-desktop.sh" "${HOOK_DIR}/0400_customize-desktop.hook.chroot"
cp "${BASE_DIR}/05-install-ai.sh" "${HOOK_DIR}/0500_install-ai.hook.chroot"
cp "${BASE_DIR}/07-install-plymouth-theme.sh" "${HOOK_DIR}/0700_install-plymouth.hook.chroot"
cp "${BASE_DIR}/06-final-cleanup.sh" "${HOOK_DIR}/9999_final-cleanup.hook.chroot"

# Prepare Assets
ASSET_DIR="${LB_CONFIG_DIR}/config/includes.chroot/usr/share/wallpapers/luminos"
echo "--> Preparing assets in ${ASSET_DIR}"
mkdir -p "${ASSET_DIR}"
cp "${BASE_DIR}/assets/"* "${ASSET_DIR}/"

# --- 6. Run the Build ---
echo "--> Building the ISO..."
sudo lb build

# --- 7. Finalize ---
# Go back to base dir
cd "${BASE_DIR}"

echo "--> Checking for ISO..."
if [ -f "${LB_CONFIG_DIR}/live-image-amd64.iso" ]; then
    echo "--> Moving ISO to project root..."
    mv "${LB_CONFIG_DIR}/live-image-amd64.iso" "${BASE_DIR}/LuminOS-0.2-amd64.iso"
    echo "--> Cleaning up build directory..."
    sudo rm -rf "${LB_CONFIG_DIR}"
    echo ""
    echo "========================================="
    echo "SUCCESS: LuminOS ISO build is complete!"
    echo "Find your image at: ${BASE_DIR}/LuminOS-0.2-amd64.iso"
    echo "========================================="
    exit 0
else
    echo "ERROR: Build finished but ISO file not found in ${LB_CONFIG_DIR}"
    exit 1
fi
