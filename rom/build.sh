#!/bin/bash
# Build a LineageOS 18.1 Android TV PhoenixSuit image for the Tanix TX6S-H
# (Allwinner H616, DDR3) from:
#   - the official Tanix firmware (bootloader, kernel, vendor, product)
#   - a generic LineageOS 18.1 ATV GSI (ARM32 / binder64) as system
#   - overlay layers listed in layers/layers.conf
#
# Usage: rom/build.sh [--variant <name> | --all]
# Needs: imgrepacker, simg2img, lpmake, lpunpack.py, e2fsprogs (debugfs), python3
set -euo pipefail

ROM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK="$ROM_DIR/work"
OUT="$ROM_DIR/output"
DL="$ROM_DIR/downloads"
UPSTREAM="$ROM_DIR/upstream"          # lucagoc/H96Max-H313-lineageos checkout
LAYERS_CONF="$ROM_DIR/layers/layers.conf"

IMGREPACKER="${IMGREPACKER:-$UPSTREAM/lib/imgrepacker/imgrepacker}"
LPUNPACK="${LPUNPACK:-$ROM_DIR/tools/lpunpack/lpunpack.py}"

BASE_IMG="$DL/base.img"
GSI_IMG="$DL/system.img"
DEVICE="TX6S-H"

log() { echo "[$(date +%H:%M:%S)] $*"; }
die() { echo "[!] $*" >&2; exit 1; }

# ------------------------------------------------------------------------------
# Variants
# ------------------------------------------------------------------------------
declare -A VARIANTS
ORDER=()
while IFS= read -r line || [ -n "$line" ]; do
    [[ "$line" =~ ^[[:space:]]*(#|$) ]] && continue
    [[ "$line" =~ ^([A-Za-z0-9_-]+)[[:space:]]*=[[:space:]]*(.*)$ ]] || continue
    VARIANTS["${BASH_REMATCH[1]}"]="${BASH_REMATCH[2]}"
    ORDER+=("${BASH_REMATCH[1]}")
done < "$LAYERS_CONF"

SELECTED=()
case "${1:-}" in
    --all)     SELECTED=("${ORDER[@]}") ;;
    --variant) SELECTED=("${2:?variant name required}") ;;
    "")        SELECTED=("${ORDER[0]}") ;;
    *)         die "usage: $0 [--variant <${ORDER[*]}> | --all]" ;;
esac

for tool in simg2img lpmake debugfs e2fsck resize2fs python3; do
    command -v "$tool" >/dev/null || die "$tool not found"
done
[ -x "$IMGREPACKER" ] || die "imgrepacker not found at $IMGREPACKER"
[ -f "$LPUNPACK" ]    || die "lpunpack.py not found at $LPUNPACK"
[ -f "$BASE_IMG" ]    || die "missing $BASE_IMG (run rom/fetch.sh)"
[ -f "$GSI_IMG" ]     || die "missing $GSI_IMG (run rom/fetch.sh)"

# ------------------------------------------------------------------------------
# Stock: unpack the Tanix image once and split super into partitions
# ------------------------------------------------------------------------------
STOCK="$WORK/stock"
if [ ! -f "$STOCK/.done" ]; then
    log "Unpacking base firmware"
    rm -rf "$STOCK"; mkdir -p "$STOCK/parts"
    cp "$BASE_IMG" "$STOCK/base.img"
    (cd "$STOCK" && "$IMGREPACKER" base.img)
    [ -f "$STOCK/base.img.dump/super.fex" ] || die "super.fex not found in base image"

    if file "$STOCK/base.img.dump/super.fex" | grep -q 'sparse image'; then
        simg2img "$STOCK/base.img.dump/super.fex" "$STOCK/super.raw"
    else
        cp --sparse=always "$STOCK/base.img.dump/super.fex" "$STOCK/super.raw"
    fi
    python3 "$LPUNPACK" "$STOCK/super.raw" "$STOCK/parts"
    rm "$STOCK/base.img"
    touch "$STOCK/.done"
fi
SUPER_SIZE=$(stat -c %s "$STOCK/super.raw")
log "Stock super: $SUPER_SIZE bytes, partitions: $(cd "$STOCK/parts" && ls)"
ls -l "$STOCK/base.img.dump"

