#!/bin/bash
set -e
echo "--> Cleaning APT cache..."
apt-get clean
rm -rf /var/lib/apt/lists/*
echo "--> Cleaning temporary files..."
rm -rf /tmp/*
echo "--> Cleaning machine-id..."
truncate -s 0 /etc/machine-id
mkdir -p /var/lib/dbus
rm -f /var/lib/dbus/machine-id
ln -s /etc/machine-id /var/lib/dbus/machine-id
echo "--> Cleaning bash history..."
unset HISTFILE
rm -f /root/.bash_history
rm -f /home/liveuser/.bash_history
