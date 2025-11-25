#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive

echo "--> Removing unwanted packages..."
PACKAGES_TO_REMOVE="kmahjongg kmines kpat ksnake kmail kontact akregator"
for pkg in $PACKAGES_TO_REMOVE; do
    apt-get purge -y "$pkg" || true
done
apt-get autoremove -y

echo "--> Setting up global assets..."
# Ensure the wallpaper directory exists
mkdir -p /usr/share/wallpapers/luminos/
# (Note: The actual image files are copied by build.sh later, 
# but we ensure the folder structure is ready here if needed)

# --- CONFIGURATION GENERATION ---
# We create a temporary folder to hold our configs first
CONFIG_TMP="/tmp/luminos-configs"
mkdir -p "$CONFIG_TMP/.config"

# 1. Dark Theme Config
cat > "$CONFIG_TMP/.config/kdeglobals" << "EOF"
[General]
ColorScheme=BreezeDark
Name=BreezeDark
[Icons]
Theme=breeze-dark
EOF

# 2. Wallpaper Config
# We configure it for both standard plasma and the desktop container
cat > "$CONFIG_TMP/.config/plasma-org.kde.plasma.desktop-appletsrc" << "EOF"
[Containments][1]
wallpaperplugin=org.kde.image

[Containments][1][Wallpaper][org.kde.image][General]
Image=file:///usr/share/wallpapers/luminos/luminos-wallpaper-default.png
FillMode=2
EOF

# 3. SDDM (Login Screen) Config
mkdir -p /etc/sddm.conf.d/
cat > /etc/sddm.conf.d/luminos-theme.conf << "EOF"
[Theme]
Current=breeze
[General]
# Ensure we point to the right background for the login screen
Background=/usr/share/wallpapers/luminos/luminos-sddm-background.png
EOF


# --- APPLYING TO USERS ---

# 1. Apply to Skeleton (for any future new users)
cp -r "$CONFIG_TMP/.config" /etc/skel/

# 2. Force Apply to 'liveuser' (The Fix!)
# We verify if the user exists, then inject the configs
if id "liveuser" &>/dev/null; then
    echo "--> Injecting configurations into liveuser home..."
    HOMEDIR="/home/liveuser"
    mkdir -p "$HOMEDIR/.config"
    
    # Copy config files
    cp "$CONFIG_TMP/.config/kdeglobals" "$HOMEDIR/.config/"
    cp "$CONFIG_TMP/.config/plasma-org.kde.plasma.desktop-appletsrc" "$HOMEDIR/.config/"
    
    # CRITICAL: Fix permissions so liveuser owns their own files
    chown -R liveuser:liveuser "$HOMEDIR"
else
    echo "WARNING: liveuser not found, configs only applied to skel."
fi

# Cleanup
rm -rf "$CONFIG_TMP"

echo "SUCCESS: Desktop environment customized and applied to liveuser."
