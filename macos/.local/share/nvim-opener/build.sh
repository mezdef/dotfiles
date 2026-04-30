#!/bin/bash
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
APP="/Applications/NvimOpener.app"

rm -rf "$APP"
osacompile -o "$APP" "$DIR/nvim-opener.applescript"

PB=/usr/libexec/PlistBuddy
PLIST="$APP/Contents/Info.plist"
"$PB" -c "Delete :CFBundleDocumentTypes" "$PLIST" 2>/dev/null || true
"$PB" \
  -c "Add :CFBundleDocumentTypes array" \
  -c "Add :CFBundleDocumentTypes:0 dict" \
  -c "Add :CFBundleDocumentTypes:0:CFBundleTypeName string Plain Text" \
  -c "Add :CFBundleDocumentTypes:0:LSItemContentTypes array" \
  -c "Add :CFBundleDocumentTypes:0:LSItemContentTypes:0 string public.plain-text" \
  -c "Add :CFBundleDocumentTypes:0:CFBundleTypeRole string Editor" \
  "$PLIST"
"$PB" -c "Delete :LSUIElement" "$PLIST" 2>/dev/null || true
"$PB" -c "Add :LSUIElement bool true" "$PLIST"

# Re-sign after plist modification
codesign --force --deep --sign - "$APP"

/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
  -f "$APP"

echo ""
echo "NvimOpener.app built at $APP"
echo ""
echo "One-time Gatekeeper setup required (macOS Sequoia):"
echo "  1. Try to open any .txt or .md file — macOS will show a block dialog"
echo "  2. Go to System Settings → Privacy & Security"
echo "  3. Scroll down and click 'Allow Anyway' next to NvimOpener"
echo "  4. Open the file again and click 'Open' in the confirmation dialog"
echo "  macOS remembers the approval — you won't be asked again."
