# Wayfinder

**让 Finder 更顺手：剪切文件、就地打开终端、一键复制真实路径。**

Wayfinder is a lightweight, native macOS Finder companion for cut & paste, opening your preferred terminal, and copying resolved filesystem paths.

[下载测试版](https://github.com/yangbo-s/Wayfinder/releases/tag/v0.1.0-beta.1) · [功能与安装](#安装与使用) · [构建与测试](#构建与测试) · [MIT License](LICENSE)

| 功能 | 行为 |
|---|---|
| ⌘X / ⌘V 文件剪切 | 使用 Finder 原生移动流程，保留冲突提示和撤销 |
| 在当前位置打开终端 | 默认 Terminal，可选 Ghostty、iTerm2、Warp 或自定义 App |
| Finder 右键复制路径 | 支持当前目录、选中项目与多选，解析符号链接 |
| 工具栏快捷入口 | 按住 ⌘ 将 App 拖入 Finder 工具栏，一次点击打开终端 |
| 登录时启动 | 可选，后台驻留菜单栏 |
| 剪切提示音 | 成功进入待移动状态时提示，可关闭 |

无需账号，不联网，无第三方运行时依赖。界面为中文，跟随系统深浅色。

## 下载

首个版本为 **v0.1.0-beta.1**，提供 **Apple Silicon（arm64）** 安装包，要求 **macOS 13 或更新版本**；实际构建和界面检查运行于 macOS 27.0.1。Intel 用户目前需要从源码构建，未提供经过测试的 Intel 安装包。

- [下载 DMG 安装包](https://github.com/yangbo-s/Wayfinder/releases/download/v0.1.0-beta.1/Wayfinder-v0.1.0-beta.1-macOS-arm64.dmg)：打开后拖到 Applications。
- [下载 ZIP 压缩包](https://github.com/yangbo-s/Wayfinder/releases/download/v0.1.0-beta.1/Wayfinder-v0.1.0-beta.1-macOS-arm64.zip)：解压后移动 App。
- [SHA-256 校验文件](https://github.com/yangbo-s/Wayfinder/releases/download/v0.1.0-beta.1/SHA256SUMS.txt)。

**测试版状态：** 本地 ad-hoc 签名，尚无 Apple Developer ID 签名和公证。下载后 macOS 可能要求在「系统设置 → 隐私与安全性」中确认打开。请仅在信任源码和发布来源时继续；无需关闭 Gatekeeper 或执行移除隔离属性的命令。17 项核心测试通过；Finder 的真实移动、扩展右键、终端实开和重新登录仍需要在授权后完成验收，详见[验收记录](docs/ACCEPTANCE.md)。

## 安装与使用

1. 从 Releases 下载 DMG 或 ZIP，将 **Wayfinder.app** 拖到 `/Applications`，打开一次。源码构建的 App 位于 `dist/Wayfinder.app`。
2. 在 Wayfinder 的「概览」里启用**辅助功能**。只对 Finder 文件区域转换快捷键，授权后自动开始监听。
3. 点击「Finder 扩展 → 去启用」，在系统设置中启用 **Wayfinder Finder**。新版 macOS 也可在「通用 → 登录项与扩展 → Finder」中找到；若未刷新，关闭并重新打开 Finder 窗口。
4. 第一次打开终端时，同意 macOS 提示的 Finder / 终端自动化权限。
5. 如果正在用 Command X，请先退出 Command X，避免同时改写同一快捷键。

登录时启动可在「权限与设置」中开关；登录启动只驻留菜单栏。剪切成功提示音默认开启，可在同一页关闭。

### 剪切文件

选中 Finder 文件 → `⌘X` → 进入目标目录 → `⌘V`。内部调用 Finder 原生 Copy / Move Item Here，冲突提示、跨卷行为和 `⌘Z` 撤销由 Finder 处理；不会提前删除源文件。源图标不会变灰。

复制别的内容、按 Esc 或关闭剪切开关会取消待移动状态。Finder 重命名、搜索框和其他应用保留原有快捷键。剪贴板复制尚未完成时快速按下 ⌘V，会提示再按一次。取消 Finder 的移动对话框后若要重试，请重新 ⌘X。

### 在这里打开终端

默认使用**系统 Terminal**。设置 → 终端可选 Ghostty、iTerm2、Warp 或自定义终端。

- **工具栏单击**：按住 `⌘`，将 Wayfinder.app 拖到 Finder 工具栏。单击即在当前 Finder 文件夹打开终端。初次运行先显示设置，请先完成安装。
- **右键**：「在这里打开终端」。点文件会打开其父目录；点文件夹会打开该文件夹；多选时采用 Finder 返回的第一个项目。
- **菜单栏**：Wayfinder →「在当前位置打开…」。设置也可从菜单栏进入。

Ghostty 使用本地 AppleScript 字典中的 `new surface configuration` / `new window`，需要提供这些命令的较新版本。Terminal / iTerm2 在新窗口执行安全转义的 `cd`。Warp 使用官方 `warp://action/new_window?path=…`。

自定义终端：选择 `.app`，按终端文档填写参数 JSON 数组，例如 `["--working-directory={path}"]`。`{path}` 会被替换为实际目录。参数以数组传递，不经过 shell；自定义终端必须本身支持工作目录参数，每次以新实例启动。

### 复制实际路径

右键空白处 →「复制当前文件夹的实际路径」。右键文件 →「复制所选项目的实际路径」，也可复制所在文件夹。多选每行一条；空格和中文原样保留，不加 shell 引号；符号链接解析为目标绝对路径。macOS 的 `/tmp` 等链接可能显示成 `/private/tmp`。名称含换行的文件仍原样复制，因此文本行不一定对应项目数。

「最近使用」、搜索集合、网络浏览根目录等虚拟视图可能没有单一实际路径，打开实际文件夹后重试。Finder Sync 的菜单覆盖与出现位置由 macOS 决定。

## 构建与测试

需要 macOS 13+ 和 Swift 5.9+ Command Line Tools。无第三方依赖。测试脚本使用轻量断言适配器运行同一份 XCTest 风格测试，避免 Command Line Tools 未附带 XCTest 的限制；完整 Xcode 也可直接 `swift test`。

```sh
./scripts/test.sh
./scripts/build.sh
open dist/Wayfinder.app --args --settings
```

脚本默认使用 `/Library/Developer/CommandLineTools`，不修改全局 xcode-select。如已配置完整 Xcode，可显式传入 `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`。`ARCH=arm64` 或 `ARCH=x86_64` 选择构建架构；默认为本机架构。

生成 `dist/Wayfinder.app` 与 `dist/Wayfinder.zip`。发布包可用 `./scripts/package-release.sh v0.1.0-beta.1` 生成，包含 DMG、ZIP 和 SHA-256。可用 `SIGNING_IDENTITY='Developer ID Application: …'` 选择自己的签名；分发到其他机器还需按 Apple 流程公证，不能将本地签名视作已公证。

源码可用 Xcode 打开 `Package.swift`；完整宿主 + 扩展打包由 `scripts/build.sh` 执行。直接运行 Swift Package 的可执行文件不包含 App 元数据和 Finder 扩展。

## 结构

- `Sources/WayfinderCore`：剪贴板状态、路径、转义与 URL 契约，可独立测试。
- `Sources/Wayfinder`：设置、菜单栏、事件监听、Finder / 终端适配。
- `FinderExtension`：Finder 右键和扩展工具栏菜单；无递归扫描、文件移动或徽标处理。
- `Resources`：App / extension 元数据和权限声明。
- [工程说明](docs/ENGINEERING.md) · [验收记录](docs/ACCEPTANCE.md)

## 权限、故障恢复与卸载

- **快捷键不工作**：确认辅助功能授权（macOS 27 中改名为「设备控制与数据访问」），退出 Command X，重新打开 Wayfinder；若重新构建导致系统签名信任变化，在辅助功能列表移除旧项，再添加当前 App。
- **右键无菜单**：先把 App 安装在固定位置，运行一次，再启用 Finder 扩展。检查当前目录是否为真实文件夹。必要时退出并重新登录；不会自动杀死 Finder。
- **自动化被拒绝**：系统设置 → 隐私与安全性 → 自动化，允许 Wayfinder 控制 Finder 和所选终端。
- **Ghostty 报脚本错误**：更新 Ghostty，或临时切换 Terminal。
- **登录时启动**：在「权限与设置」中开启，macOS 需要审批时会打开登录项设置。安装在固定位置后再开启。
- **卸载**：关闭登录时启动，退出 Wayfinder，关闭 Finder 扩展，然后把 App 移到废纸篓。设置位于 `local.wayfinder.mac` 用户偏好域；不会清理或改动用户文件。

## 依据

使用 Apple 的 [Finder Sync 公共 API](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/Finder.html) 与 [Finder 移动快捷键](https://support.apple.com/en-us/102650)。Apple 将 Finder Sync 主要定位为同步应用的扩展，本项目是本地个人工具，不承诺 App Store 适用性。Warp 参数依据 [官方 URI 文档](https://docs.warp.dev/terminal/more-features/uri-scheme)。Ghostty / iTerm2 命令以本机安装 App 的 `.sdef` 脚本字典验证。

## 项目与反馈

项目采用 MIT License。若发现兼容性问题，请在 [Issues](https://github.com/yangbo-s/Wayfinder/issues) 中附上 macOS 版本、终端版本、复现步骤和是否已开启系统权限；不要上传私人路径、文件内容或其他敏感信息。

功能受到 Command X 和 cd to 的使用方式启发，本项目独立实现，未使用它们的名称、图标或代码资产。