# ------------------------------------------------------------------------------
# Image helpers (debugfs edits ext4 images in place, no root/loop mounts needed)
# ------------------------------------------------------------------------------
# Path of a partition-relative file inside its image. system is system-as-root,
# so its files live under /system inside the image.
img_path() { [ "$1" = system ] && echo "/system/$2" || echo "/$2"; }

dfs() { debugfs -w -R "$2" "$1" >/dev/null 2>&1 || true; }

default_ctx() { [ "$1" = vendor ] && echo u:object_r:vendor_file:s0 || echo u:object_r:system_file:s0; }

# write_file <part> <host file> <rel path> <selinux ctx>
write_file() {
    local part="$1" src="$2" rel="$3" ctx="$4" img="$P/$1.img"
    local dst; dst="$(img_path "$part" "$rel")"
    local dir="" seg
    IFS=/ read -ra segs <<< "$(dirname "$dst" | sed 's|^/||')"
    for seg in "${segs[@]}"; do
        dir="$dir/$seg"
        dfs "$img" "mkdir $dir"
        dfs "$img" "ea_set $dir security.selinux $(default_ctx "$part")"
    done
    dfs "$img" "rm $dst"
    debugfs -w -R "write $src $dst" "$img" >/dev/null 2>&1 || die "debugfs write failed: $dst"
    local mode=0100644
    [[ "$rel" == bin/* || -x "$src" ]] && mode=0100755
    dfs "$img" "set_inode_field $dst mode $mode"
    dfs "$img" "set_inode_field $dst uid 0"
    dfs "$img" "set_inode_field $dst gid 0"
    dfs "$img" "ea_set $dst security.selinux $ctx"
    echo "      + $part:$dst [$ctx]"
}

# rm_tree <img> <path> : delete a file or a directory tree inside an image.
# "ls -p" prints /inode/mode/uid/gid/name/size/ ; directory modes start with 04.
rm_tree() {
    local img="$1" path="$2" mode name
    while IFS=/ read -r _ _ mode _ _ name _; do
        [[ -z "$name" || "$name" == . || "$name" == .. ]] && continue
        if [[ "$mode" == 04* ]]; then rm_tree "$img" "$path/$name"
        else dfs "$img" "rm $path/$name"; fi
    done < <(debugfs -R "ls -p $path" "$img" 2>/dev/null)
    dfs "$img" "rmdir $path"
    dfs "$img" "rm $path"
}

remove_path() {
    local part="$1" rel="$2"
    local dst; dst="$(img_path "$part" "$rel")"
    rm_tree "$P/$part.img" "$dst"
    echo "      - $part:$dst"
}

# set_prop <part> <key> <value> : replace or append in the partition's build.prop
set_prop() {
    local part="$1" key="$2" val="$3" img="$P/$1.img" tmp="$P/.prop.$1"
    local f; f="$(img_path "$part" build.prop)"
    debugfs -R "dump $f $tmp" "$img" >/dev/null 2>&1 || : > "$tmp"
    if grep -q "^${key}=" "$tmp"; then
        sed -i "s|^${key}=.*|${key}=${val}|" "$tmp"
    else
        echo "${key}=${val}" >> "$tmp"
    fi
    write_file "$part" "$tmp" build.prop "$(default_ctx "$part")" >/dev/null
    rm -f "$tmp"
}

# Resolve a layer name to a directory. "upstream:<name>" uses lucagoc's layer.
layer_dir() {
    case "$1" in
        upstream:*) echo "$UPSTREAM/layers/${1#upstream:}/super" ;;
        *)          echo "$ROM_DIR/layers/$1" ;;
    esac
}

apply_layer() {
    local name="$1" dir; dir="$(layer_dir "$1")"
    [ -d "$dir" ] || die "layer not found: $name ($dir)"
    log "  layer $name"

    declare -A ctx=()
    local path c
    if [ -f "$dir/selinux.list" ]; then
        while read -r path c; do
            [[ -z "$path" || "$path" == \#* ]] && continue
            ctx["$path"]="$c"
        done < "$dir/selinux.list"
    fi

    if [ -f "$dir/remove.list" ]; then
        while read -r path; do
            [[ -z "$path" || "$path" == \#* ]] && continue
            path="${path#/}"
            remove_path "${path%%/*}" "${path#*/}"
        done < "$dir/remove.list"
    fi

    local part rel f
    for part in system vendor product; do
        [ -d "$dir/$part" ] || continue
        [ -f "$P/$part.img" ] || die "layer $name targets missing partition $part"
        while IFS= read -r -d '' f; do
            rel="${f#"$dir/$part/"}"
            [ "$rel" = build.prop ] && [ "$name" != "${name#upstream:}" ] && continue  # never take H313 build.props
            write_file "$part" "$f" "$rel" "${ctx[/$part/$rel]:-$(default_ctx "$part")}"
        done < <(find "$dir/$part" -type f ! -name 'README*' -print0)
    done

    # props/<part>.prop : key=value lines merged into that partition's build.prop;
    # @VERSION@ is replaced with the build version.
    if [ -d "$dir/props" ]; then
        local line val
        for f in "$dir"/props/*.prop; do
            part="$(basename "$f" .prop)"
            while IFS= read -r line || [ -n "$line" ]; do
                [[ -z "$line" || "$line" == \#* ]] && continue
                val="${line#*=}"
                set_prop "$part" "${line%%=*}" "${val//@VERSION@/$VERSION}"
                echo "      = $part:${line%%=*}"
            done < "$f"
        done
    fi
}

# ------------------------------------------------------------------------------
# Build one variant
# ------------------------------------------------------------------------------
build_variant() {
    local variant="$1" layers_raw="${VARIANTS[$1]:-}"
    [ -n "$layers_raw" ] || die "unknown variant '$variant' (have: ${ORDER[*]})"
    IFS=', ' read -ra layers <<< "$layers_raw"

    local date_tag; date_tag="$(date +%Y%m%d)"
    VERSION="18.1-${date_tag}-UNOFFICIAL-${DEVICE}-${variant}"
    local final="$OUT/lineage-${VERSION}.img"
    P="$WORK/$variant"
    rm -rf "$P"; mkdir -p "$P" "$OUT"

    log "=== $variant: ${layers[*]}"

    # system from the GSI, everything else from stock
    if file "$GSI_IMG" | grep -q 'sparse image'; then simg2img "$GSI_IMG" "$P/system.img"
    else cp --sparse=always "$GSI_IMG" "$P/system.img"; fi
    local img part
    for img in "$STOCK"/parts/*.img; do
        part="$(basename "$img" .img)"
        [ "$part" = system ] && continue
        cp --sparse=always "$img" "$P/$part.img"
    done

    # Headroom for overlays; shrunk back to minimum before lpmake.
    for img in "$P"/*.img; do
        truncate -s +600M "$img"
        e2fsck -fy "$img" >/dev/null 2>&1 || true
        resize2fs "$img" >/dev/null 2>&1
    done

    log "Applying layers"
    local l
    for l in "${layers[@]}"; do apply_layer "$l"; done

    log "Shrinking partitions"
    for img in "$P"/*.img; do
        e2fsck -fy "$img" >/dev/null 2>&1 || true
        resize2fs -M "$img" >/dev/null 2>&1
        e2fsck -fy "$img" >/dev/null 2>&1 || true
        # keep 32 MiB free so the system can write its runtime files
        truncate -s +32M "$img"; resize2fs "$img" >/dev/null 2>&1
        echo "      $(basename "$img"): $(( $(stat -c %s "$img") / 1048576 )) MiB"
    done

    log "Building super.fex ($SUPER_SIZE bytes)"
    local args=(--metadata-size 65536 --super-name super --metadata-slots 2
                --device "super:$SUPER_SIZE" --group "main:$((SUPER_SIZE - 4194304))"
                --sparse --output "$P/super.fex")
    for img in "$P"/*.img; do
        part="$(basename "$img" .img)"
        args+=(--partition "$part:readonly:$(stat -c %s "$img"):main" --image "$part=$img")
    done
    lpmake "${args[@]}"

    log "Repacking PhoenixSuit image"
    rm -rf "$P/pack"; mkdir -p "$P/pack"
    cp -r "$STOCK/base.img.dump" "$P/pack/base.img.dump"
    cp "$P/super.fex" "$P/pack/base.img.dump/super.fex"
    (cd "$P/pack" && "$IMGREPACKER" base.img.dump)
    mv "$P/pack/base.img" "$final"
    (cd "$OUT" && sha256sum "$(basename "$final")" > "$(basename "$final").sha256")
    rm -rf "$P"
    log "Done: $final ($(du -h "$final" | cut -f1))"
}

for v in "${SELECTED[@]}"; do build_variant "$v"; done
