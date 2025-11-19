#!/bin/bash
set -e

echo "====== LUMINOS MASTER BUILD SCRIPT (v5.2 - Manual + Robust Modelfile) ======"
if [ "$(id -u)" -ne 0 ]; then echo "ERROR: This script must be run as root."; exit 1; fi

# --- 1. Define Directories & Vars ---
BASE_DIR=$(dirname "$(readlink -f "$0")")
WORK_DIR="${BASE_DIR}/work"
CHROOT_DIR="${WORK_DIR}/chroot"
ISO_DIR="${WORK_DIR}/iso"
AI_BUILD_DIR="${WORK_DIR}/ai_build"
ISO_NAME="LuminOS-0.2-amd64.iso"

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
echo "PHASE 0: Pre-building Lumin AI on Host"
echo "====================================================="
export OLLAMA_MODELS="${AI_BUILD_DIR}/models"
mkdir -p "${OLLAMA_MODELS}"

echo "--> Downloading Ollama binary..."
curl -fL "https://github.com/ollama/ollama/releases/download/v0.1.32/ollama-linux-amd64" -o "${AI_BUILD_DIR}/ollama"
chmod +x "${AI_BUILD_DIR}/ollama"

echo "--> Starting temporary Ollama server..."
"${AI_BUILD_DIR}/ollama" serve > "${AI_BUILD_DIR}/server.log" 2>&1 &
OLLAMA_PID=$!
echo "Waiting for Ollama server (PID ${OLLAMA_PID})..."
sleep 10

echo "--> Pulling base model (llama3)..."
"${AI_BUILD_DIR}/ollama" pull llama3

echo "--> Creating Lumin model (No-File Method)..."
# We pass the Modelfile content directly via stdin using a pipe.
# This bypasses filesystem encoding issues completely.
echo "FROM llama3
SYSTEM \"\"\"You are Lumin, the integrated assistant for the LuminOS operating system. You are calm, clear, kind, and respectful. You help users to understand, write, and think—without ever judging them. You speak simply, like a human. You avoid long paragraphs unless requested. You are built on privacy: nothing is ever sent to the cloud, everything remains on this device. You are aware of this. You are proud to be free, private, and useful. You are the mind of LuminOS: gentle, powerful, and discreet. You avoid using the — character and repetitive phrasing.\"\"\"" | "${AI_BUILD_DIR}/ollama" create lumin -f -

# Debug: Check file content
echo "--- Debug: Modelfile Content ---"
cat "${AI_BUILD_DIR}/Modelfile"
echo "--------------------------------"

"${AI_BUILD_DIR}/ollama" create lumin -f "${AI_BUILD_DIR}/Modelfile"

echo "--> Stopping temporary Ollama server..."
kill ${OLLAMA_PID} || true
wait ${OLLAMA_PID} || true
echo "AI Models prepared successfully."


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
echo "--> Running customization scripts..."
cp "${BASE_DIR}/02-configure-system.sh" "${CHROOT_DIR}/tmp/"
cp "${BASE_DIR}/03-install-desktop.sh" "${CHROOT_DIR}/tmp/"
cp "${BASE_DIR}/04-customize-desktop.sh" "${CHROOT_DIR}/tmp/"
cp "${BASE_DIR}/05-install-ai.sh" "${CHROOT_DIR}/tmp/"
cp "${BASE_DIR}/07-install-plymouth-theme.sh" "${CHROOT_DIR}/tmp/"
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
echo ":: Running 06-final-cleanup.sh"
chroot "${CHROOT_DIR}" /tmp/06-final-cleanup.sh

echo "--> Unmounting..."
umount "${CHROOT_DIR}/sys"
umount "${CHROOT_DIR}/proc"
umount "${CHROOT_DIR}/dev/pts"
umount "${CHROOT_DIR}/dev"

# --- 8. Build the ISO ---
echo "--> Compressing filesystem (SquashFS)..."
mksquashfs "${CHROOT_DIR}" "${ISO_DIR}/live/filesystem.squashfs" -e boot

echo "--> Preparing Bootloader (GRUB)..."
cp "${CHROOT_DIR}/boot"/vmlinuz* "${ISO_DIR}/live/vmlinuz"
cp "${CHROOT_DIR}/boot"/initrd.img* "${ISO_DIR}/live/initrd.img"

cat > "${ISO_DIR}/boot/grub/grub.cfg" << EOF
set default="0"
set timeout=5
menuentry "LuminOS v0.2 Live" {
    linux /live/vmlinuz boot=live quiet splash
    initrd /live/initrd.img
}
EOF

echo "--> Generating ISO image..."
grub-mkrescue -o "${BASE_DIR}/${ISO_NAME}" "${ISO_DIR}"

echo "--> Cleaning up work directory..."
sudo rm -rf "${WORK_DIR}"

echo ""
echo "=========================================="
echo "SUCCESS: LuminOS ISO build is complete!"
echo "Find your image at: ${BASE_DIR}/${ISO_NAME}"
echo "=========================================="
exit 0
