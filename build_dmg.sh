#!/bin/bash
set -e

APP_NAME="MacBoary"
SCHEME="macboary"
BUILD_DIR="build"
ARCHIVE_PATH="$BUILD_DIR/$APP_NAME.xcarchive"
EXPORT_PATH="$BUILD_DIR/Export"
DMG_PATH="$BUILD_DIR/$APP_NAME.dmg"

# Clean
echo "🧹 Cleaning..."
rm -rf "$BUILD_DIR"
xcodebuild clean -scheme "$SCHEME" -destination 'generic/platform=macOS'

# Archive
echo "📦 Archiving..."
xcodebuild archive \
  -scheme "$SCHEME" \
  -destination 'generic/platform=macOS' \
  -archivePath "$ARCHIVE_PATH" \
  -configuration Release \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO

# Export
echo "📤 Exporting..."
# Create ExportOptions.plist manually if needed, or just copy the app
mkdir -p "$EXPORT_PATH"
cp -r "$ARCHIVE_PATH/Products/Applications/$APP_NAME.app" "$EXPORT_PATH/$APP_NAME.app"

# Explicitly re-sign with entitlements to ensure TCC stability
echo "🔏 Signing with entitlements..."
codesign --force --deep --sign - --entitlements macboary/macboary.entitlements "$EXPORT_PATH/$APP_NAME.app"

# Create DMG
echo "💿 Creating DMG..."
mkdir -p "$BUILD_DIR/dmg_root"
cp -r "$EXPORT_PATH/$APP_NAME.app" "$BUILD_DIR/dmg_root/"
ln -s /Applications "$BUILD_DIR/dmg_root/Applications"

# Create DMG (Optimized: HFS+ filesystem, LZFSE compression)
hdiutil create -volname "$APP_NAME" -srcfolder "$BUILD_DIR/dmg_root" -ov -fs HFS+ -format ULFO "$DMG_PATH"

echo "✅ DMG created at $DMG_PATH"
open "$BUILD_DIR"
