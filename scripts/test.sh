#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Library/Developer/CommandLineTools}"
export CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-cache"
swift package resolve
SPARKLE="$PWD/.build/artifacts/sparkle/Sparkle/Sparkle.xcframework/macos-arm64_x86_64"
TEST_DIR="$PWD/.build/standalone-tests"
mkdir -p "$TEST_DIR"
xcrun swiftc -swift-version 5 -enable-testing -emit-library -emit-module \
    -module-name WayfinderCore Sources/WayfinderCore/*.swift \
    -emit-module-path "$TEST_DIR/WayfinderCore.swiftmodule" -o "$TEST_DIR/libWayfinderCore.dylib"
xcrun swiftc -swift-version 5 -D STANDALONE_TESTS -I "$TEST_DIR" -L "$TEST_DIR" \
    -lWayfinderCore -Xlinker -rpath -Xlinker "$TEST_DIR" \
    Tests/WayfinderCoreTests/*.swift -o "$TEST_DIR/CoreTests"
"$TEST_DIR/CoreTests"
APP_SOURCES=()
for source in Sources/Wayfinder/*.swift; do
    [[ "$source" == "Sources/Wayfinder/Main.swift" ]] || APP_SOURCES+=("$source")
done
xcrun swiftc -swift-version 5 -I "$TEST_DIR" -L "$TEST_DIR" \
    -F "$SPARKLE" -framework Sparkle -Xlinker -rpath -Xlinker "$SPARKLE" \
    -lWayfinderCore -Xlinker -rpath -Xlinker "$TEST_DIR" \
    "${APP_SOURCES[@]}" Tests/AppTests/CutSoundTests.swift -o "$TEST_DIR/CutSoundTests"
if [[ -z "${SOUND_RESOURCES:-}" ]]; then
    SOUND_RESOURCES="$TEST_DIR/CutSounds"
    mkdir -p "$SOUND_RESOURCES"
    cp design/audio/cut-options/[ABCDE]-*.wav "$SOUND_RESOURCES/"
    cp design/audio/crisp-cut-options/[FGHIJKLMN]-*.wav "$SOUND_RESOURCES/"
fi
"$TEST_DIR/CutSoundTests" "$SOUND_RESOURCES"
UPDATER_TEST_APP="$TEST_DIR/UpdaterTests.app"
mkdir -p "$UPDATER_TEST_APP/Contents/MacOS"
python3 - "$UPDATER_TEST_APP/Contents/Info.plist" <<'PY'
import plistlib, sys
with open('Resources/Info.plist', 'rb') as source:
    info = plistlib.load(source)
info['CFBundleIdentifier'] = 'local.wayfinder.tests.updater'
info['CFBundleExecutable'] = 'UpdaterTests'
info.pop('CFBundleURLTypes', None)
with open(sys.argv[1], 'wb') as out:
    plistlib.dump(info, out)
PY
xcrun swiftc -swift-version 5 -I "$TEST_DIR" -L "$TEST_DIR" \
    -F "$SPARKLE" -framework Sparkle -Xlinker -rpath -Xlinker "$SPARKLE" \
    -lWayfinderCore -Xlinker -rpath -Xlinker "$TEST_DIR" \
    Sources/Wayfinder/AppUpdater.swift Tests/AppTests/UpdaterTests.swift \
    -o "$UPDATER_TEST_APP/Contents/MacOS/UpdaterTests"
"$UPDATER_TEST_APP/Contents/MacOS/UpdaterTests"
