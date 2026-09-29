#!/usr/bin/env bash
set -euo pipefail

PLUGIN_ID="alan.ajazz-mouse"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DEST="$HOME/.config/omarchy/plugins/$PLUGIN_ID"
BIN_DEST="$HOME/.local/bin"
UDEV_DEST="/etc/udev/rules.d"

say() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarning:\033[0m %s\n' "$*"; }

say "Checking Python modules"
if ! python3 -c 'import hid, usb' 2>/dev/null; then
  warn "python-hidapi / python-pyusb missing. Install with:"
  warn "  sudo pacman -S python-hidapi python-pyusb   (or: omarchy pkg add python-hidapi python-pyusb)"
fi

say "Installing scripts to $BIN_DEST"
mkdir -p "$BIN_DEST"
install -m 0755 "$REPO_DIR/bin/ajazz-battery" "$REPO_DIR/bin/ajazz-ctl" "$BIN_DEST/"

say "Installing Omarchy plugin to $PLUGIN_DEST"
mkdir -p "$PLUGIN_DEST"
install -m 0644 "$REPO_DIR/plugin/manifest.json" "$PLUGIN_DEST/"
install -m 0644 "$REPO_DIR/plugin/BarWidget.qml" "$PLUGIN_DEST/"
install -m 0644 "$REPO_DIR/plugin/Panel.qml" "$PLUGIN_DEST/"
install -m 0644 "$REPO_DIR/plugin/Chip.qml" "$PLUGIN_DEST/"

say "Installing udev rule (sudo)"
sudo install -m 0644 "$REPO_DIR/udev/99-ajazz-aj139-pro.rules" "$UDEV_DEST/"
sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=usb --action=change || true
sudo udevadm trigger --subsystem-match=hidraw --action=change || true

if command -v omarchy >/dev/null 2>&1; then
  say "Enabling widget in the bar"
  omarchy plugin enable "$PLUGIN_ID" right || omarchy plugin enable "$PLUGIN_ID" || true
else
  warn "omarchy not found. Enable the widget manually in ~/.config/omarchy/shell.json"
fi

say "Done. Replug the mouse/dongle once so the udev rule takes effect."
