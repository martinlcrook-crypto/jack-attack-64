#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ANDROID_DIR="$ROOT_DIR/android"
WEB_FILE="$ROOT_DIR/web/index.html"
BUILD_DIR="$ANDROID_DIR/build"
DIST_DIR="$ROOT_DIR/dist"

SDK="${ANDROID_HOME:-/opt/android-sdk}"
BUILD_TOOLS="$SDK/build-tools/35.0.0"
PLATFORM_JAR="$SDK/platforms/android-35/android.jar"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/res_compiled" "$BUILD_DIR/gen" "$BUILD_DIR/classes" "$BUILD_DIR/dex" "$BUILD_DIR/assets" "$DIST_DIR"

echo "==> Copying web bundle into Android assets..."
cp "$WEB_FILE" "$BUILD_DIR/assets/index.html"

echo "==> Compiling Android resources with aapt2..."
"$BUILD_TOOLS/aapt2" compile --dir "$ANDROID_DIR/res" -o "$BUILD_DIR/res_compiled/resources.zip"

echo "==> Linking base APK & generating R.java..."
"$BUILD_TOOLS/aapt2" link \
  -I "$PLATFORM_JAR" \
  --manifest "$ANDROID_DIR/AndroidManifest.xml" \
  -A "$BUILD_DIR/assets" \
  -o "$BUILD_DIR/unaligned.apk" \
  --java "$BUILD_DIR/gen" \
  "$BUILD_DIR/res_compiled/resources.zip"

echo "==> Compiling Java sources..."
javac --release 11 \
  -classpath "$PLATFORM_JAR" \
  -d "$BUILD_DIR/classes" \
  "$ANDROID_DIR/src/com/retro/jackattack/MainActivity.java" \
  "$BUILD_DIR/gen/com/retro/jackattack/R.java"

echo "==> Converting bytecode to DEX with d8..."
"$BUILD_TOOLS/d8" \
  --lib "$PLATFORM_JAR" \
  --min-api 24 \
  --output "$BUILD_DIR/dex" \
  $(find "$BUILD_DIR/classes" -name "*.class")

echo "==> Packaging classes.dex into APK..."
(cd "$BUILD_DIR/dex" && zip -q -u "$BUILD_DIR/unaligned.apk" classes.dex)

echo "==> Aligning APK with zipalign..."
"$BUILD_TOOLS/zipalign" -f -p 4 "$BUILD_DIR/unaligned.apk" "$BUILD_DIR/aligned.apk"

KEYSTORE="$ANDROID_DIR/jackattack-debug.keystore"
if [[ ! -f "$KEYSTORE" ]]; then
  echo "==> Generating signing keystore..."
  keytool -genkeypair -v \
    -keystore "$KEYSTORE" \
    -storepass android \
    -alias jackattack \
    -keypass android \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000 \
    -dname "CN=Jack Attack 64, OU=Retro, O=Commodore Tribute, L=Web, S=CA, C=US"
fi

OUT_APK="$DIST_DIR/jack-attack.apk"
echo "==> Signing APK with apksigner..."
"$BUILD_TOOLS/apksigner" sign \
  --ks "$KEYSTORE" \
  --ks-pass pass:android \
  --key-pass pass:android \
  --ks-key-alias jackattack \
  --out "$OUT_APK" \
  "$BUILD_DIR/aligned.apk"

echo "==> Verifying APK signature..."
"$BUILD_TOOLS/apksigner" verify --verbose "$OUT_APK"

echo "==> APK badging info:"
"$BUILD_TOOLS/aapt2" dump badging "$OUT_APK" | head -n 12
ls -lh "$OUT_APK"
echo "==> SUCCESS: Built $OUT_APK"
