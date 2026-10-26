# TX6S-H LineageOS 18.1 Android TV ROM

Builds a PhoenixSuit image: official Tanix TX6S DDR3 firmware (2023-04-26,
bootloader/kernel/vendor) + LineageOS 18.1 Android TV GSI as `system` + the
layers in [`layers/`](layers/). Design notes: [../docs/custom-rom-plan.md](../docs/custom-rom-plan.md).

## Variants (`layers/layers.conf`)

| Variant | Contents |
|---|---|
| `vanilla_debug` | **Flash this first.** No Google apps; ADB on LAN without prompt + USB OTG ADB |
| `vanilla` | No Google apps |
| `gms_core` | Play Store + Google services |
| `gms_full` | Full Google Android TV: Google TV launcher, Assistant (Katniss), Cast, Gboard |

## Build (GitHub Actions)

GitHub → **Actions → Build ROM → Run workflow** → pick a variant. The image is
attached to a new pre-release (`build-<n>`).

## Build (Linux)

```bash
sudo apt install android-sdk-libsparse-utils e2fsprogs libc6:i386 libstdc++6:i386 zlib1g:i386
pip3 install gdown          # plus lpmake in PATH
bash rom/fetch.sh
bash rom/build.sh --variant vanilla_debug   # or --all
```

## Layers

A layer folder may contain `system/`, `vendor/`, `product/` file trees,
`remove.list` (paths to delete), `selinux.list` (`<path> <context>`), and
`props/<partition>.prop` (`key=value` merged into that partition's
`build.prop`, `@VERSION@` expanded). `upstream:<name>` reuses a layer from
[lucagoc/H96Max-H313-lineageos](https://github.com/lucagoc/H96Max-H313-lineageos)
at the commit pinned in `fetch.sh` (its `build.prop` files are ignored).
