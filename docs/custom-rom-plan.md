# Custom Android TV / Google TV ROM – build plan

No ready-made GTV ROM exists for this box ([rom-search.md](rom-search.md)), so we
build one. The box is Treble-compliant, so the approach is: **keep Allwinner's
boot + vendor (kernel, Wi-Fi, GPU, HDMI, remote) and replace `system` with an
Android TV GSI**, then add Google TV components and package it as a PhoenixSuit
image.

## Facts that drive the design (`device-info/stock/`)

| Property | Value | Consequence |
|---|---|---|
| `ro.treble.enabled` | true | GSIs can boot on the stock vendor |
| `ro.vndk.version` | 29 (Android 10 vendor) | GSI must still support VNDK 29 (Android 11–13 GSIs do) |
| Kernel / userspace | Linux 4.9 `armv8l`, `zygote32` | Need an **ARM 32-bit** GSI with 64-bit binder (`gsi_tv_arm`) |
| `ro.boot.dynamic_partitions` | true, `super` = 2 GiB (`mmcblk0p4`) | GSI goes into `super`; must fit next to `vendor` |
| A/B | none (`slot_suffix` empty), system-as-root | "A-only" style flashing into `super` |
| `vbmeta`, `vbmeta_system`, `vbmeta_vendor` | present | Flash vbmeta with verification disabled |
| Build | `userdebug`, `ro.adb.secure=0`, `adb root` works | Easy root, easy debugging |
| DSU | `gsid` + `com.android.dynsystem` present | Can try a GSI **without touching stock** |
| Feature | `android.hardware.type.television` already declared | Vendor already TV-oriented |

## Reference port: lucagoc/H96Max-H313-lineageos

[lucagoc/H96Max-H313-lineageos](https://github.com/lucagoc/H96Max-H313-lineageos)
(Oct 2026) ships LineageOS 18.1 **Android TV 11** for the H96 Max H313. Its
vendor is the same Allwinner `cupid` platform, Android 10 / VNDK 29, 32-bit
userspace, 2 GiB `super` – i.e. the same BSP generation as this box. Method:

1. Unpack stock PhoenixSuit image (imgRePacker) → `super.fex` → `lpunpack`.
2. Replace `system` with a generic LineageOS 18.1 ATV GSI
   (AndyYan `a64_bvS`, ARM32 binder64; their `v0.0/system.img`).
3. Overlay layers with `debugfs` (files + SELinux labels): Magisk, Couchy
   launcher, IR keymaps, tweaks / ATV GMS core / full Google TV apps.
4. `lpmake` a new 2 GiB `super.fex`, repack the PhoenixSuit image.

Their repo has **no license** – we reference it and download its GSI, but write
our own build script and layers. Their `boot.img`, `boot-resource.fex` and
2 GB-RAM tuning are H313-specific and are **not** used here.

## Phases

### 0. Full stock backup – `scripts/backup-device.ps1`
Raw dump of every partition except `UDISK` plus the first 40 MiB of the eMMC
(boot0 / u-boot). Hashes in `device-info/stock/backup-sha256.txt`.
Also keep the official Tanix 2023 `.img` as a second recovery path.

### 1. Pick the GSI
Candidates (all ARM 32-bit, 64-bit binder):
- AOSP `gsi_tv_arm-userdebug` from Google's CI (`device/google/atv/products/gsi_tv_arm.mk`) – Android TV, no Google apps.
- Community Android TV GSIs (XDA "Android TV GSI built from AOSP and Lineage") – check for an `arm`/`a64` build.
- Build our own from AOSP `android13-gsi` with `lunch gsi_tv_arm-userdebug` if no prebuilt fits (Linux PC, ~300 GB disk).

### 2. Test without flashing (DSU)
```powershell
adb shell setprop persist.sys.fflag.override.settings_dynamic_system true
adb push system.img.gz /sdcard/Download/
adb shell am start-activity -n com.android.dynsystem/com.android.dynsystem.VerificationActivity `
  -a android.os.image.action.START_INSTALL -d file:///storage/emulated/0/Download/system.img.gz `
  --el KEY_SYSTEM_SIZE <bytes> --el KEY_USERDATA_SIZE 8589934592
```
Reboot into the GSI; a normal reboot returns to stock. Check: boot, Wi-Fi
(AP6330/bcmdhd), Bluetooth remote, IR remote, HDMI audio, video decode,
4K output. If DSU is refused (locked bootloader), go straight to phase 3
with the backup ready.

### 3. Flash for real
Via fastbootd (if the stock recovery supports it):
```powershell
adb reboot fastboot
fastboot flash system system.img
fastboot --disable-verity --disable-verification flash vbmeta vbmeta.img
fastboot -w
fastboot reboot
```
Otherwise, repack (phase 5) and flash with PhoenixSuit.

### 4. Fix-ups and Google TV layer
- Vendor overlays / props for anything broken in phase 2 (remote keymap, HDMI-CEC, audio).
- Google services for TV (ATV GApps) and the Google TV launcher / Google TV
  apps on top; set TV device props in `system/build.prop`.
- Expect **Widevine L3** (SD in Netflix/Prime) and Play Protect "uncertified" –
  the device was never Google-certified; register the GSF ID as uncertified device.

### 5. Package as a flashable firmware
Unpack the official Tanix `.img` with imgRePacker, replace `super.fex`
(built with `lpmake` from our `system` + stock `vendor`), repack, flash with
PhoenixSuit / PhoenixCard. Output: `firmware/TX6S-H_ATV_<date>.img`.

## Rollback
PhoenixSuit + official Tanix image, or write `backup/stock/*.img` back with
`fastboot flash` / `dd` as root.
