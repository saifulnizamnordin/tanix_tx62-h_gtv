# 2. Choose a matching Google TV ROM

A ROM must match the hardware **exactly**. Tanix sells several boards under
similar names, so confirm from `device-info/` (created by `backup-device.ps1`)
rather than from the box label.

## Check these values

| What | Where in `device-info/` | Notes |
|---|---|---|
| SoC | `getprop.txt` → `ro.board.platform`, `ro.hardware`; `cpuinfo.txt` | TX6S family is Allwinner (H616 / H618 / H313). Amlogic ROMs will **not** work. |
| Board / model | `getprop.txt` → `ro.product.board`, `ro.product.model`, `ro.build.fingerprint` | |
| RAM | `meminfo.txt` → `MemTotal` | 2 GB / 4 GB variants use different DRAM configs |
| eMMC size | `partitions.txt` | |
| Wi-Fi / BT chip | `lsmod.txt`, `getprop.txt` → `wlan.*` | e.g. XR819, AW859A, RTL8822CS – wrong driver = no Wi-Fi |
| Android version | `getprop.txt` → `ro.build.version.release` | |

## Where to look

- XDA Developers / 4PDA / FreakTab threads for "Tanix TX6S" + your SoC.
- Prefer ROMs whose post lists your exact SoC **and** Wi-Fi chip.
- Prefer `.img` Allwinner burn images (flash with PhoenixSuit/PhoenixCard).

## Record your choice

Put the download link, version and SHA256 in [`firmware/README.md`](../firmware/README.md)
so the exact image can be found again.
