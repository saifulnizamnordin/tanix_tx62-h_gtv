# Tanix TX6S-H – Custom Google TV

Notes, scripts and firmware references for replacing the stock Android TV box
firmware on a **Tanix TX6S-H** with a custom Google TV (GTV) ROM.

> ⚠️ Flashing the wrong firmware can brick the box. Always confirm the SoC,
> RAM/eMMC size and Wi-Fi chip before flashing, and back up stock first.

## This unit (from `device-info/stock/`)

| | |
|---|---|
| SoC | **Allwinner H616** (`sun50iw9p1`, platform `cupid`) – firmware falsely labels itself "Amlogic p281" |
| RAM / eMMC | 4 GB / 64 GB |
| Wi-Fi / BT | Broadcom SDIO `02d0:4330` → BCM4330 (AP6330), driver `bcmdhd` |
| GPU | Mali-G31 (`mali_kbase`) |
| Stock ROM | Android 10, 32-bit userspace (`armeabi-v7a`), `userdebug`, build 2020-12-19 |
| ADB | Network ADB on port 5555 works on stock |

Pick an **Allwinner H616** GTV ROM with Broadcom AP6330 Wi-Fi support – never an Amlogic one.
As of 2026-10 no such Google TV ROM exists – see [docs/rom-search.md](docs/rom-search.md).

## Do I need ADB before starting?

**Not strictly for flashing, but yes, do it first.**

| Purpose | Needs ADB? |
|---|---|
| Flashing the ROM (Allwinner USB burn mode via PhoenixSuit, or SD card via PhoenixCard) | No – done over USB/SD, not network |
| Identifying the exact hardware (SoC, board, Wi-Fi chip, eMMC/RAM) | **Yes** – easiest way |
| Backing up stock firmware / partitions so you can recover | **Yes** |
| Sideloading apps, debugging, logcat after the new ROM is installed | Yes (re-enable on the new ROM) |

ADB over network lets you do all of this from the PC without a USB A-to-A cable.

## Workflow

1. [Enable ADB over network on stock firmware](docs/01-enable-adb.md)
2. Connect and collect device info + backup:
   ```powershell
   .\scripts\adb-connect.ps1 -Ip 192.168.1.50
   .\scripts\backup-device.ps1 -Ip 192.168.1.50
   ```
   Commit the files in `device-info/` – they identify the board.
3. [Choose a matching GTV ROM](docs/02-choose-rom.md)
4. [Flash the ROM](docs/03-flash.md) · custom ROM: [docs/04-flash-custom-rom.md](docs/04-flash-custom-rom.md)
5. Re-enable ADB on the new ROM (same steps as 1) for post-install setup.

Custom Android TV ROM build: [rom/](rom/README.md) · plan: [docs/custom-rom-plan.md](docs/custom-rom-plan.md)

## Repo layout

```
docs/          step-by-step guides
scripts/       PowerShell helpers (ADB connect, info/backup)
device-info/   text output from backup-device.ps1 (committed)
backup/        partition dumps (NOT committed – too large)
firmware/      ROM images + checksums (images NOT committed, see firmware/README.md)
```

## Requirements (PC)

- Windows with [Android platform-tools](https://developer.android.com/tools/releases/platform-tools) (`adb`)
- PhoenixSuit (USB flashing) or PhoenixCard (SD card flashing) + Allwinner USB driver
- USB A-to-A cable (for PhoenixSuit) or a microSD card ≥ 8 GB (for PhoenixCard)
