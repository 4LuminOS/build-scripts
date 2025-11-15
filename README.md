# LuminOS Build Scripts

[![Build Test](https://github.com/4LuminOS/build-scripts/actions/workflows/build-test.yml/badge.svg)](https://github.com/4LuminOS/build-scripts/actions/workflows/build-test.yml)

# This README is NOT up to date. It'll be revamped for the next functional ISO. Thank you.

This repository contains the scripts and documentation for building the official **LuminOS v0.2** ISO image. LuminOS aims to be a free, private, and intelligent Linux distribution, mainly built for modern machines.

## Project Goals (v0.2)

* **Base:** Debian 13 "Trixie" (Testing).
* **Desktop:** KDE Plasma (dark theme, customized).
* **Core Feature:** Integrated, 100% local AI assistant "Lumin" (powered by Ollama + Llama 3).
* **Philosophy:** Privacy-focused, no cloud dependencies, FOSS-first, modern look.
* **Branding:** Custom LuminOS Plymouth splash screen and basic branding.

## Prerequisites

* An **Ubuntu (24.04 LTS recommended)** or Debian (12+) based host system.
* `sudo` privileges.
* Approximately **30-40 GB** of free disk space.
* An active internet connection (especially for the first build).
* The following build dependencies must be installed:
    ```bash
    sudo apt update
    sudo apt install git live-build debootstrap debian-archive-keyring plymouth curl rsync
    ```
* **For AI:** You must pre-download the AI model on your host machine before running the build:
    ```bash
    # Install Ollama on host if you haven't already
    curl -fsSL [https://ollama.com/install.sh](https://ollama.com/install.sh) | sh
    # Pull the required base model
    ollama pull llama3
    ```

## How to Build the ISO

1.  **Clone the repository:**
    ```bash
    git clone [https://github.com/4LuminOS/build-scripts.git](https://github.com/4LuminOS/build-scripts.git)
    ```
2.  **Navigate into the directory:**
    ```bash
    cd build-scripts
    ```
3.  **(Optional but Recommended) Ensure latest version:**
    ```bash
    git pull
    ```
4.  **Run the master build script as root:**
    * **Warning:** This process WILL take a significant amount of time (potentially several hours) and will download several gigabytes of packages.
    ```bash
    sudo ./build.sh
    ```
5.  **Result:** If successful, the final ISO image (e.g., `live-image-amd64.iso`) will be located in the `build-scripts` folder.

## Build Scripts Overview

The `build.sh` script orchestrates the following phases:

* **01-build-base-system.sh:** Creates a minimal Debian "Trixie" chroot environment
* **02-configure-system.sh:** Configures the base system (hostname, users, updates, locales)
* **03-install-desktop.sh:** Installs the Linux kernel, GRUB, and KDE Plasma
* **04-customize-desktop.sh:** Removes unwanted packages, applies basic themes & wallpapers, brands OS
* **05-install-ai.sh:** Installs Ollama binary, copies pre-downloaded model, creates "Lumin" model & base services
* **07-install-plymouth-theme.sh:** Installs the custom LuminOS boot splash screen
* **06-final-cleanup.sh:** Cleans the system before packaging.
* **(build.sh):** Configures `live-build` and generates the final bootable ISO.

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.
