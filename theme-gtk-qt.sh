#!/usr/bin/env bash
# One-time setup so GTK3/GTK4 and Qt apps follow DankMaterialShell colors.
# After this, DMS switches them automatically on dark/light toggle.
set -euo pipefail

echo "==> Installing adw-gtk3-theme, qt6ct, qt5ct"
sudo dnf install -y adw-gtk3-theme qt6ct qt5ct

echo "==> Pointing qt5ct/qt6ct at DMS palette"
bash /usr/share/quickshell/dms/scripts/qt.sh "$HOME/.config"

echo "==> Session env: QT_QPA_PLATFORMTHEME=qt6ct"
mkdir -p "$HOME/.config/environment.d"
echo "QT_QPA_PLATFORMTHEME=qt6ct" > "$HOME/.config/environment.d/91-qt.conf"
systemctl --user set-environment QT_QPA_PLATFORMTHEME=qt6ct 2>/dev/null || true

echo "Done. Toggle dark/light once in DMS, then log out/in for Qt apps."
