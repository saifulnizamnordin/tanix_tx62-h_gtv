#!/bin/bash
# Unpack a built image again and report what is inside, so a build can be
# checked before flashing. Writes <image>.report.txt next to the image.
#
# Usage: rom/verify.sh rom/output/<image>.img
set -euo pipefail

ROM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMGREPACKER="${IMGREPACKER:-$ROM_DIR/upstream/lib/imgrepacker/imgrepacker}"
LPUNPACK="${LPUNPACK:-$ROM_DIR/tools/lpunpack/lpunpack.py}"
STOCK="$ROM_DIR/work/stock/base.img.dump"

IMG="$(realpath "$1")"
REPORT="$IMG.report.txt"
T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT

FAIL=0
check() {  # check <description> <command...>
    local desc="$1"; shift
    if "$@" >/dev/null 2>&1; then echo "PASS  $desc"; else echo "FAIL  $desc"; FAIL=1; fi
}
prop() {  # prop <image> <path> <key>
    debugfs -R "cat $2" "$1" 2>/dev/null | grep -m1 "^$3=" | cut -d= -f2-
}
exists() { debugfs -R "stat $2" "$1" 2>&1 | grep -q '^Inode:'; }

{
echo "# $(basename "$IMG")"
echo "sha256 $(sha256sum "$IMG" | cut -d' ' -f1)"
echo

cp "$IMG" "$T/out.img"
(cd "$T" && "$IMGREPACKER" out.img >/dev/null)
D="$T/out.img.dump"

echo "## Firmware parts identical to Tanix base (bootloader, kernel, env)"
for f in boot0_sdcard.fex boot0_nand.fex boot_package.fex toc1.fex u-boot.fex \
         boot.fex env.fex vbmeta.fex vbmeta_system.fex vbmeta_vendor.fex sys_config.fex; do
    [ -f "$STOCK/$f" ] || continue
    check "$f" cmp -s "$STOCK/$f" "$D/$f"
done
check "super.fex differs from stock (system replaced)" bash -c "! cmp -s '$STOCK/super.fex' '$D/super.fex'"
echo

echo "## super partitions"
if file "$D/super.fex" | grep -q 'sparse image'; then simg2img "$D/super.fex" "$T/super.raw"
else cp "$D/super.fex" "$T/super.raw"; fi
echo "super raw size: $(stat -c %s "$T/super.raw")"
mkdir "$T/parts"
python3 -W ignore "$LPUNPACK" "$T/super.raw" "$T/parts" >/dev/null
for p in "$T"/parts/*.img; do
    printf '  %-10s %6d MiB  fsck: %s\n' "$(basename "$p" .img)" $(( $(stat -c %s "$p") / 1048576 )) \
        "$(e2fsck -fn "$p" >/dev/null 2>&1 && echo clean || echo ERRORS)"
done
S="$T/parts/system.img"; V="$T/parts/vendor.img"
echo

echo "## system (GSI)"
for k in ro.build.version.release ro.lineage.version ro.build.characteristics \
         ro.product.cpu.abilist dalvik.vm.isa.arm.variant ro.adb.secure; do
    echo "  $k=$(prop "$S" /system/build.prop "$k")"
done
check "LineageOS 18.1 (Android 11)" test "$(prop "$S" /system/build.prop ro.build.version.release)" = 11
check "TV GSI: Leanback/TV packages present" bash -c "debugfs -R 'ls -l /system/priv-app' '$S' 2>/dev/null | grep -qi -e tv -e leanback"
check "tx6s first-boot script" exists "$S" /system/bin/tx6s_firstboot.sh
check "tx6s first-boot init rc" exists "$S" /system/etc/init/tx6s_firstboot.rc
echo

echo "## vendor (Tanix)"
for k in ro.board.platform ro.product.vendor.model ro.sf.lcd_density ro.config.low_ram ro.adb.secure persist.vendor.usb0device; do
    echo "  $k=$(prop "$V" /build.prop "$k")"
done
check "vendor platform is cupid (H616)" test "$(prop "$V" /build.prop ro.board.platform)" = cupid
check "Broadcom Wi-Fi driver bcmdhd.ko" bash -c "debugfs -R 'ls /lib/modules' '$V' 2>/dev/null | grep -q bcmdhd || debugfs -R 'ls /modules' '$V' 2>/dev/null | grep -q bcmdhd"
check "AP6330 firmware" bash -c "debugfs -R 'ls /etc/firmware' '$V' 2>/dev/null | grep -q -e ap6330 -e bcm40183"
echo

[ "$FAIL" = 0 ] && echo "RESULT: all checks passed" || echo "RESULT: SOME CHECKS FAILED - do not flash"
} 2>&1 | tee "$REPORT"
