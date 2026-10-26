# 3. Flash the ROM (Allwinner)

Do **not** start until `backup-device.ps1` has run and you have a stock
firmware image (your own dump or an official Tanix image) to fall back on.

## Option A – PhoenixSuit (USB A-to-A cable)

1. Install the Allwinner USB driver and PhoenixSuit on the PC.
2. Verify the image checksum:
   ```powershell
   Get-FileHash .\firmware\<rom>.img -Algorithm SHA256
   ```
3. PhoenixSuit → **Firmware** tab → select the `.img`.
4. Unplug power from the box. Hold the **reset/recovery button** (inside the
   AV jack on most Tanix boxes – use a toothpick), plug the A-to-A cable into
   the OTG USB port, then plug in power. Release after a few seconds.
   - Alternative while the box is running with ADB: `adb reboot efex`
5. PhoenixSuit detects the device and asks whether to **format** – choose
   **Yes** (full flash) when switching to a different ROM.
6. Wait for "Upgrade succeeded". First boot can take 5–10 minutes.

## Option B – PhoenixCard (microSD)

1. PhoenixCard → select the `.img` → mode **Product** (burns to eMMC) →
   **Burn** to the SD card.
2. Power off the box, insert the card, power on. Progress shows on the TV.
3. When it finishes, **remove the card** before rebooting.

## After flashing

1. Finish Google TV setup.
2. Re-enable ADB ([step 1](01-enable-adb.md)) and run
   `.\scripts\backup-device.ps1 -Ip <ip> -Label gtv` to record the new ROM.
3. Check Wi-Fi, Bluetooth remote, HDMI-CEC, 4K/HDR output, Widevine level
   (e.g. *DRM Info* app) and note results in `device-info/`.

## Recovery

If the box does not boot, re-enter burn mode (step A4) and flash the stock
image. Allwinner burn mode lives in the boot ROM, so it works even when the
installed firmware is broken.
