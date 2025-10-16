# LuminOS Build Scripts

This repository contains the scripts and documentation for building the official LuminOS ISO image.

## Prerequisites

- An Ubuntu (24.04 LTS) or Debian (12+) based host system.
- `sudo` privileges.
- The following build dependencies must be installed:
  `sudo apt-get install git live-build debootstrap debian-archive-keyring plymouth`

## How to Build the ISO

1.  Clone this repository:
    ```bash
    git clone [https://github.com/4LuminOS/build-scripts.git](https://github.com/4LuminOS/build-scripts.git)
    ```
2.  Navigate into the directory:
    ```bash
    cd build-scripts
    ```
3.  Run the master build script as root. This process will be long and will download several gigabytes of packages.
    ```bash
    sudo ./build.sh
    ```
4.  If successful, the final `.iso` file will be in the `build-scripts` folder.
