# rockpi-penta-pi5-fix

Patches for the [Radxa Penta SATA HAT](https://radxa.com/products/accessories/penta-sata-hat) `rockpi-penta` package to work correctly on a **Raspberry Pi 5** running **Debian Trixie** (Raspberry Pi OS based on Debian 13).

## The Problem

The official `rockpi-penta` v0.2.2 package was written for `gpiod` v1. Debian Trixie ships with `gpiod` v2, which completely overhauled its Python API. This causes the service to crash immediately on startup with:

```
FileNotFoundError: [Errno 2] No such file or directory
```

Additionally, the fan controller reads CPU temperature by default. Since the Penta SATA HAT fan is positioned to cool the drives (not the CPU), this patch changes it to read SSD temperatures via `smartctl` instead, with a fallback to CPU temp if smartctl fails.

## What's Patched

| File | Change |
|------|--------|
| `fan.py` | `Gpio` class rewritten for gpiod v2 API; `read_temp()` reads SSD temps via smartctl |
| `misc.py` | `read_key()` rewritten for gpiod v2 API |
| `rockpi-penta.conf` | Fan thresholds tuned for SSD temps (35/42/48/55°C) rather than CPU temps |

## Requirements

- Raspberry Pi 5
- Debian Trixie / Raspberry Pi OS (Trixie-based)
- `rockpi-penta` v0.2.2 already installed
- `smartmontools` (installed automatically by the install script)

## Installation

```bash
# Install rockpi-penta first if you haven't already
sudo apt install wget
wget https://github.com/radxa/rockpi-penta/releases/download/v0.2.2/rockpi-penta-0.2.2.deb
sudo apt install -y ./rockpi-penta-0.2.2.deb

# Then apply this fix
git clone https://github.com/YOUR_USERNAME/rockpi-penta-pi5-fix.git
cd rockpi-penta-pi5-fix
sudo bash install.sh
```

## Manual Installation

If you prefer to apply the patches manually:

```bash
sudo apt install smartmontools

# Back up originals
sudo cp /usr/bin/rockpi-penta/fan.py /usr/bin/rockpi-penta/fan.py.bak
sudo cp /usr/bin/rockpi-penta/misc.py /usr/bin/rockpi-penta/misc.py.bak

# Copy patched files
sudo cp patches/fan.py /usr/bin/rockpi-penta/fan.py
sudo cp patches/misc.py /usr/bin/rockpi-penta/misc.py

# Restart service
sudo systemctl restart rockpi-penta.service
sudo systemctl status rockpi-penta.service
```

## Fan Temperature Thresholds

The included `rockpi-penta.conf` uses these thresholds, tuned for SSD temperatures:

| Level | Temp | Fan Speed |
|-------|------|-----------|
| Off   | <35°C | 0% |
| lv0   | 35°C | 25% |
| lv1   | 42°C | 50% |
| lv2   | 48°C | 75% |
| lv3   | 55°C | 100% |

You can adjust these in `/etc/rockpi-penta.conf`. Run `sudo systemctl restart rockpi-penta.service` after any changes.

## Also Required — config.txt

For the HAT to be recognised at all, you need these lines in `/boot/firmware/config.txt`:

```ini
dtparam=pciex1
dtparam=pciex1_gen=3
```

## License

These patches are provided under the MIT License. The original `rockpi-penta` package is by [Radxa](https://github.com/radxa/rockpi-penta).
