#!/bin/bash
set -euo pipefail

# Build the app and create a proper macOS .app bundle
# MenuBarExtra requires a bundled application to render in the menu bar.

# Always run from project root
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${PROJECT_DIR}"

APP_NAME="HomeManagerStatus"
BUILD_DIR=".build/release"
APP_BUNDLE="${APP_NAME}.app"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"

echo "Building release binary..."
swift build -c release

echo "Creating app bundle..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${MACOS_DIR}"

# Copy the binary
cp "${BUILD_DIR}/${APP_NAME}" "${MACOS_DIR}/${APP_NAME}"

# Create Info.plist
cat >"${CONTENTS_DIR}/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>HomeManagerStatus</string>
    <key>CFBundleIdentifier</key>
    <string>dev.nolith.HomeManagerStatus</string>
    <key>CFBundleName</key>
    <string>HomeManagerStatus</string>
    <key>CFBundleDisplayName</key>
    <string>Home Manager Status</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
PLIST

echo "Done! App bundle created at: ${APP_BUNDLE}"
echo ""
echo "To run:  open ${APP_BUNDLE}"
echo "To install: cp -r ${APP_BUNDLE} /Applications/"
