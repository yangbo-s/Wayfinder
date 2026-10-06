#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
VERSION="${1:-v0.1.0-beta.1}"
if [[ ! "$VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-[A-Za-z0-9.-]+)?$ ]]; then
    printf 'Expected a version such as v0.1.0-beta.1\n' >&2
    exit 1
fi
./scripts/build.sh
ARCH="${ARCH:-$(uname -m)}"
NAME="Wayfinder-$VERSION-macOS-$ARCH"
STAGING="$(mktemp -d "$PWD/.build/release.XXXXXX")"
trap 'rm -rf "$STAGING"' EXIT
ditto dist/Wayfinder.app "$STAGING/Wayfinder.app"
ln -s /Applications "$STAGING/Applications"
cat > "$STAGING/安装说明.txt" <<'INSTALL'
Wayfinder 安装

将 Wayfinder.app 拖到 Applications，然后打开一次。
在 App 的概览中启用辅助功能（macOS 27：设备控制与数据访问）与 Finder 扩展。
第一次使用终端时允许 Finder / 终端自动化。使用剪切前退出 Command X，避免冲突。

默认终端为系统 Terminal，可在设置中切换 Ghostty、iTerm2、Warp 或自定义终端。
按住 Command 将 App 拖入 Finder 工具栏，可单击在当前目录打开终端。
登录启动和剪切提示音开关位于“权限与设置”。

这是测试版，尚未使用 Apple Developer ID 签名及公证。
macOS 可能要求在系统设置的隐私与安全性中确认打开；请先核实发布来源。
不要关闭系统安全保护。

源码、完整说明和已知限制：https://github.com/yangbo-s/Wayfinder
INSTALL
hdiutil create -volname Wayfinder -srcfolder "$STAGING" -ov -format UDZO "dist/$NAME.dmg"
ditto -c -k --keepParent dist/Wayfinder.app "dist/$NAME.zip"
(
    cd dist
    shasum -a 256 "$NAME.dmg" "$NAME.zip" > SHA256SUMS.txt
)
hdiutil verify "dist/$NAME.dmg"
unzip -tq "dist/$NAME.zip"
printf 'Release artifacts: dist/%s.{dmg,zip}\n' "$NAME"
