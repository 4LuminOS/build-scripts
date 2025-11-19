#!/bin/bash
set -e

echo "===== LUMINOS MASTER BUILD SCRIPT (v4.4) ====="
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

# --- 4. Prepare Hooks and Assets ---
HOOK_DIR="${LB_CONFIG_DIR}/config/hooks/chroot"
echo "--> Preparing build hooks in ${HOOK_DIR}"
mkdir -p "${HOOK_DIR}"

cp "${BASE_DIR}/02-configure-system.sh" "${HOOK_DIR}/0200_configure-system.hook.chroot"
cp "${BASE_DIR}/03-install-desktop.sh" "${HOOK_DIR}/0300_install-desktop.hook.chroot"
cp "${BASE_DIR}/04-customize-desktop.sh" "${HOOK_DIR}/0400_customize-desktop.hook.chroot"
cp "${BASE_DIR}/05-install-ai.sh" "${HOOK_DIR}/0500_install-ai.hook.chroot"
cp "${BASE_DIR}/07-install-plymouth-theme.sh" "${HOOK_DIR}/0700_install-plymouth.hook.chroot"
cp "${BASE_DIR}/06-final-cleanup.sh" "${HOOK_DIR}/9999_final-cleanup.hook.chroot"

# Prepare Assets (Wallpaper)
ASSET_DIR="${LB_CONFIG_DIR}/config/includes.chroot/usr/share/wallpapers/luminos"
mkdir -p "${ASSET_DIR}"
cp "${BASE_DIR}/assets/"* "${ASSET_DIR}/"

# --- 5. APPLY APT FIX (The "Nuclear" Option) ---
# We inject the config file directly into the OS filesystem structure.
# This ensures apt sees it regardless of live-build's internal logic.
APT_CONF_DIR="${LB_CONFIG_DIR}/config/includes.chroot/etc/apt/apt.conf.d"
echo "--> Injecting strict APT configuration into ${APT_CONF_DIR}"
mkdir -p "${APT_CONF_DIR}"
cat > "${APT_CONF_DIR}/99-no-contents" << EOF
Acquire::IndexTargets::deb::Contents-deb "false";
Acquire::IndexTargets::deb-src::Contents-src "false";
EOF

# --- 6. Configure Live-Build ---
echo "--> Configuring live-build..."
DEBIAN_MIRROR="http://deb.debian.org/debian/"
SECURITY_MIRROR="http://security.debian.org/ trixie-security main contrib non-free-firmware"

# Enter config directory
cd "${LB_CONFIG_DIR}"

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
    --apt-indices false \
    --apt-options '--yes -o "Acquire::IndexTargets::deb::Contents-deb=false" -o "Acquire::IndexTargets::deb::src::Contents-src=false"' \
    "${@}"

# --- 7. Run the Build ---
echo "--> Building the ISO..."
sudo lb build

# --- 8. Finalize ---
cd "${BASE_DIR}"
echo "--> Moving final ISO..."
if [ -f "${LB_CONFIG_DIR}/live-image-amd64.iso" ]; then
    mv "${LB_CONFIG_DIR}/live-image-amd64.iso" "${BASE_DIR}/LuminOS-0.2-amd64.iso"
elif [ -f "${BASE_DIR}/live-image-amd64.iso" ]; then
    mv "${BASE_DIR}/live-image-amd64.iso" "${BASE_DIR}/LuminOS-0.2-amd64.iso"
fi

echo "--> Cleaning up..."
sudo rm -rf "${LB_CONFIG_DIR}"

echo ""
echo "========================================="
if [ -f "${BASE_DIR}/LuminOS-0.2-amd64.iso" ]; then
    echo "SUCCESS: LuminOS ISO build is complete!"
    echo "Find your image at: ${BASE_DIR}/LuminOS-0.2-amd64.iso"
else
    echo "ERROR: Build finished but ISO file not found."
    exit 1
fi
echo "========================================="
exit 0
