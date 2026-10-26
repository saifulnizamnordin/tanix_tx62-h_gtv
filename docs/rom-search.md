# ROM search results (2026-10-26)

Target: Allwinner H616 (`sun50iw9p1`), 4 GB / 64 GB, Broadcom AP6330 Wi-Fi.

## Result: no Google TV ROM found for this box

Searched XDA, 4PDA (T95 H616, Tanix TX6, Transpeed H40 threads), the
`t.me/atvfirm` firmware channel, androidtvbox.eu, needrom and the Tanix
firmware centre. Every H616 image found is **regular Android 10** (phone-style
Android with a TV launcher), not Android TV or Google TV. XDA users asking for
Android TV on the TX6S got no working answer.

Why nobody has built one: Google TV needs a Google-licensed build, a 64-bit
userspace and Widevine L1 keys provisioned at the factory. This box ships
32-bit Android 10 with test-keys, so a "real" GTV port would mean porting a
GTV system image from another device onto the H616 BSP – nobody has published
one.

## Firmware that does exist (all Android 10, non-ATV)

| Firmware | Date | Source | Notes |
|---|---|---|---|
| Tanix TX6S official | 2023-04-26 | [Tanix firmware centre](https://www.tanixtvbox.com/firmware-centre/) → [Google Drive](https://drive.google.com/drive/folders/1g834P9UZaf7YTlzWwfgjb7jhlyZzQ29O) | Newest official build; ours is 2020-12-19. Best "safe upgrade". |
| Tanix TX6S official | 2020-07-30 | [androidtvbox.eu](https://androidtvbox.eu/tanix-tx6s-firmware-for-tv-box-with-allwinner-h616-soc-20200730/) | Recovery image |
| TX6s Oranth H616 | 2020-10-22 | [XDA thread](https://xdaforums.com/t/allwinner-h616-tx6s.4043863/) | Same "Oranth" vendor as this unit (OTA URL `oranthservice.com`) – reported working on TX6S 4G/64G |
| Other H616 boxes (T95, H96 Max, Transpeed H40) | 2020–2022 | androidtvbox.eu / needrom | **Different boards** – XDA reports lost Wi-Fi/BT/remote after cross-flashing. Avoid. |

## Practical options

1. **Upgrade to the 2023 official Tanix image** (still Android 10).
2. **Make stock look/feel like Google TV**: install a TV launcher
   (Projectivy Launcher or FLauncher) plus the TV versions of apps, and disable
   the stock launcher with ADB. Netflix/Prime will be SD only (Widevine L3).
3. **Real Google TV**: a certified device (Chromecast with Google TV,
   Xiaomi TV Box S, onn. 4K, etc.) – the only way to get Widevine L1/HD streaming.
