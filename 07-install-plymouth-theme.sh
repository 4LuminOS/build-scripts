#!/bin/bash
# ==============================================================================
# LuminOS Build Script, Phase 7: Plymouth Boot Splash Theme
#
# Author: Gabriel, Project Leader @ LuminOS
# Version: 0.1.0
# ==============================================================================
set -e
LUMINOS_CHROOT_DIR="chroot"

if [ ! -f "assets/logo-plymouth.png" ]; then
    echo "ERROR: Plymouth logo not found at assets/logo-plymouth.png"
    exit 1
fi

echo "--> Creating Plymouth theme structure..."
THEME_DIR="$LUMINOS_CHROOT_DIR/usr/share/plymouth/themes/luminos"
mkdir -p "$THEME_DIR"
cp "assets/logo-plymouth.png" "$THEME_DIR/logo.png"

cat > "$THEME_DIR/luminos.plymouth" << EOF
[Plymouth Theme]
Name=LuminOS
Description=A clean and simple boot splash for LuminOS
ModuleName=script

[script]
ImageDir=/usr/share/plymouth/themes/luminos
ScriptFile=/usr/share/plymouth/themes/luminos/luminos.script
EOF

cat > "$THEME_DIR/luminos.script" << EOF
logo_image = Image("logo.png");
logo_sprite = Sprite(logo_image);
logo_sprite.SetX(Window.GetWidth() / 2 - logo_image.GetWidth() / 2);
logo_sprite.SetY(Window.GetHeight() / 2 - logo_image.GetHeight() / 2 - 100);

progress_box_image = Image.Box(Window.GetWidth() / 4, 8, 0, 0, 0);
progress_box_sprite = Sprite(progress_box_image);
progress_box_sprite.SetX(Window.GetWidth() / 2 - progress_box_image.GetWidth() / 2);
progress_box_sprite.SetY(logo_sprite.GetY() + logo_image.GetHeight() + 50);

fun refresh_callback () {
  progress = Plymouth.GetProgress();
  progress_image = Image.Box(Window.GetWidth() / 4 * progress, 8, 1, 1, 1);
  progress_sprite = Sprite(progress_image);
  progress_sprite.SetX(Window.GetWidth() / 2 - progress_box_image.GetWidth() / 2);
  progress_sprite.SetY(logo_sprite.GetY() + logo_image.GetHeight() + 50);
}
Plymouth.SetRefreshFunction(refresh_callback);
EOF

echo "--> Installing and configuring Plymouth theme in chroot..."
chroot "$LUMINOS_CHROOT_DIR" /bin/bash << EOF
set -e
apt-get install -y plymouth plymouth-themes
plymouth-set-default-theme -R luminos
EOF
