#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/.build"
APP_BIN="$BUILD_DIR/camera-mirror"
SOURCE_FILE="$SCRIPT_DIR/main.m"

mkdir -p "$BUILD_DIR"

if [[ ! -f "$APP_BIN" || "$SOURCE_FILE" -nt "$APP_BIN" ]]; then
  echo "Compiling Camera Mirror..."
  clang \
    -fobjc-arc \
    -framework AppKit \
    -framework AVFoundation \
    -framework QuartzCore \
    "$SOURCE_FILE" \
    -o "$APP_BIN"
fi

exec "$APP_BIN"
