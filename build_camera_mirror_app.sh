#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/.build"
APP_NAME="Camera Mirror"
APP_DIR="$SCRIPT_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
BIN_PATH="$BUILD_DIR/camera-mirror"
ICON_GEN_BIN="$BUILD_DIR/generate-icon"
ICON_PNG="$BUILD_DIR/camera-mirror-icon-1024.png"
ICONSET_DIR="$BUILD_DIR/AppIcon.iconset"
ICNS_PATH="$RESOURCES_DIR/AppIcon.icns"
ICON_EXPORT_PATH="$SCRIPT_DIR/camera-mirror-icon-1024.png"
RSRC_PATH="$BUILD_DIR/appicon.rsrc"
FINDER_ICON_FILE="$APP_DIR/Icon"$'\r'

mkdir -p "$BUILD_DIR" "$MACOS_DIR" "$RESOURCES_DIR"

echo "Compiling Camera Mirror binary..."
clang \
  -fobjc-arc \
  -framework AppKit \
  -framework AVFoundation \
  -framework QuartzCore \
  "$SCRIPT_DIR/main.m" \
  -o "$BIN_PATH"

echo "Compiling icon generator..."
clang \
  -fobjc-arc \
  -framework AppKit \
  "$SCRIPT_DIR/generate_icon.m" \
  -o "$ICON_GEN_BIN"

echo "Generating app icon..."
"$ICON_GEN_BIN" "$ICON_PNG"
cp "$ICON_PNG" "$ICON_EXPORT_PATH"

rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR"

for size in 16 32 128 256 512; do
  sips -z "$size" "$size" "$ICON_PNG" --out "$ICONSET_DIR/icon_${size}x${size}.png" >/dev/null
  retina_size=$((size * 2))
  sips -z "$retina_size" "$retina_size" "$ICON_PNG" --out "$ICONSET_DIR/icon_${size}x${size}@2x.png" >/dev/null
done

cp "$ICON_PNG" "$ICONSET_DIR/icon_1024x1024.png"

if iconutil -c icns "$ICONSET_DIR" -o "$ICNS_PATH"; then
  echo "Generated .icns app icon."
else
  echo "iconutil could not build .icns on this machine; keeping exported PNG icon at:"
  echo "$ICON_EXPORT_PATH"
fi

cp "$BIN_PATH" "$MACOS_DIR/camera-mirror"
chmod +x "$MACOS_DIR/camera-mirror"

cat > "$CONTENTS_DIR/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleDisplayName</key>
  <string>Camera Mirror</string>
  <key>CFBundleExecutable</key>
  <string>camera-mirror</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundleIdentifier</key>
  <string>com.luciana.camera-mirror</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>Camera Mirror</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>12.0</string>
  <key>NSCameraUsageDescription</key>
  <string>Camera Mirror uses the camera to show your face while you record your screen.</string>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

if [[ ! -f "$ICNS_PATH" ]]; then
  echo "Applying Finder custom icon fallback..."
  rm -f "$RSRC_PATH"
  rm -f "$FINDER_ICON_FILE"
  sips -i "$ICON_EXPORT_PATH" >/dev/null
  DeRez -only icns "$ICON_EXPORT_PATH" > "$RSRC_PATH"
  Rez -append "$RSRC_PATH" -o "$FINDER_ICON_FILE"
  SetFile -a V "$FINDER_ICON_FILE"
  SetFile -a C "$APP_DIR"
fi

echo "Built app bundle:"
echo "$APP_DIR"
echo "Exported PNG icon:"
echo "$ICON_EXPORT_PATH"
