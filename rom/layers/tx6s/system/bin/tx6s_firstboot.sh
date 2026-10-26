#!/system/bin/sh
# One-time setup after the first boot of the TX6S-H ATV ROM.
# Installs APKs from /system/etc/pre_install and runs /system/etc/pre_install.d hooks.

MARKER=/data/.tx6s_firstboot_done
LOG=/data/tx6s_firstboot.log
[ -f "$MARKER" ] && exit 0

exec >> "$LOG" 2>&1
echo "=== first boot setup $(date) ==="

until pm path android >/dev/null 2>&1; do sleep 2; done
sleep 3

settings put global auto_time 1
settings put global auto_time_zone 0
# Allwinner audio HAL has no IEC61937 passthrough: keep PCM output
settings put global encoded_surround_output 1
settings put global encoded_surround_output_enabled_formats ""
wm density 320

APK_DIR=/system/etc/pre_install
for apk in "$APK_DIR"/*.apk; do
    [ -f "$apk" ] && echo "install $apk: $(pm install -g -r -d "$apk" 2>&1)"
done
for dir in "$APK_DIR"/*/; do
    [ -d "$dir" ] || continue
    echo "install $dir: $(pm install -g -r -d "$dir"*.apk 2>&1)"
done

for hook in /system/etc/pre_install.d/*.sh; do
    [ -f "$hook" ] && echo "hook $hook" && /system/bin/sh "$hook"
done

touch "$MARKER"
echo "=== done $(date) ==="
