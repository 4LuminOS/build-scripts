#!/bin/bash
set -e
echo "--> Applying pre-install fixes..."
echo "--> Disabling download of apt Contents-indices to prevent 404 errors."
# This file tells apt to not download the problematic Contents files
cat > /etc/apt/apt.conf.d/99-no-contents << EOF
Acquire::IndexTargets::deb::Contents-deb "false";
Acquire::IndexTargets::deb-src::Contents-src "false";
EOF
echo "--> Fix applied."
