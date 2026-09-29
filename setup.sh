#!/usr/bin/env bash
# One-time system setup for the Ajazz mouse plugin: checks Python deps and
# installs the udev rule that grants the `wheel` group access to the mouse.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

say() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

say "Checking Python modules"
if python3 -c 'import hid, usb' 2>/dev/null; then
  echo "python-hidapi and python-pyusb present."
else
  echo "Missing python-hidapi / python-pyusb. Install with:"
  echo "  omarchy pkg add python-hidapi python-pyusb"
  echo "  # or: sudo pacman -S python-hidapi python-pyusb"
fi

say "Installing udev rule (sudo required)"
sudo install -m 0644 "$REPO_DIR/udev/99-ajazz-aj139-pro.rules" /etc/udev/rules.d/
sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=usb --action=change || true
sudo udevadm trigger --subsystem-match=hidraw --action=change || true

say "Done. Unplug and replug the mouse or its dongle once."
