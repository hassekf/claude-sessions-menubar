#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

echo "→ swift build -c release"
swift build -c release

BIN_DIR="$(swift build -c release --show-bin-path)"
BIN="$BIN_DIR/ClaudeSessions"
APP="./build/ClaudeSessions.app"

if [ ! -f "$BIN" ]; then
    echo "✗ binary not found at $BIN"
    exit 1
fi

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp "$BIN" "$APP/Contents/MacOS/ClaudeSessions"
chmod +x "$APP/Contents/MacOS/ClaudeSessions"

# SPM resource bundle (claude.svg) — carry along if present
BUNDLE="$BIN_DIR/ClaudeSessions_ClaudeSessions.bundle"
if [ -d "$BUNDLE" ]; then
    cp -R "$BUNDLE" "$APP/Contents/Resources/"
fi

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>dev.hassek.claude-sessions-menubar</string>
    <key>CFBundleName</key>
    <string>Claude Sessions</string>
    <key>CFBundleDisplayName</key>
    <string>Claude Sessions</string>
    <key>CFBundleExecutable</key>
    <string>ClaudeSessions</string>
    <key>CFBundleVersion</key>
    <string>0.1</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

echo ""
echo "✓ app: $APP"
echo "→ open $APP"
