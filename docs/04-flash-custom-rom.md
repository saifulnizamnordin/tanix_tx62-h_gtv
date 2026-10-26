# 4. Flash the custom LineageOS Android TV ROM

**This erases everything on the box** (apps, settings, files). The full stock
backup is in `backup/stock/` (checksums in `device-info/stock/backup-sha256.txt`).

## You need

- Windows PC with **PhoenixSuit** (v1.10+) and the **Allwinner USB driver**
- **USB A-to-A cable**
- The ROM image from the GitHub release, e.g.
  `firmware/lineage-18.1-…-TX6S-H-vanilla_debug.img`, with `RESULT: all checks passed`
  in its release notes

## Steps

1. Open PhoenixSuit → **Firmware** tab → **Image** → select the `.img`.
2. Put the box into burn (FEL / efex) mode, either:
   - **From ADB (easiest, box running stock):**
     ```powershell
     adb -s 192.168.100.10:5555 reboot efex
     ```
     then connect the A-to-A cable between the PC and the box's **OTG USB port**.
   - **With the button:** unplug power, plug the A-to-A cable into the OTG
     port, hold the reset button inside the **AV jack** (toothpick), plug in
     power, release after ~5 s.
3. Windows should detect a new USB device and PhoenixSuit should show the
   device. If it doesn't, install the Allwinner USB driver
   (Device Manager → unknown device → update driver → PhoenixSuit `Drivers` folder).
4. PhoenixSuit asks **"Do you want to format the device?"** → **Yes**
   (needed: the system changes from Android 10 to Android 11).
5. Wait for **"Upgrade succeeded"** (about 5–10 minutes). Do not unplug.
6. Unplug the USB cable, power-cycle the box with the HDMI connected.
   **First boot takes 3–10 minutes** (boot logo → LineageOS animation).

## After the first boot (`vanilla_debug`)

- Network ADB is on port 5555 **without an authorization prompt**:
  ```powershell
  adb connect <box-ip>:5555
  adb shell getprop ro.lineage.version
  ```
- If it does not boot past the logo, ADB usually still comes up: collect logs with
  `adb logcat -d > logcat.txt` and `adb shell dmesg > dmesg.txt`.
- Test: Wi-Fi, Ethernet, IR remote, Bluetooth, HDMI audio, video playback
  (YouTube / Kodi), 4K output, reboot, standby.

## Going back to stock

Flash `ddr3-TX6S-20230426.img` (official Tanix, same DRAM type) with the same
steps, or restore `backup/stock/` partitions over ADB root.
