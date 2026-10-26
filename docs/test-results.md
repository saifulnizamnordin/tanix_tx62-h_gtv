# Hardware test results

## build-4 `vanilla_debug` (LineageOS 18.1 ATV, 2026-10-26)

Flashed with PhoenixSuit V1.19 (auto-started on detection). First boot to
setup wizard: OK.

| Area | Result | Evidence |
|---|---|---|
| Boot | ✅ | `sys.boot_completed=1`, LineageOS boot animation → setup wizard |
| Wi-Fi AP6330 (bcmdhd) | ✅ | `wlan0` up, associated, DHCP 192.168.100.10 |
| Bluetooth | ✅ on | `bluetooth_manager state: ON`; setup wizard accessory search runs |
| GPU Mali-G31 | ✅ | EGL `Bifrost r20p0-01rel0` |
| HW video decode | ✅ listed | `OMX.allwinner.video.decoder.{avc,hevc,vp9,mpeg2,mpeg4,vc1,…}` |
| Display | ✅ | 1920x1080, density 320 |
| IR remote | ✅ device | `sunxi-ir` input device |
| USB keyboard | ✅ | SONiX / BESCO detected |
| HDMI audio | ⏳ test | HAL exposes `AUDIO_DEVICE_OUT_HDMI`; route shows `SPEAKER` |
| First-boot script | ✅ | `/data/.tx6s_firstboot_done` |
| SELinux | Permissive | from stock kernel cmdline |
| Video playback, 4K, HDMI-CEC, standby | ⏳ test | |
