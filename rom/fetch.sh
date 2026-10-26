#!/bin/bash
# Download build inputs into rom/downloads and tools into rom/upstream, rom/tools.
set -euo pipefail
ROM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DL="$ROM_DIR/downloads"
mkdir -p "$DL" "$ROM_DIR/tools"

# Official Tanix TX6S DDR3 firmware 2023-04-26 (Oranth, cupid_p1) - Google Drive file
BASE_GDRIVE_ID=1Y1nAj0_-068WLXAQtxaSBdj3RbdteFdT
BASE_SHA256=""
# LineageOS 18.1 ATV GSI (AndyYan a64_bvS, ARM32 binder64) as published by lucagoc
GSI_URL=https://github.com/lucagoc/H96Max-H313-lineageos/releases/download/v0.0/system.img
GSI_SHA256=""

UPSTREAM_REPO=https://github.com/lucagoc/H96Max-H313-lineageos.git
UPSTREAM_SHA=327433fd830187b57a0368c2450c867abfc2e133
LPUNPACK_REPO=https://github.com/unix3dgforce/lpunpack.git
LPUNPACK_SHA=c59b8f3b069c5a8aa438a049fa4a091177172434

checkout() {  # checkout <repo> <sha> <dir>
    [ -d "$3/.git" ] || git clone --filter=blob:none "$1" "$3"
    git -C "$3" checkout -q "$2"
}

verify() {  # verify <file> <sha256 or empty>
    local got; got="$(sha256sum "$1" | cut -d' ' -f1)"
    echo "    sha256 $got  $(basename "$1")"
    [ -z "$2" ] || [ "$got" = "$2" ] || { echo "[!] checksum mismatch for $1"; exit 1; }
}

if [ ! -f "$DL/base.img" ]; then
    echo "[*] Tanix base firmware (Google Drive)"
    python3 -m gdown "$BASE_GDRIVE_ID" -O "$DL/base.img"
fi
verify "$DL/base.img" "$BASE_SHA256"

if [ ! -f "$DL/system.img" ]; then
    echo "[*] LineageOS ATV GSI"
    curl -fL --retry 3 -o "$DL/system.img" "$GSI_URL"
fi
verify "$DL/system.img" "$GSI_SHA256"

echo "[*] upstream layers + imgRePacker @ $UPSTREAM_SHA"
checkout "$UPSTREAM_REPO" "$UPSTREAM_SHA" "$ROM_DIR/upstream"
chmod +x "$ROM_DIR/upstream/lib/imgrepacker/imgrepacker"
echo "[*] lpunpack @ $LPUNPACK_SHA"
checkout "$LPUNPACK_REPO" "$LPUNPACK_SHA" "$ROM_DIR/tools/lpunpack"
