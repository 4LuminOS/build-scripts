# LuminOS Build Scripts :)

This repository contains the scripts and documentation for building the official LuminOS ISO image from a standard Debian base.

## Usage

The scripts are designed to be run in sequential order on a Debian-based system (like Debian, Ubuntu, ...)

### Prerequisites

- A Debian-based host system.
- `sudo` privileges.
- The `debootstrap` package must be installed (`sudo apt-get install debootstrap`)

### Build Process

Run the scripts in the following order as root:

1.  `sudo ./01-build-base-system.sh`
2.  `sudo ./02-configure-system.sh`
3.  ... (more to come)

## Scripts

-   **01-build-base-system.sh**: Creates a minimal Debian "Trixie" chroot environment which serves as the foundation of LuminOS.
-   **02-configure-system.sh**: Configures the base system within the chroot (hostname, users, updates, etc.).
