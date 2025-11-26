#!/bin/bash
set -e

echo "====== LUMINOS MASTER BUILD SCRIPT (v6.2 - Model Cleaner) ======"
if [ "$(id -u)" -ne 0 ]; then echo "ERROR: This script must be run as root."; exit 1; fi

# --- 1. Define Directories & Vars ---
BASE_DIR=$(dirname "$(readlink -f "$0")")
WORK_DIR="${BASE_DIR}/work"
CHROOT_DIR="${WORK_DIR}/chroot"
ISO_DIR="${WORK_DIR}/iso"
AI_BUILD_DIR="${WORK_DIR}/ai_build"
ISO_NAME="LuminOS-0.2.1-amd64.iso"
REQUIRED_MODEL="llama3"

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

# --- 4. PREPARE AI (Smart & Clean) ---
echo "====================================================="
echo "PHASE 0: Preparing AI Models"
echo "====================================================="
TARGET_MODEL_DIR="${AI_BUILD_DIR}/models"
mkdir -p "${TARGET_MODEL_DIR}"

# Detect User Home
REAL_USER="${SUDO_USER:-$USER}"
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

POSSIBLE_LOCATIONS=(
    "${USER_HOME}/.ollama/models"
    "/usr/share/ollama/.ollama/models"
    "/var/lib/ollama/.ollama/models"
    "/root/.ollama/models"
)

MODEL_FOUND=false

# Strategy A: Copy existing models (Draft)
for LOC in "${POSSIBLE_LOCATIONS[@]}"; do
    if [ -d "$LOC" ]; then
        SIZE_CHECK=$(du -s "$LOC" | cut -f1)
        if [ "$SIZE_CHECK" -gt 1000000 ]; then
            echo "INFO: Found models at $LOC. Copying to temp dir..."
            cp -r "${LOC}/." "${TARGET_MODEL_DIR}/"
            MODEL_FOUND=true
            break
        fi
    fi
done

echo "--> Downloading Ollama binary..."
curl -fL "https://github.com/ollama/ollama/releases/download/v0.1.32/ollama-linux-amd64" -o "${AI_BUILD_DIR}/ollama"
chmod +x "${AI_BUILD_DIR}/ollama"

# Start Temp Server (Used for both downloading AND cleaning)
export OLLAMA_MODELS="${TARGET_MODEL_DIR}"
export HOME="${AI_BUILD_DIR}" # Redirect home to keep things clean

echo "--> Starting temporary Ollama server to manage models..."
"${AI_BUILD_DIR}/ollama" serve > "${AI_BUILD_DIR}/server.log" 2>&1 &
OLLAMA_PID=$!
echo "Waiting 10s for server..."
sleep 10

# Strategy B: Download if missing
if [ "$MODEL_FOUND" = false ]; then
    echo "--> Model not found locally. Downloading ${REQUIRED_MODEL}..."
    "${AI_BUILD_DIR}/ollama" pull ${REQUIRED_MODEL}
else
    # Check if the specific required model is actually there
    if ! "${AI_BUILD_DIR}/ollama" list | grep -q "${REQUIRED_MODEL}"; then
        echo "--> Local cache found, but ${REQUIRED_MODEL} is missing. Downloading..."
        "${AI_BUILD_DIR}/ollama" pull ${REQUIRED_MODEL}
    fi
fi

# --- CLEANUP STEP (New in v6.2) ---
echo "--> Cleaning up extraneous models to save ISO space..."
# List all models, filter out the required one, and remove the rest
EXISTING_MODELS=$("${AI_BUILD_DIR}/ollama" list | awk 'NR>1 {print $1}')

for model in $EXISTING_MODELS; do
    # Check if model matches required (allowing for :latest tag)
    if [[ "$model" != "${REQUIRED_MODEL}" && "$model" != "${REQUIRED_MODEL}:latest" ]]; then
        echo "--> Removing unused model from ISO build: $model"
        "${AI_BUILD_DIR}/ollama" rm "$model"
    else
        echo "--> Keeping core model: $model"
    fi
done
# ----------------------------------

echo "--> Stopping temporary Ollama server..."
kill ${OLLAMA_PID} || true
wait ${OLLAMA_PID} || true


# Final Verification
SIZE_CHECK=$(du -s "${TARGET_MODEL_DIR}" | cut -f1)
if [ "$SIZE_CHECK" -lt 1000000 ]; then
    echo "ERROR: Model preparation failed. Target directory is too small ($SIZE_CHECK KB)."
    exit 1
else
    echo "SUCCESS: AI Models prepared and cleaned (${SIZE_CHECK} KB)."
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

# --- 6. Apply Fixes & Prepare Environment ---
echo "--> Applying APT fixes..."
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

echo "--> Injecting AI files into system..."
cp "${AI_BUILD_DIR}/ollama" "${CHROOT_DIR}/usr/local/bin/"
# Create the directory structure exactly as Ollama expects
mkdir -p "${CHROOT_DIR}/usr/share/ollama/.ollama"
# Copy the cleaned models
cp -r "${TARGET_MODEL_DIR}" "${CHROOT_DIR}/usr/share/ollama/.ollama/"
echo "--> AI Injection Complete."


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

echo ":: Running 02-configure-system.sh"
chroot "${CHROOT_DIR}" /tmp/02-configure-system.sh
echo ":: Running 03-install-desktop.sh"
chroot "${CHROOT_DIR}" /tmp/03-install-desktop.sh
echo ":: Running 04-customize-desktop.sh"
chroot "${CHROOT_DIR}" /tmp/04-customize-desktop.sh
echo ":: Running 05-install-ai.sh"
chroot "${CHROOT_DIR}" /tmp/05-install-ai.sh
echo ":: Running 07-install-plymouth-theme.sh"
chroot "${CHROOT_DIR}" /tmp/07-install-plymouth-theme.sh
echo ":: Running 08-install-software.sh"
chroot "${CHROOT_DIR}" /tmp/08-install-software.sh
echo ":: Running 06-final-cleanup.sh"
chroot "${CHROOT_DIR}" /tmp/06-final-cleanup.sh

echo "--> Unmounting..."
umount "${CHROOT_DIR}/sys"
umount "${CHROOT_DIR}/proc"
umount "${CHROOT_DIR}/dev/pts"
umount "${CHROOT_DIR}/dev"

# --- 8. Build the ISO ---
echo "--> Compressing filesystem (SquashFS)..."
mksquashfs "${CHROOT_DIR}" "${ISO_DIR}/live/filesystem.squashfs" -e boot -comp zstd

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
    echo "ERROR: Build finished but ISO file not found."
    exit 1
fi
echo "========================================="
exit 0
