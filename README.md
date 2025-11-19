# LuminOS Build Scripts 
19.11.2025

[![Build Status](https://img.shields.io/badge/build-passing-brightgreen)]()

Welcome to the official build repository for **LuminOS**.

**LuminOS** is a lightweight, private, and intelligent Linux distribution based on Debian "Trixie". It features native integration of **Lumin**, a local, offline, and ethical AI assistant. By running this script, you will obtain the first version of LuminOS in the form of an .ISO file. Please note that this version of LuminOS is an alpha version and may not be stable and/or not contain all the features mentioned.

---

## 🏗️ Build Architecture (v0.2)

We utilize a **transparent, manual build process** (bypassing the complexity of `live-build` wrappers) to ensure maximum stability and customization.

The master script `build.sh` orchestrates the entire pipeline:
1.  **AI Preparation:** Downloads Ollama and the Llama 3 model on the host to avoid chroot network issues.
2.  **Bootstrap:** Creates a pristine Debian base system using `debootstrap`.
3.  **Injection:** Copies scripts, assets, and the pre-downloaded AI models into the system.
4.  **Customization (Chroot):** Installs the Kernel, KDE Plasma, LuminOS Theme, and configures Lumin (the AI).
5.  **Assembly:** Compresses the filesystem (`SquashFS`) and generates a Hybrid ISO (BIOS/UEFI) using `grub-mkrescue`.

## 🚀 Prerequisites

To build LuminOS, you need a host machine running **Ubuntu 24.04 LTS** or **Debian 12+**.

* **Disk Space:** ~30 GB free.
* **RAM:** 8 GB minimum recommended.
* **Internet:** Required to download packages and the AI model (~5 GB).
* **Privileges:** `sudo` access is required.

The script automatically installs the necessary dependencies:
`debootstrap`, `squashfs-tools`, `xorriso`, `grub-pc-bin`, `grub-efi-amd64-bin`, `mtools`, `curl`, `rsync`.

## 🛠️ Build Instructions

1.  **Clone the repository:**
    ```bash
    git clone [https://github.com/4LuminOS/build-scripts.git](https://github.com/4LuminOS/build-scripts.git)
    cd build-scripts
    ```

2.  **Run the build:**
    ```bash
    sudo ./build.sh
    ```

3.  **Retrieve the ISO:**
    Once completed (30 to 60 minutes depending on connection), the final image will be located here:
    `LuminOS-0.2-amd64.iso`

## 🤖 About Lumin (AI)

LuminOS v0.2 features a 100% local AI integration.
* **Model:** Based on Llama 3 (may change to a newer version in futur releases)
* **Privacy:** No data ever leaves your machine.
* **Initialization:** The model is prepared during the build process. On the very first boot, a system service finalizes the Lumin setup in the background.
* Lumin will be at the heart of LuminOS and will be integrated more deeply as future versions of LuminOS are released

---

**License:** GPL-3.0
*Built with passion for digital freedom. <3* 
