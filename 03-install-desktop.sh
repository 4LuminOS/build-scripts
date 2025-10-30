#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive
echo "--> Installing Linux kernel and GRUB..."
apt-get install -y linux-image-amd64 grub-pc
echo "--> Installing KDE Plasma desktop and services..."
DESKTOP_PACKAGES="plasma-desktop konsole sddm network-manager"
apt-get install -y $DESKTOP_PACKAGES
