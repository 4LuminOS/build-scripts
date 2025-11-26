#!/bin/bash
set -e

echo "===== LUMINOS MASTER BUILD SCRIPT (v5.7 - With Software Pack) ====="
if [ "$(id -u)" -ne 0 ]; then echo "ERROR: This script must be run as root."; exit 1; fi

# --- 1. Define Directories & Vars ---
BASE_DIR=$(dirname "$(readlink -f "$0")")
WORK_DIR="${BASE_DIR}/work"
CHROOT_DIR="${WORK_DIR}/chroot"
ISO_DIR="${WORK_DIR}/iso"
AI_BUILD_DIR="${WORK_DIR}/ai_build"
ISO_NAME="LuminOS-0.2.1-amd64.iso" # Updated version number

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
echo "PHASE 0: Pre-downloading AI Models"
echo "====================================================="
export OLLAMA_MODELS="${AI_BUILD_DIR}/models"
mkdir -p "${OLLAMA_MODELS}"

echo "--> Downloading Ollama binary..."
curl -fL "https://github.com/ollama/ollama/releases/download/v0.1.32/ollama-linux-amd64" -o "${AI_BUILD_DIR}/ollama"
chmod +x "${AI_BUILD_DIR}/ollama"

echo "--> Starting temporary Ollama server..."
OLLAMA_MODELS="${OLLAMA_MODELS}" "${AI_BUILD_DIR}/ollama" serve > "${AI_BUILD_DIR}/server.log" 2>&1 &
OLLAMA_PID=$!
echo "Waiting for Ollama server (PID ${OLLAMA_PID})..."
sleep 10

echo "--> Pulling base model (llama3)..."
OLLAMA_MODELS="${OLLAMA_MODELS}" "${AI_BUILD_DIR}/ollama" pull llama3

echo "--> Stopping temporary Ollama server..."
kill ${OLLAMA_PID} || true
wait ${OLLAMA_PID} || true

SIZE_CHECK=$(du -s "${OLLAMA_MODELS}" | cut -f1)
if [ "$SIZE_CHECK" -lt 4000000 ]; then
    echo "ERROR: Model download failed or is too small ($SIZE_CHECK KB)."
    exit 1
else
    echo "SUCCESS: AI Models downloaded (${SIZE_CHECK} KB)."
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
mkdir -p "${CHROOT_DIR}/usr/share/ollama/.ollama"
cp -r "${AI_BUILD_DIR}/models" "${CHROOT_DIR}/usr/share/ollama/.ollama/"


# --- 7. Run Customization Scripts ---
echo "--> Running customization
