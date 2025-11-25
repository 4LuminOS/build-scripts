# LuminOS Build Scripts

[![Build Status](https://img.shields.io/badge/build-passing-brightgreen)]()

Welcome to the official build repository for **LuminOS**.

**LuminOS** is a lightweight, private, and intelligent Linux distribution based on Debian 13 "Trixie". It features native integration of **Lumin**, a local, offline, and ethical AI assistant.

---

## 🏗️ Build Architecture (v0.2)

We choose a **transparent, manual build process** to ensure stability.

The master script `build.sh` orchestrates the entire pipeline:
1.  **Bootstrap:** Creates a base Debian system using `debootstrap`.
2.  **AI Prep:** Pre-downloads Ollama and models on the host to avoid network issues
3.  **Injection:** Copies scripts and assets into the system.
4.  **Customization:** Executes scripts `02` through `07` inside the system (chroot) to install KDE, themes, and configure settings.
5.  **Assembly:** Compresses the filesystem and generates the ISO.

## 🚀 Prerequisites

* Host: **Ubuntu 24.04 LTS** or **Debian 12+**.
* Disk Space: ~30 GB free.
* RAM: 8 GB minimum.
* `sudo` privileges.

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
    The final image `LuminOS-0.2-amd64.iso` will be generated in the project folder (called build-scripts probably)

## 🤖 About Lumin (AI)

LuminOS v0.2 integrates a local AI based on Llama 3. The model is prepared during the build. On the first boot of the installed OS, a background service finalizes the setup automatically.

---
**License:** GPL-3.0 :)
