# omarchy-ajazz-mouse

Battery read-out **and** configuration for the **Ajazz AJ139 Pro** (and
likely other AJazz / ATK / VXE / COMPX mice) on Linux, packaged as an
[Omarchy](https://omarchy.org/) bar widget with a control popup.

No vendor software, no Windows, no VM — it talks to the mouse directly over
HID. The protocol was reverse-engineered by the ATK/VXE community (see
[Credits](#credits)).

![kind](https://img.shields.io/badge/kind-bar--widget-blue)
![license](https://img.shields.io/badge/license-MIT-green)

## Features

- **Bar widget:** mouse icon + battery percentage, lightning bolt while
  charging, warning colour when low. Tooltip shows charging state and
  `wired`/`wireless`. Reacts to plugging/unplugging the cable within ~2 s.
- **Control popup** (left-click the icon):
  - polling rate (125 / 250 / 500 / 1000 Hz)
  - active DPI profile (1–8)
  - all 8 DPI stages with `−`/`+` (50 DPI step)
  - per-stage LED colour (click cycles a palette)
  - backup / restore
- **CLI** (`ajazz-ctl`) for scripting and everything above.
- Automatic full-config backup before the first write, plus `restore`.

## Requirements

- Arch Linux / Omarchy (uses `omarchy plugin`, systemd not required).
- `python-hidapi` (battery widget) and `python-usb` / pyusb (config reads &
  writes):
  ```bash
  sudo pacman -S python-hidapi python-pyusb
  # or: omarchy pkg add python-hidapi python-pyusb
  ```
- Your user must be able to access the mouse's `hidraw` and USB device nodes.
  The shipped udev rule grants that to the `wheel` group (the default admin
  group on Arch).

## Install

```bash
git clone <this repo> omarchy-ajazz-mouse
cd omarchy-ajazz-mouse
./install.sh
```

The installer copies the plugin to
`~/.config/omarchy/plugins/alan.ajazz-mouse/`, the scripts to
`~/.local/bin/`, installs the udev rule (with `sudo`) and enables the widget
in the right bar section.

Manual install is just copying those three things and running
`omarchy plugin enable alan.ajazz-mouse right`.

Uninstall:

```bash
./uninstall.sh
```

## Usage

### Widget

Click the mouse icon in the bar. Everything in the popup takes effect on the
mouse immediately. While a control action runs, the HID *config* interface is
detached for a moment; the movement interface is untouched.

### CLI `ajazz-ctl`

```
ajazz-ctl info [--json]           # battery, rate, profile, 8×DPI, colours, settings
ajazz-ctl rate 125|250|500|1000   # polling rate
ajazz-ctl profile 1..8            # active DPI profile
ajazz-ctl dpi 3 1600              # set a DPI stage (multiple of 50)
ajazz-ctl color 1 '#ff8800'       # LED colour of a stage
ajazz-ctl backup | restore        # config backup / rollback (keeps latest + 5)
ajazz-ctl raw-read 0xa9 10        # read raw EEPROM
ajazz-ctl raw-write 0xa9 '01 54'  # write raw EEPROM
```

`ajazz-battery --status` prints the JSON the widget consumes; `ajazz-battery`
alone prints a one-liner.

## Configuration

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

- **Battery**: HID report id `0x08`, command `0x04` (`GetBatteryLevel`) over
  `hidraw`. Fast and needs no driver detach.
- **Config (DPI, rate, colours, …)**: HID report id `0x08`,
  commands `0x07` (`SetEEPROM`) / `0x08` (`GetEEPROM`). A 16-byte command
  `[cmd, status, addr_hi, addr_lo, len, data…, checksum]` is sent as a USB
  control `SET_REPORT`; the reply arrives on the interface's interrupt-IN
  endpoint. Because the kernel HID driver owns that interface, it is
  detached for the duration of the call (mouse movement is unaffected).
- Checksum settles the byte sum at `0x55`.

Useful EEPROM addresses: `0x00` report-rate/active-DPI block, `0x0c/0x14/0x1c/0x24`
DPI pairs (stages 1–8), `0x2c/0x34/0x3c/0x44` DPI colours, `0xa9`+ settings
(stabilisation, motion sync, sleep, …).

## Supported devices

Tested on the **Ajazz AJ139 Pro** (`25a7:fa7b` wired, `25a7:fa7c` dongle).
Other Ajazz / ATK / VXE mice that speak the same COMPX protocol should work
after adjusting the VID/PID lists in `bin/ajazz-battery` and `bin/ajazz-ctl`.
Please open a PR with the IDs if you test another model.

## Credits

- [`libatk-rs`](https://crates.io/crates/libatk-rs) and
  [`VoideUI/Linux-ATK`](https://github.com/VoideUI/Linux-ATK) — clean
  reference for the command framing and EEPROM map.
- [`mateusands/open-m711pro`](https://github.com/mateusands/open-m711pro) —
  protocol notes for COMPX `25a7` mice.
- `245582001g-oss/mouse-battery-reminder` — the `0x04` battery command.
- [`xb-bx/atk-a9-ultra-driver`](https://github.com/xb-bx/atk-a9-ultra-driver) —
  control-transfer reference.

## Disclaimer

Unofficial and not affiliated with Ajazz. Writing to the mouse changes its
stored configuration; the tools back up first, but use at your own risk.

## License

MIT — see [LICENSE](LICENSE).
