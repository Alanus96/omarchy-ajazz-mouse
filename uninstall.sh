#!/usr/bin/env bash
set -euo pipefail

PLUGIN_ID="alan.ajazz-mouse"
PLUGIN_DEST="$HOME/.config/omarchy/plugins/$PLUGIN_ID"

say() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

if command -v omarchy >/dev/null 2>&1; then
  say "Disabling widget"
  omarchy plugin disable "$PLUGIN_ID" || true
fi

say "Removing plugin, scripts and udev rule"
rm -rf "$PLUGIN_DEST"
rm -f "$HOME/.local/bin/ajazz-battery" "$HOME/.local/bin/ajazz-ctl"
sudo rm -f /etc/udev/rules.d/99-ajazz-aj139-pro.rules
sudo udevadm control --reload-rules || true

say "Done."
