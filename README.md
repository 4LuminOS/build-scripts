# LuminOS Build Scripts

[![Build Status](https://img.shields.io/badge/build-passing-brightgreen)]() [![Version](https://img.shields.io/badge/version-v0.2.1-blue)]()

Welcome to the official repository for **LuminOS**.

**LuminOS** is a lightweight, private, and intelligent Linux distribution based on **Debian 13 (Trixie)**. It features native integration of **Lumin**, a 100% local, offline AI assistant, and a curated suite of productivity tool

---

## 💿 Getting Started (Live ISO)

### Default Credentials
If you boot the ISO, use these credentials to log in:
* **User:** `liveuser`
* **Password:** `luminos`

> **⚠️ Important for AZERTY Users:**
> The live system boots with a **US (QWERTY)** keyboard layout by default.
> To type "luminos", use the digital keyboard (the one on screen). You'll find the option in the bottom left corner. Alternatively, you can also press: **`l` `u` `,` `i` `n` `o` `s`**
> *(The `m` is located on the `,` key).*
> Sorry for the inconvenience... 😅 will fix this.

### How to try it
1.  **Get** the ISO (from Releases -> soon or build it yourself).
2.  **Flash** it to a USB stick using **BalenaEtcher** or **Ventoy**.
3.  **Boot** your computer from the USB stick (also make sure Secure Boot is disabled in your BIOS).

---

## 📦 Included Software

LuminOS comes "batteries included", and some default apps for productivity:

* **Desktop:** KDE Plasma (Dark Theme).
* **AI:** **Lumin** (powered by Ollama + Llama 3) - 100% Local & Offline.
* **Productivity:** **OnlyOffice Desktop Editors** (Word, Excel, PowerPoint compatible).
* **Multimedia:** **VLC Media Player** + Full Codec Pack (h.264, mp3, and more...).
* **System:** **Timeshift** (Backups), **Flatpak** (App Store), **Firefox** (you guessed it, web borwser).

---

## 🏗️ Build It Yourself

We use a transparent, manual build process for good stability.

### Prerequisites
* Host: **Ubuntu 24.04 LTS** or **Debian 12+**.
* Disk Space: ~30 GB free.
* RAM: 8 GB minimum.
* `sudo` privileges

### Build Instructions

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/4LuminOS/build-scripts.git
    cd build-scripts
    ```

2.  **Run the build:**
    ```bash
    sudo ./build.sh
    ```

3.  **Retrieve the ISO:**
    The final image `LuminOS-0.2.1-amd64.iso` will be generated in the project folder.

---

## 🤖 Architecture Overview

1.  **AI Prep:** Downloads Ollama and Llama 3 on the host to ensure integrity.
2.  **Bootstrap:** Creates a pristine Debian Trixie base.
3.  **Injection:** Copies scripts, assets, and AI models into the system.
4.  **Customization:** Installs Kernel, Desktop, Themes, and Software via chroot hooks.
5.  **Assembly:** Compresses the filesystem (SquashFS) and generates a Hybrid ISO.

---
**License:** GPL-3.0
*Built with <3*
