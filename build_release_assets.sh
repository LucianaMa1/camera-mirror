#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="Camera Mirror"
APP_PATH="$SCRIPT_DIR/$APP_NAME.app"
BUILD_DIR="$SCRIPT_DIR/.build"
RELEASE_DIR="$SCRIPT_DIR/release"
DMG_PATH="$RELEASE_DIR/Camera-Mirror-macOS.dmg"
ZIP_PATH="$RELEASE_DIR/Camera-Mirror-macOS.zip"
DMG_STAGING_DIR="$BUILD_DIR/dmg-staging"

"$SCRIPT_DIR/build_camera_mirror_app.sh"

mkdir -p "$RELEASE_DIR"
rm -f "$DMG_PATH" "$ZIP_PATH"
rm -rf "$DMG_STAGING_DIR"
mkdir -p "$DMG_STAGING_DIR"

# Remove quarantine if present so the packaged app is cleaner for users.
xattr -cr "$APP_PATH" 2>/dev/null || true

echo "Building ZIP release asset..."
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_PATH"

echo "Building DMG release asset..."
rm -rf "$DMG_STAGING_DIR/$APP_NAME.app"
cp -R "$APP_PATH" "$DMG_STAGING_DIR/$APP_NAME.app"
rm -f "$DMG_STAGING_DIR/$APP_NAME.app/Icon"$'\r' 2>/dev/null || true

if hdiutil create \
  -volname "Camera Mirror" \
  -srcfolder "$DMG_STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH" >/dev/null; then
  echo "$DMG_PATH"
else
  echo "DMG packaging failed on this machine; ZIP asset is still ready for release."
fi

echo "Release assets:"
echo "$ZIP_PATH"
if [[ -f "$DMG_PATH" ]]; then
  echo "$DMG_PATH"
fi
