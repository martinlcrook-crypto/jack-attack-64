#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WIN_DIR="$ROOT_DIR/windows"
WEB_FILE="$ROOT_DIR/web/index.html"
ICON_PNG="$ROOT_DIR/android/res/drawable/ic_launcher.png"
DIST_DIR="$ROOT_DIR/dist"
OUT_EXE="$DIST_DIR/jack-attack-64.exe"

mkdir -p "$WIN_DIR/assets" "$DIST_DIR"

echo "==> Copying web bundle into Windows embedded assets..."
cp "$WEB_FILE" "$WIN_DIR/assets/index.html"

echo "==> Generating 256x256 Windows .ico from pixel-art launcher icon..."
python3 - "$ICON_PNG" "$WIN_DIR/assets/favicon.ico" << 'PY'
import sys, struct, zlib

png_path, ico_path = sys.argv[1], sys.argv[2]
with open(png_path, "rb") as f:
    data = f.read()

# Parse 512x512 RGBA PNG and nearest-neighbor downsample 2x -> 256x256
pos = 8
idat = bytearray()
w = h = 0
while pos < len(data):
    length = struct.unpack(">I", data[pos:pos+4])[0]
    ctype = data[pos+4:pos+8]
    cdata = data[pos+8:pos+8+length]
    pos += 12 + length
    if ctype == b"IHDR":
        w, h = struct.unpack(">II", cdata[:8])
    elif ctype == b"IDAT":
        idat.extend(cdata)

raw = zlib.decompress(bytes(idat))
stride = w * 4 + 1
nw, nh = 256, 256
out_raw = bytearray()
for y in range(nh):
    sy = (y * h) // nh
    row_start = sy * stride + 1
    out_raw.append(0)
    for x in range(nw):
        sx = (x * w) // nw
        p = row_start + sx * 4
        out_raw.extend(raw[p:p+4])

def chunk(tag, payload):
    return struct.pack(">I", len(payload)) + tag + payload + struct.pack(">I", zlib.crc32(tag + payload) & 0xffffffff)

ihdr = struct.pack(">IIBBBBB", nw, nh, 8, 6, 0, 0, 0)
png256 = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IDAT", zlib.compress(bytes(out_raw), 9)) + chunk(b"IEND", b"")

header = struct.pack("<HHH", 0, 1, 1)
entry = struct.pack("<BBBBHHII", 0, 0, 0, 0, 1, 32, len(png256), 6 + 16)
with open(ico_path, "wb") as f:
    f.write(header + entry + png256)
print(f"Wrote 256x256 {ico_path} ({len(header)+len(entry)+len(png256)} bytes)")
PY

if command -v x86_64-w64-mingw32-windres >/dev/null 2>&1; then
  echo "==> Compiling Windows icon & version resources (.syso)..."
  (cd "$WIN_DIR" && x86_64-w64-mingw32-windres --preprocessor=gcc --preprocessor-arg=-E --preprocessor-arg=-xc --preprocessor-arg=-DRC_INVOKED -O coff -o rsrc_windows_amd64.syso jackattack.rc)
fi

echo "==> Cross-compiling standalone Windows x64 GUI executable..."
(cd "$WIN_DIR" && GOOS=windows GOARCH=amd64 CGO_ENABLED=0 go build -trimpath -ldflags="-H=windowsgui -s -w" -o "$OUT_EXE" .)

echo "==> Verifying Windows executable..."
file "$OUT_EXE"
ls -lh "$OUT_EXE"
echo "==> SUCCESS: Built $OUT_EXE"
