#!/bin/bash
set -e

echo "====== LUMINOS MASTER BUILD SCRIPT (v7.1 - Multi-Layer AI) ======"
if [ "$(id -u)" -ne 0 ]; then echo "ERROR: This script must be run as root."; exit 1; fi

# --- 1. Define Directories & Vars ---
BASE_DIR=$(dirname "$(readlink -f "$0")")
WORK_DIR="${BASE_DIR}/work"
CHROOT_DIR="${WORK_DIR}/chroot"
ISO_DIR="${WORK_DIR}/iso"
AI_BUILD_DIR="${WORK_DIR}/ai_build"
ISO_NAME="LuminOS-0.2.1-amd64.iso"

# --- 2. Clean Up ---
echo "--> Cleaning up previous build artifacts..."
sudo umount "${CHROOT_DIR}/sys" &>/dev/null || true
sudo umount "${CHROOT_DIR}/proc" &>/dev/null || true
sudo umount "${CHROOT_DIR}/dev/pts" &>/dev/null || true
sudo umount "${CHROOT_DIR}/dev" &>/dev/null || true
pkill -f "ollama serve" || true
sudo rm -rf "${WORK_DIR}"
sudo rm -f "${BASE_DIR}/${ISO_NAME}"

mkdir -p "${CHROOT_DIR}"
mkdir -p "${ISO_DIR}/live"
mkdir -p "${ISO_DIR}/boot/grub"
mkdir -p "${AI_BUILD_DIR}"

# --- 3. Install Dependencies ---
echo "--> Installing build dependencies..."
apt-get update
apt-get install -y debootstrap squashfs-tools xorriso grub-pc-bin grub-efi-amd64-bin mtools curl rsync

# --- 4. PREPARE AI (ON HOST) ---
echo "====================================================="
echo "PHASE 0: Preparing AI Models"
echo "====================================================="
TARGET_MODEL_DIR="${AI_BUILD_DIR}/models"
mkdir -p "${TARGET_MODEL_DIR}"

REAL_USER="${SUDO_USER:-$USER}"
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

# Search existing models
MODEL_FOUND=false
POSSIBLE_LOCATIONS=("${USER_HOME}/.ollama/models" "/root/.ollama/models" "/usr/share/ollama/.ollama/models")

for LOC in "${POSSIBLE_LOCATIONS[@]}"; do
    if [ -d "$LOC" ]; then
        SIZE_CHECK=$(du -s "$LOC" | cut -f1)
        if [ "$SIZE_CHECK" -gt 1000000 ]; then
            echo "SUCCESS: Found models at $LOC! Copying..."
            cp -r "${LOC}/." "${TARGET_MODEL_DIR}/"
            MODEL_FOUND=true
            break
        fi
    fi
done

# Download if not found
if [ "$MODEL_FOUND" = false ]; then
    echo "--> Model not found locally. Downloading..."
    curl -fL "https://github.com/ollama/ollama/releases/download/v0.1.32/ollama-linux-amd64" -o "${AI_BUILD_DIR}/ollama"
    chmod +x "${AI_BUILD_DIR}/ollama"
    export HOME="${AI_BUILD_DIR}"
    "${AI_BUILD_DIR}/ollama" serve > "${AI_BUILD_DIR}/server.log" 2>&1 &
    OLLAMA_PID=$!
    echo "Waiting 10s for server..."
    sleep 10
    "${AI_BUILD_DIR}/ollama" pull llama3
    kill ${OLLAMA_PID} || true
    if [ -d "${AI_BUILD_DIR}/.ollama/models" ]; then
        cp -r "${AI_BUILD_DIR}/.ollama/models/." "${TARGET_MODEL_DIR}/"
    fi
fi

# --- 5. Bootstrap Base System ---
echo "--> Bootstrapping Debian base..."
debootstrap \
    --arch=amd64 \
    --components=main,contrib,non-free-firmware \
    --include=linux-image-amd64,live-boot,systemd-sysv \
    trixie \
    "${CHROOT_DIR}" \
    http://ftp.debian.org/debian/

# --- 6. Apply Fixes & Environment ---
mkdir -p "${CHROOT_DIR}/etc/apt/apt.conf.d"
cat > "${CHROOT_DIR}/etc/apt/apt.conf.d/99-no-contents" << EOF
Acquire::IndexTargets::deb::Contents-deb "false";
Acquire::IndexTargets::deb-src::Contents-src "false";
EOF

echo "--> Mounting virtual filesystems..."
mount --bind /dev "${CHROOT_DIR}/dev"
mount --bind /dev/pts "${CHROOT_DIR}/dev/pts"
mount -t proc /proc "${CHROOT_DIR}/proc"
mount -t sysfs /sys "${CHROOT_DIR}/sys"

echo "--> Copying assets..."
mkdir -p "${CHROOT_DIR}/usr/share/wallpapers/luminos"
cp "${BASE_DIR}/assets/"* "${CHROOT_DIR}/usr/share/wallpapers/luminos/"

echo "--> Injecting AI Binary..."
if [ ! -f "${AI_BUILD_DIR}/ollama" ]; then
    curl -fL "https://github.com/ollama/ollama/releases/download/v0.1.32/ollama-linux-amd64" -o "${AI_BUILD_DIR}/ollama"
    chmod +x "${AI_BUILD_DIR}/ollama"
