#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Library/Developer/CommandLineTools}"
export CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-cache"
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
    -lWayfinderCore -Xlinker -rpath -Xlinker "$TEST_DIR" \
    "${APP_SOURCES[@]}" Tests/AppTests/CutSoundTests.swift -o "$TEST_DIR/CutSoundTests"
if [[ -z "${SOUND_RESOURCES:-}" ]]; then
    SOUND_RESOURCES="$TEST_DIR/CutSounds"
    mkdir -p "$SOUND_RESOURCES"
    cp design/audio/cut-options/[ABCDE]-*.wav "$SOUND_RESOURCES/"
    cp design/audio/crisp-cut-options/[FGHIJKLMN]-*.wav "$SOUND_RESOURCES/"
fi
"$TEST_DIR/CutSoundTests" "$SOUND_RESOURCES"
