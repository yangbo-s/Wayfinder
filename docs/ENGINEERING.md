# 工程计划与契约

GOAL-001：用一个原生 Mac 工具完成 Finder 文件移动、定位终端和复制真实路径。

| 需求 | 功能 / 验收 | 模块 |
|---|---|---|
| REQ-001 / AC-001 | Finder 文件区域 ⌘X、目标目录 ⌘V 通过原生 Move 完成；文本编辑、普通复制和其他 App 不受影响 | MOD-001 CutController / CutSession |
| REQ-002 / AC-002 | 默认 Terminal，设置能选择 Ghostty/iTerm2/Warp/自定义；Finder 工具栏单击在当前目录新开终端 | MOD-002 TerminalLauncher / FinderLocation |
| REQ-003 / AC-003 | Finder 文件及空白处右键复制实际绝对路径，含多选、空格、中文、链接 | MOD-003 FinderExtension / PathResolver |
| REQ-004 / AC-004 | 可运行 .app、权限引导、开机启动开关、可复现构建与文档 | MOD-004 AppModel / Settings / scripts |

IN-001：Finder file URL；路径必须为非空绝对路径，不含 NUL。自定义终端参数使用 JSON 字符串数组，以 {path} 替换目录；不经 shell。默认 Terminal。
OUT-001：复制结果为 UTF-8 文本，多选每行一条；终端每次新建窗口。失败有可见错误，不静默改用其他目录。
CON-001：macOS 13+；原生 SDK；不直接删除/移动用户文件；不修改其他程序配置。尚无 Developer ID，交付本地 ad-hoc 签名包，不声称已公证。
OOS-001：App Store 发布、云服务、Finder 私有 API、复制 Command X/cd to 品牌或资产。
ASM-001：名称 Wayfinder、中文界面、实际路径解析 symlink；普通文件打开其父目录。

REQ-005 / AC-005：登录时启动可开关且后台启动不打开终端；剪切确认成功后播放一次提示音，可关闭、设置持久化。

## ADR-001
方案 A 自己使用 FileManager 移动：需重建冲突、撤销、跨卷行为，风险高。
方案 B 将文件区域 ⌘X 映射到 Finder ⌘C，仅在剪贴板仍对应本次剪切时将 ⌘V 映射为 ⌥⌘V：选择 B，复用 Finder 原生确认与撤销。不会预先删除源文件。剪切不使图标变灰。

## ADR-002
Services 能提供服务子菜单，但不能覆盖 Finder 空白处；Finder Sync 可提供项目、空白处与工具栏菜单。选择 Finder Sync，同时主 App 可按住 ⌘ 拖入 Finder 工具栏，实现直接单击启动终端。Finder Sync 只注册目录，不遍历内容或绘制徽标。Apple 将此扩展定位为同步软件；这里使用公开 API 为本地个人工具添加菜单，不承诺 App Store 审核。

## 接口
API-001：扩展通过 wayfinder://terminal?path=<percent-encoded absolute path> 唤起主 App；主 App 校验路径，使用已配置终端，不接受外部命令。重复请求各开一个窗口；错误可重试。复制在扩展内完成，避免 URL 长度限制。
API-002：CutSession 状态 idle → awaitingCopy(previous changeCount) → ready(changeCount) → idle。剪贴板换内容、普通复制、Esc、关闭功能取消；paste 消费一次，重试失败由 Finder 处理。
API-003：Terminal/iTerm2/Ghostty 使用本地脚本字典；路径做 AppleScript 字符串与 shell 两层独立转义。Warp 用官方 file URI 查询。自定义 app 参数通过 Process 数组传给 /usr/bin/open，不展开 shell。

## 阶段门禁
需求及契约已形成 → 纯逻辑与真实文件边界测试 → App / extension 构建 → 签名与安装包检查 → 可用权限范围内 UI 和系统联调 → 验收记录。没有权限时保留精确未验证项，不等同于通过。

## 发布范围补充（2026-10-06）

REQ-006 / AC-006：按用户明确授权，将 GitHub yangbo-s/this-is-the-way 改名为 Wayfinder，保持原公开可见性和 main 分支；补充 README 与仓库简介；将源码提交推送；创建 v0.1.0-beta.1 预发布，上传 Apple Silicon DMG、ZIP 和 SHA-256。验收以 GitHub API 仓库名称、远端 main 提交与本地一致、release 已发布、资产可下载且哈希匹配为准。由于核心系统集成尚待授权，仅发布明确标示的测试版，不宣称达到稳定发布门槛。
