#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
VERSION="${1:-v0.1.0-beta.7}"
if [[ ! "$VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-[A-Za-z0-9.-]+)?$ ]]; then
    printf 'Expected a version such as v0.1.0-beta.7\n' >&2
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
在 Finder 工具栏右键选择“自定工具栏”，加入 Wayfinder 文件夹按钮。
点击该扩展按钮可选择打开终端、复制路径或新建文件夹；普通打开 App 显示设置。
右键文件或文件夹空白处，可以复制实际路径、新建空文件夹，或将所选项目放入新文件夹。
点击新建后立即创建 untitled folder，重名自动编号，随后在 Finder 内重命名。
自动进入重命名需要辅助功能权限；未授权仍创建并选中，可手动按 Return。
新建操作可在 Wayfinder 菜单栏中撤销最近一次；不等同于 Finder 的 Command+Z。
登录启动和剪切提示音开关位于“权限与设置”。
剪切音效提供十四种原创声音，可在同一页选择、试听；选择会自动保存。
音量跟随系统音效设置；系统关闭“播放用户界面音效”时，试听也保持静音。
软件更新页提供手动检查、自动检查和自动安装开关；默认均不自动更新。
检查更新会连接 GitHub。下载包及更新目录均经过 Sparkle Ed25519 签名校验。

这是测试版，尚未使用 Apple Developer ID 签名及公证。
macOS 可能要求在系统设置的隐私与安全性中确认打开；请先核实发布来源。
不要关闭系统安全保护。

源码、完整说明和已知限制：https://github.com/yangbo-s/Wayfinder
INSTALL
hdiutil create -volname Wayfinder -srcfolder "$STAGING" -ov -format UDZO "dist/$NAME.dmg"
ditto -c -k --keepParent dist/Wayfinder.app "dist/$NAME.zip"
SOUNDS="Wayfinder-$VERSION-Cut-Sounds.zip"
ditto -c -k --keepParent design/audio "dist/$SOUNDS"
python3 scripts/make-appcast.py "dist/$NAME.zip" "$VERSION"
(
    cd dist
    shasum -a 256 "$NAME.dmg" "$NAME.zip" "$SOUNDS" appcast.xml > SHA256SUMS.txt
)
hdiutil verify "dist/$NAME.dmg"
unzip -tq "dist/$NAME.zip"
unzip -tq "dist/$SOUNDS"
printf 'Release artifacts: dist/%s.{dmg,zip}\n' "$NAME"
