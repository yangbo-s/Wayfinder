#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Library/Developer/CommandLineTools}"
export CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$PWD/.build/swift-cache"
ARCH="${ARCH:-$(uname -m)}"
IDENTITY="${SIGNING_IDENTITY:--}"
APP="$PWD/dist/Wayfinder.app"
EXT="$APP/Contents/PlugIns/WayfinderFinder.appex"
swift build -c release --arch "$ARCH" --disable-sandbox
BIN="$(swift build -c release --arch "$ARCH" --show-bin-path --disable-sandbox)"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$EXT/Contents/MacOS"
cp "$BIN/Wayfinder" "$APP/Contents/MacOS/Wayfinder"
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp LICENSE "$APP/Contents/Resources/LICENSE.txt"
cp Resources/Extension-Info.plist "$EXT/Contents/Info.plist"
xcrun swiftc -swift-version 5 -O -parse-as-library -module-name WayfinderFinder \
    -target "$ARCH-apple-macos13.0" -sdk "$(xcrun --show-sdk-path)" \
    -framework AppKit -framework FinderSync -Xlinker -e -Xlinker _NSExtensionMain \
    FinderExtension/FinderSync.swift Sources/Wayfinder/WayfinderSymbol.swift Sources/WayfinderCore/PathResolver.swift Sources/WayfinderCore/TerminalRequest.swift Sources/WayfinderCore/FinderActionContext.swift Sources/WayfinderCore/FolderRequest.swift -o "$EXT/Contents/MacOS/WayfinderFinder"
xcrun swift scripts/make-icon.swift "$APP/Contents/Resources"
codesign --force --sign "$IDENTITY" --options runtime --entitlements Resources/Extension.entitlements "$EXT"
codesign --force --sign "$IDENTITY" --options runtime --entitlements Resources/App.entitlements "$APP"
codesign --verify --deep --strict "$APP"
ditto -c -k --keepParent "$APP" "$PWD/dist/Wayfinder.zip"
printf 'Built: %s\n' "$APP"
