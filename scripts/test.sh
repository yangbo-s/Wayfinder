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
