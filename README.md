# Ajazz Mouse Battery (Omarchy plugin)

Battery read-out **and** configuration for the **Ajazz AJ139 Pro** (and likely
other Ajazz / ATK / VXE / COMPX mice) as an [Omarchy](https://omarchy.org/)
bar widget with a control popup. No vendor software, no Windows — it talks to
the mouse directly over HID.

- **Bar widget:** mouse icon + battery percentage, lightning bolt while
  charging, warning colour when low. Tooltip shows charging state and
  `wired`/`wireless`; reacts to plugging/unplugging within ~2 s.
- **Control popup** (left-click the icon): polling rate (125/250/500/1000 Hz),
  active DPI profile (1–8), all 8 DPI stages (`−`/`+`, 50 DPI step), per-stage
  LED colour, and backup/restore.
- **CLI** (`scripts/ajazz-ctl`) for scripting.

Protocol was reverse-engineered by the ATK/VXE community — see [Credits](#credits).

## Requirements

- Omarchy (Quattro shell) with `omarchy plugin`.
- `python-hidapi` (battery) and `python-pyusb` (configuration reads/writes).
- Access to the mouse's `hidraw` and USB device nodes via the shipped udev
  rule (granted to the `wheel` group, the default admin group on Arch).

## Install

```bash
# 1. install the widget (clones this repo into your plugin dir)
omarchy plugin add https://github.com/Alanus96/omarchy-ajazz-mouse --enable

# 2. dependencies
omarchy pkg add python-hidapi python-pyusb       # or: sudo pacman -S python-hidapi python-pyusb

# 3. permissions: install the udev rule (needs sudo; do this once)
PLUGIN_DIR="$HOME/.config/omarchy/plugins/io.github.alanus96.ajazz-mouse"
sudo install -m 0644 "$PLUGIN_DIR/udev/99-ajazz-aj139-pro.rules" /etc/udev/rules.d/
sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=usb --action=change
sudo udevadm trigger --subsystem-match=hidraw --action=change
# then unplug/replug the mouse or dongle once
```

From a cloned copy you can run `./setup.sh` instead of step 3.

> **Manual setup is required:** the udev rule and the Python modules cannot be
> installed automatically by the marketplace. The widget will show nothing
> until they are in place.

## Removal

```bash
sudo rm -f /etc/udev/rules.d/99-ajazz-aj139-pro.rules
sudo udevadm control --reload-rules
omarchy plugin remove io.github.alanus96.ajazz-mouse --yes
```

## Usage

Click the mouse icon in the bar. Every control takes effect on the mouse
immediately. While a control action runs, the HID *config* interface is
detached for a moment; the movement interface is untouched.

CLI (inside the installed plugin folder, or the repo's `scripts/`):

```
ajazz-ctl info [--json]           # battery, rate, profile, 8×DPI, colours, settings
ajazz-ctl rate 125|250|500|1000   # polling rate
ajazz-ctl profile 1..8            # active DPI profile
ajazz-ctl dpi 3 1600              # set a DPI stage (multiple of 50)
ajazz-ctl color 1 '#ff8800'       # LED colour of a stage
ajazz-ctl backup | restore        # config backup / rollback (latest + 5)
ajazz-ctl raw-read 0xa9 10        # read raw EEPROM
ajazz-ctl raw-write 0xa9 '01 54'  # write raw EEPROM

ajazz-battery                     # one-line battery status
ajazz-battery --status            # JSON consumed by the widget
```

## Settings

Widget settings (via the Omarchy settings UI, stored in
`~/.config/omarchy/shell.json`):

| key | default | meaning |
|---|---|---|
| `showPercent` | `true` | show the percentage next to the icon |
| `pollInterval` | `2` | bar refresh interval in seconds |
| `warningThreshold` | `30` | percentage at which the icon turns urgent |
| `criticalThreshold` | `15` | critical threshold |
| `hideWhenOffline` | `false` | hide the widget when the mouse is off |

## How it works

- **Battery:** HID report id `0x08`, command `0x04` (`GetBatteryLevel`) over
  `hidraw`. Fast, no driver detach.
- **Configuration (DPI, rate, colours, …):** HID report id `0x08`, commands
  `0x07` (`SetEEPROM`) / `0x08` (`GetEEPROM`). A 16-byte command
  `[cmd, status, addr_hi, addr_lo, len, data…, checksum]` is sent as a USB
  control `SET_REPORT`; the reply arrives on the interface's interrupt-IN
  endpoint. The kernel HID driver owns that interface, so it is detached for
  the duration of the call (movement is unaffected).
- Checksum settles the byte sum at `0x55`.

Useful EEPROM addresses: `0x00` report-rate/active-DPI block,
`0x0c/0x14/0x1c/0x24` DPI pairs (stages 1–8), `0x2c/0x34/0x3c/0x44` DPI
colours, `0xa9`+ settings (stabilisation, motion sync, sleep, …).

## Supported devices

Tested on the **Ajazz AJ139 Pro** (`25a7:fa7b` wired, `25a7:fa7c` dongle).
Other Ajazz / ATK / VXE mice that speak the same COMPX protocol should work
after adjusting the VID/PID lists in `scripts/ajazz-battery` and
`scripts/ajazz-ctl`. Pull requests with additional IDs are welcome.

## Credits

- [`libatk-rs`](https://crates.io/crates/libatk-rs) and
  [`VoideUI/Linux-ATK`](https://github.com/VoideUI/Linux-ATK) — command framing
  and EEPROM map.
- [`mateusands/open-m711pro`](https://github.com/mateusands/open-m711pro) —
  COMPX `25a7` protocol notes.
- `245582001g-oss/mouse-battery-reminder` — the `0x04` battery command.
- [`xb-bx/atk-a9-ultra-driver`](https://github.com/xb-bx/atk-a9-ultra-driver) —
  control-transfer reference.

## Disclaimer

Unofficial; not affiliated with Ajazz. Writing changes the mouse's stored
configuration. The tools back up first, but use at your own risk.

## License

MIT — see [LICENSE](LICENSE).
