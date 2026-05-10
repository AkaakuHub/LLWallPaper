#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
PACKAGE_DIR="$ROOT_DIR/LLWallPaper.Mac"
VERSION="${1:-0.0.0}"
CONFIGURATION="${CONFIGURATION:-release}"
APP_NAME="LLWallPaper"
BUILD_ROOT="$PACKAGE_DIR/.build/apple"
DIST_DIR="$ROOT_DIR/dist/macos"
APP_DIR="$DIST_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
EXECUTABLE_PATH="$MACOS_DIR/LLWallPaperMac"
ICON_PATH="$ROOT_DIR/installer/macos/icon/LLWallPaper.icns"
DMG_STAGING_DIR="$(mktemp -d "${TMPDIR:-/tmp}/llwallpaper-dmg.XXXXXX")"
DMG_PATH="$ROOT_DIR/dist/LLWallPaper-macOS-$VERSION.dmg"
trap 'rm -rf "$DMG_STAGING_DIR"' EXIT

rm -rf "$DIST_DIR" "$DMG_PATH"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

swift build \
  --package-path "$PACKAGE_DIR" \
  -c "$CONFIGURATION" \
  --build-path "$PACKAGE_DIR/.build/apple" \
  --arch arm64 \
  --arch x86_64

BUILT_EXECUTABLE="$(find "$BUILD_ROOT" -path "*/Products/*/LLWallPaperMac" -type f | head -n 1)"
if [[ -z "$BUILT_EXECUTABLE" ]]; then
  echo "LLWallPaperMac executable was not found under $BUILD_ROOT." >&2
  exit 1
fi

cp "$BUILT_EXECUTABLE" "$EXECUTABLE_PATH"
cp "$ICON_PATH" "$RESOURCES_DIR/LLWallPaper.icns"

cat > "$CONTENTS_DIR/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>ja</string>
  <key>CFBundleDisplayName</key>
  <string>LLWallPaper</string>
  <key>CFBundleExecutable</key>
  <string>LLWallPaperMac</string>
  <key>CFBundleIconFile</key>
  <string>LLWallPaper.icns</string>
  <key>CFBundleIdentifier</key>
  <string>dev.akaaku.LLWallPaper</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>LLWallPaper</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$VERSION</string>
  <key>CFBundleVersion</key>
  <string>$VERSION</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>NSSupportsAutomaticTermination</key>
  <false/>
</dict>
</plist>
PLIST

if [[ -n "${MACOS_CODESIGN_IDENTITY:-}" ]]; then
  codesign --force --deep --options runtime --timestamp --sign "$MACOS_CODESIGN_IDENTITY" "$APP_DIR"
else
  codesign --force --deep --sign - "$APP_DIR"
fi

mkdir -p "$DMG_STAGING_DIR"
cp -R "$APP_DIR" "$DMG_STAGING_DIR/"
ln -s /Applications "$DMG_STAGING_DIR/Applications"
hdiutil create -volname "LLWallPaper" -srcfolder "$DMG_STAGING_DIR" -ov -format UDZO "$DMG_PATH"
echo "$DMG_PATH"
