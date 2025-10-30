#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive

echo "--> Installing Plymouth..."
apt-get install -y plymouth

echo "--> Creating Plymouth theme files..."
THEME_DIR="/usr/share/plymouth/themes/luminos"
# The logo file is already copied by build.sh to /usr/share/wallpapers/luminos/logo-plymouth.png

cat > "\${THEME_DIR}/luminos.plymouth" << EOF
[Plymouth Theme]
Name=LuminOS
Description=A clean and simple boot splash for LuminOS
ModuleName=script
[script]
ImageDir=/usr/share/wallpapers/luminos
ScriptFile=/usr/share/plymouth/themes/luminos/luminos.script
EOF

cat > "\${THEME_DIR}/luminos.script" << EOF
logo_image = Image("logo-plymouth.png");
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

echo "--> Setting default Plymouth theme..."
plymouth-set-default-theme -R luminos
update-initramfs -u