fi
cp "${AI_BUILD_DIR}/ollama" "${CHROOT_DIR}/usr/local/bin/"

# --- 7. Run Customization Scripts ---
echo "--> Running customization scripts..."
cp "${BASE_DIR}/02-configure-system.sh" "${CHROOT_DIR}/tmp/"
cp "${BASE_DIR}/03-install-desktop.sh" "${CHROOT_DIR}/tmp/"
cp "${BASE_DIR}/04-customize-desktop.sh" "${CHROOT_DIR}/tmp/"
cp "${BASE_DIR}/05-install-ai.sh" "${CHROOT_DIR}/tmp/"
cp "${BASE_DIR}/07-install-plymouth-theme.sh" "${CHROOT_DIR}/tmp/"
cp "${BASE_DIR}/08-install-software.sh" "${CHROOT_DIR}/tmp/"
cp "${BASE_DIR}/06-final-cleanup.sh" "${CHROOT_DIR}/tmp/"

chmod +x "${CHROOT_DIR}/tmp/"*.sh

echo ":: Running scripts..."
chroot "${CHROOT_DIR}" /tmp/02-configure-system.sh
chroot "${CHROOT_DIR}" /tmp/03-install-desktop.sh
chroot "${CHROOT_DIR}" /tmp/04-customize-desktop.sh
chroot "${CHROOT_DIR}" /tmp/05-install-ai.sh
chroot "${CHROOT_DIR}" /tmp/07-install-plymouth-theme.sh
chroot "${CHROOT_DIR}" /tmp/08-install-software.sh
chroot "${CHROOT_DIR}" /tmp/06-final-cleanup.sh

echo "--> Unmounting..."
umount "${CHROOT_DIR}/sys"
umount "${CHROOT_DIR}/proc"
umount "${CHROOT_DIR}/dev/pts"
umount "${CHROOT_DIR}/dev"

# --- 8. Build the ISO (Multi-Layer Strategy) ---

# Layer 1: Main OS (Base + Desktop + Apps)
# We EXCLUDE the heavy AI models path here
echo "--> Compressing Layer 1: Main OS..."
mksquashfs "${CHROOT_DIR}" "${ISO_DIR}/live/01-filesystem.squashfs" -e boot -e usr/share/ollama/.ollama -comp zstd

# Layer 2 & 3: AI Models (Split into chunks < 4GB)
echo "--> Preparing AI Layers (Splitting models)..."

# Prepare temporary folders for layers
AI_LAYER_1="${WORK_DIR}/ai_layer_1"
AI_LAYER_2="${WORK_DIR}/ai_layer_2"
mkdir -p "${AI_LAYER_1}/usr/share/ollama/.ollama"
mkdir -p "${AI_LAYER_2}/usr/share/ollama/.ollama"

# Copy all models to Layer 1 first
cp -r "${TARGET_MODEL_DIR}/." "${AI_LAYER_1}/usr/share/ollama/.ollama/"

# Move the heavy "blobs" folder to Layer 2 to balance size?
# Better strategy: Move half of the blobs to Layer 2.
BLOB_DIR_1="${AI_LAYER_1}/usr/share/ollama/.ollama/blobs"
BLOB_DIR_2="${AI_LAYER_2}/usr/share/ollama/.ollama/blobs"
mkdir -p "${BLOB_DIR_2}"

echo "--> Distributing AI blobs across layers..."
# Move roughly half the blobs to the second layer
count=0
for file in "${BLOB_DIR_1}"/*; do
    if [ -f "$file" ]; then
        if (( count % 2 == 0 )); then
            mv "$file" "${BLOB_DIR_2}/"
        fi
        ((count++))
    fi
done

echo "--> Compressing Layer 2: AI Part A..."
mksquashfs "${AI_LAYER_1}" "${ISO_DIR}/live/02-ai-part-a.squashfs" -comp zstd

echo "--> Compressing Layer 3: AI Part B..."
mksquashfs "${AI_LAYER_2}" "${ISO_DIR}/live/03-ai-part-b.squashfs" -comp zstd

echo "--> Preparing Bootloader (GRUB)..."
cp "${CHROOT_DIR}/boot"/vmlinuz* "${ISO_DIR}/live/vmlinuz"
cp "${CHROOT_DIR}/boot"/initrd.img* "${ISO_DIR}/live/initrd.img"

cat > "${ISO_DIR}/boot/grub/grub.cfg" << EOF
set default="0"
set timeout=5
menuentry "LuminOS v0.2.1 Live" {
    linux /live/vmlinuz boot=live quiet splash
    initrd /live/initrd.img
}
EOF

echo "--> Generating ISO image..."
# No special flags needed now, individual squashfs files are small!
grub-mkrescue -o "${BASE_DIR}/${ISO_NAME}" "${ISO_DIR}"

echo "--> Cleaning up work directory..."
sudo rm -rf "${WORK_DIR}"

echo ""
echo "========================================="
if [ -f "${BASE_DIR}/${ISO_NAME}" ]; then
    echo "SUCCESS: LuminOS ISO build is complete!"
    echo "Find your image at: ${BASE_DIR}/${ISO_NAME}"
    ISO_SIZE=$(du -h "${BASE_DIR}/${ISO_NAME}" | cut -f1)
    echo "ISO Size: $ISO_SIZE"
else
    echo "ERROR: Build finished but ISO file... not found?!"
    exit 1
fi
echo "========================================="
exit 0
