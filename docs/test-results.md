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
| IR remote | ❌ build-4 → ✅ build-5 | kernel `sunxi-ir` emits only `MSC_SCAN` (address `4040`); stock `multi_ir` daemon + `customer_ir_4040.kl` were in the old system partition → `tx6s-ir` layer |
| USB keyboard | ✅ | SONiX / BESCO detected |
| HDMI audio | ⏳ test | HAL exposes `AUDIO_DEVICE_OUT_HDMI`; route shows `SPEAKER` |
| First-boot script | ✅ | `/data/.tx6s_firstboot_done` |
| SELinux | Permissive | from stock kernel cmdline |
| Video playback, 4K, HDMI-CEC, standby | ⏳ test | |

### IR remote codes (address 0x4040, NEC)

`MSC_SCAN 01404xx` = press, `00404xx` = release.

| Button | Up | Down | Left | Right | OK | Back | Home | Menu | Vol+ | Vol− | Power |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Code | 0x0b | 0x0e | 0x10 | 0x11 | 0x0d | 0x42 | 0x1a | 0x45 | 0x18 | 0x17 | 0x4d |

## build-5 `vanilla_debug` (2026-10-26 21:23, IR fix)

Flashed over build-4 with PhoenixSuit **format = No**: Wi-Fi and setup kept.

| Area | Result | Evidence |
|---|---|---|
| `multi_ir` service | ✅ | `init.svc.multi_ir=running`, domain `u:r:multi_ir:s0` |
| IR → Android keys | ✅ | `sunxi-ir-uinput` with `sunxi-ir-uinput.kl`; Up/Down/Left/Right/OK/Back/Home/Vol± arrive as Linux keys 19–23, 4, 3, 24, 25 = DPAD_*, BACK, HOME, VOLUME_* |
| Data kept on reflash | ✅ | `user_setup_complete=1`, Wi-Fi reconnected |
