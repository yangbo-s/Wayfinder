#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Library/Developer/CommandLineTools}"
export CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$PWD/.build/swift-cache"
ARCH="${ARCH:-$(uname -m)}"
IDENTITY="${SIGNING_IDENTITY:--}"
APP="${APP_OUTPUT:-$PWD/dist/Wayfinder.app}"
EXT="$APP/Contents/PlugIns/WayfinderFinder.appex"
ENTITLEMENTS=Resources/App.entitlements
if [[ "$IDENTITY" == "-" ]]; then
    if [[ "${ALLOW_ADHOC_UPDATES:-0}" != "1" ]]; then
        printf 'Sparkle needs matching Team IDs with Hardened Runtime. Set SIGNING_IDENTITY, or explicitly opt into the ad-hoc test build with ALLOW_ADHOC_UPDATES=1 (disables library validation for this app only).\n' >&2
        exit 1
    fi
    ENTITLEMENTS=Resources/App-AdHoc.entitlements
fi
swift build -c release --arch "$ARCH" --disable-sandbox
BIN="$(swift build -c release --arch "$ARCH" --show-bin-path --disable-sandbox)"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$EXT/Contents/MacOS"
cp "$BIN/Wayfinder" "$APP/Contents/MacOS/Wayfinder"
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp LICENSE "$APP/Contents/Resources/LICENSE.txt"
SPARKLE="$PWD/.build/artifacts/sparkle/Sparkle/Sparkle.xcframework/macos-arm64_x86_64/Sparkle.framework"
FRAMEWORK="$APP/Contents/Frameworks/Sparkle.framework"
mkdir -p "$APP/Contents/Frameworks"
ditto "$SPARKLE" "$FRAMEWORK"
cp .build/artifacts/sparkle/Sparkle/LICENSE "$APP/Contents/Resources/Sparkle-LICENSE.txt"
mkdir -p "$APP/Contents/Resources/CutSounds"
cp design/audio/cut-options/[ABCDE]-*.wav "$APP/Contents/Resources/CutSounds/"
cp design/audio/crisp-cut-options/[FGHIJKLMN]-*.wav "$APP/Contents/Resources/CutSounds/"
cp Resources/Extension-Info.plist "$EXT/Contents/Info.plist"
xcrun swiftc -swift-version 5 -O -parse-as-library -module-name WayfinderFinder \
    -target "$ARCH-apple-macos13.0" -sdk "$(xcrun --show-sdk-path)" \
    -framework AppKit -framework FinderSync -Xlinker -e -Xlinker _NSExtensionMain \
    FinderExtension/FinderSync.swift Sources/Wayfinder/WayfinderSymbol.swift Sources/WayfinderCore/PathResolver.swift Sources/WayfinderCore/TerminalRequest.swift Sources/WayfinderCore/FinderActionContext.swift Sources/WayfinderCore/FolderRequest.swift -o "$EXT/Contents/MacOS/WayfinderFinder"
xcrun swift scripts/make-icon.swift "$APP/Contents/Resources"
codesign --force --sign "$IDENTITY" --options runtime --entitlements Resources/Extension.entitlements "$EXT"
for component in XPCServices/Installer.xpc XPCServices/Downloader.xpc Autoupdate Updater.app; do
    codesign --force --sign "$IDENTITY" --options runtime "$FRAMEWORK/Versions/B/$component"
done
codesign --force --sign "$IDENTITY" --options runtime "$FRAMEWORK"
codesign --force --sign "$IDENTITY" --options runtime --entitlements "$ENTITLEMENTS" "$APP"
codesign --verify --deep --strict "$APP"
ditto -c -k --keepParent "$APP" "$PWD/dist/Wayfinder.zip"
printf 'Built: %s\n' "$APP"
