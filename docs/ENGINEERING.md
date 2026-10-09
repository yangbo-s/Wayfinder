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
Services 能提供服务子菜单，但不能覆盖 Finder 空白处；Finder Sync 可提供项目、空白处与工具栏菜单。选择 Finder Sync；工具栏扩展按钮在 toolbarItemMenu 回调中直接请求终端并返回 nil，实现单击打开。普通启动与再次打开主 App 始终显示设置，登录/明确后台启动保持安静。Finder Sync 只注册目录，不遍历内容或绘制徽标。Apple 将此扩展定位为同步软件；这里使用公开 API 为本地个人工具添加菜单，不承诺 App Store 审核。

## 接口
API-001：扩展通过 wayfinder://terminal?path=<percent-encoded absolute path> 唤起主 App；主 App 校验路径，使用已配置终端，不接受外部命令。重复请求各开一个窗口；错误可重试。复制在扩展内完成，避免 URL 长度限制。
API-002：CutSession 状态 idle → awaitingCopy(previous changeCount) → ready(changeCount) → idle。剪贴板换内容、普通复制、Esc、关闭功能取消；paste 消费一次，重试失败由 Finder 处理。
API-003：Terminal/iTerm2/Ghostty 使用本地脚本字典；路径做 AppleScript 字符串与 shell 两层独立转义。Warp 用官方 file URI 查询。自定义 app 参数通过 Process 数组传给 /usr/bin/open，不展开 shell。

## 阶段门禁
需求及契约已形成 → 纯逻辑与真实文件边界测试 → App / extension 构建 → 签名与安装包检查 → 可用权限范围内 UI 和系统联调 → 验收记录。没有权限时保留精确未验证项，不等同于通过。

## 发布范围补充（2026-10-06）

REQ-006 / AC-006：按用户明确授权，将 GitHub yangbo-s/this-is-the-way 改名为 Wayfinder，保持原公开可见性和 main 分支；补充 README 与仓库简介；将源码提交推送；创建 v0.1.0-beta.1 预发布，上传 Apple Silicon DMG、ZIP 和 SHA-256。验收以 GitHub API 仓库名称、远端 main 提交与本地一致、release 已发布、资产可下载且哈希匹配为准。由于核心系统集成尚待授权，仅发布明确标示的测试版，不宣称达到稳定发布门槛。

## beta.2 缺陷修复与追加验收

REQ-007 / AC-007：普通冷启动（含已有 hasLaunched 标志）与再次打开 App 均显示设置，不启动终端；登录/后台和外部动作保持既有语义。设置页使用 App 的同一图标资源，菜单栏与 Finder 工具栏改为单色“文件夹＋转向箭头”图标。

REQ-008 / AC-008：系统授权与监听运行状态分别显示。已经获得访问时，不重复申请授权；失效事件监听可重建。当前进程的 AX preflight 或受保护的 Finder AX 查询成功才判为授权生效，不根据偏好中的旧开关推断。ad-hoc 更新造成的旧授权失效必须如实提示。

REQ-009 / AC-009：Finder 菜单动作在触发时查询 targetedURL / selectedItemURLs，不依赖跨进程不保留的 NSMenuItem representedObject。当前目录、文件、多选及链接复制与终端动作恢复。找不到位置或写剪贴板失败时反馈错误，不静默退出。

API-004：FinderActionContext 过滤非 file URL，区分当前目录与选中项目；菜单 action 内获取最新上下文。终端请求使用对应的 containing App，避免多份构建误唤起旧版。`wayfinder://error?reason=missing-location|clipboard-write-failed` 仅接受已知原因、单参数且无额外路径或 fragment，由宿主显示错误。

MOD-005：LaunchPolicy / KeyboardReadiness 纯逻辑负责生命周期与状态判定；AppDelegate / AccessibilityPermission / CutController 负责真实系统事件、权限与监听。测试覆盖升级后的启动、重复打开、后台与外部请求，以及授权已获得但监听失败的分支。

ADR-003：曾在菜单项 representedObject 中存 URL，Finder 在跨进程重建菜单后不再携带该状态。选择 Apple SDK 明确允许的 action 回调期间读取 Finder 上下文，避免缓存路径和旧项目身份。失败只记录原因码，不记录用户路径。

已知代价：本机没有有效 Developer ID 身份；仍发布 ad-hoc 测试版，代码签名身份无法跨构建稳定。没有降低签名检查、重置整个 TCC 或自动更改系统权限。

## beta.3 需求与契约

REQ-010 / AC-010：所有 Wayfinder 右键菜单项带原生单色小图标；终端入口统一“在当前目录下打开终端”。Finder 工具栏箭头由宿主生成，公开 API 仅提供 image/name/tooltip/menu，不能移除；用户明确选择真正的功能菜单（终端、复制路径、新建文件夹）。保持普通 App 启动显示设置。

REQ-011 / AC-011：文件夹背景、单选、多选菜单始终提供“新建空文件夹…”；同时提供按单选或多选数量显示的“将所选项目放入新文件夹…”动作。命名对话框确认前零写入；仅同一真实父目录的项目可一起分组。已有同名目标不覆盖，保留符号链接本身，失败时回退已完成移动；若外部修改阻止回退，明确报告保留位置。成功后 Finder 选中新文件夹，宿主提供本次会话内撤销入口。

API-005：扩展将 Codable FolderRequest（mode、directory、items）写入 UUID 命名的临时 pasteboard，使用 `wayfinder://folder?token=<UUID>` 通知对应宿主；不修改系统通用剪贴板，不受 URL 中大量文件路径的长度限制。宿主验证 URL、读取并释放命名板、校验请求，显示目录与数量及命名输入框。取消/非法请求不创建目录。

MOD-006：FolderCreation（真实文件系统预检、无覆盖移动、失败回退、撤销）；FolderRequest（纯数据和 URL 契约）；FolderActions（命名 UI 与 Finder 揭示）；FinderExtension 只捕获动作上下文、图标和传递请求，不在 sandbox 内直接移动文件。

ADR-004：Finder 快捷键/菜单模拟依赖辅助功能且无法可靠处理自定义名称；Finder AppleScript 移动还受自动化授权、符号链接 alias 解析及撤销语义影响。选择范围受限的 FileManager 同父目录分组，文件身份校验、无覆盖移动和失败回退负责保护数据；用宿主自己的撤销恢复。此处是用户明确新增的分组功能；已有 ⌘X/⌘V 仍完全使用 Finder 原生移动，不改变原实现。组内多次 rename 不是跨文件原子事务。

TC-038–045：核心请求契约、名称/目录/选择预检、空目录创建、单项与多项分组、同名/失效源拒绝、链接保留、故障回退与撤销；再通过真实 Finder 背景/单选/多选入口用独立临时文件联调。发布 beta.3 后重新下载校验。


## beta.4 原生重命名流程

REQ-012 / AC-012（替代 REQ-011 的命名对话框）：三个新建入口均立即创建 `untitled folder`，已占用则使用 `untitled folder 2` 等名称；不显示命名弹窗，菜单标题移除省略号。创建或分组成功后选中新文件夹并进入 Finder 内联重命名。用户可直接输入名称并按 Return 确认；不编辑时按 Return 保留默认名称。改名后 Wayfinder 撤销仍恢复原文件；原路径被其他文件占用时保留它。

IN-002 / OUT-002：沿用 API-005 的空/单/多选请求，不再要求用户输入名称；成功返回文件夹 URL 和卷/文件身份。无覆盖 mkdir 对并发同名冲突重试，其他错误原样反馈。请求串行；新建成功但权限或 Finder 焦点不可用时仍保留目录并选中，在状态提示中说明可按 Return，不弹新的命名或授权窗口。

ADR-005：公开 NSWorkspace API 能揭示和选中文件，但不提供内联重命名参数。选择揭示后验证 Finder 为前台、文件区域焦点、且 AXSelectedRows / AXSelectedChildren 中的单个文件 URL 精确等于新目录，再通过公开 AXPress 调用 Finder 自己的 Rename 菜单命令。有限等待，期间有用户键盘/鼠标输入则放弃。按英文、简体中文、繁体中文菜单标题匹配唯一可用命令，不依赖菜单位置；其他语言仍创建并选中，提示手动 Return。只需要辅助功能授权，不为重命名依赖 Finder AppleScript 自动化，不发送合成键盘事件。相比完全模拟 Finder 新建命令，文件创建与分组仍可独立于权限完成并保留已有数据保护。

MOD-007：FinderRename 只负责揭示、选择校验和进入原生编辑；文件内容仍由 MOD-006 管理。FolderCreation 的撤销按卷/文件身份在原父目录查找改名后的目录，不跨目录追踪、不误用原路径的替换文件。API-005 宿主收到合法请求后直接创建，不再经过命名 UI。

TC-051–054：自动名称、并发同名、空/单/多改名后撤销、目录内容/父目录变化保护的真实文件测试。TC-055：Finder 空、单、多入口立即创建且 AX 编辑器出现；TC-056：缺少权限/用户切换时不误发键；TC-057：新版包签名和下载校验。正式发布前记录实际结果及未运行项。

依据：[NSWorkspace 揭示 API](https://developer.apple.com/documentation/appkit/nsworkspace/activatefileviewerselecting(_:)) 与 [Apple Finder 重命名说明](https://support.apple.com/en-mt/guide/mac-help/mchlp1144/mac)。

## beta.5 五款剪切音效

REQ-013 / AC-013：内置本会话制作的全部五款原创音效（最早轻快剪切及 A–D），在“权限与设置”中选择、主动试听、自动保存。默认轻快剪切；未知旧值回到默认。保留已有静音设置，关闭自动提示仍可主动试听。成功准备剪切后仅播放当前选择一次。使用系统音效音量和界面音效开关，资源缺失不回退为 Tink、不打断文件移动。

IN-003 / OUT-003：选择以稳定字符串 crisp / metallic / paper / soft / doubleTick 保存到 cutSound，playCutSound 布尔设置保持兼容。五份 mono PCM16 / 48 kHz WAV 从 App Resources/CutSounds 读取，只允许枚举映射的资源名。出错写入设置页状态，不在 Finder 前弹窗；试听与实际剪切共享播放器。

MOD-008 / ADR-006：CutSoundChoice 管理稳定名称与文件映射；CutSoundPlayer 通过公开 AudioToolbox 加载并缓存 SystemSoundID，析构时释放。相比 NSSound 系统提示音，内置原创 WAV 可准确保留用户已试听的声音，System Sound Services 默认 IsUISound=1 尊重系统开关；不新增运行时依赖。音频与生成器随 MIT 许可发布，未使用 Command X 音频。

验收顺序：逐字节保留原五个试听文件 → 音频加载/错误/设置持久化/开关集成测试 → 主 App 与扩展构建 → 实际设置菜单和试听检查 → DMG/ZIP/单独音效包及重新下载校验。TC-059–065 为音效集成测试；TC-066 为实际 UI，TC-067 为发布资源完整性。REQ-006 延续用户授权，推送 main 并发布 v0.1.0-beta.5 测试版。

## beta.6 十四款剪切音效

REQ-014 / AC-014：将用户认可的 F–N 九款干脆音效加入现有选择器与试听，共十四款；原 A–E 五款及其稳定 ID、默认选择、静音设置完全保留。所有 WAV 与用户试听文件逐字节一致。机械双击名称注明 13 / 20 / 27 / 46 ms，便于区分。沿用 MOD-008 / ADR-006，不更换播放器或添加依赖。

IN-004 / OUT-004：cutSound 新增 cleanClick / tightDouble / mechanicalSnap / fastLightHeavy / spacedLightHeavy / tightMechanical / deepMechanical / closeMechanical / mediumMechanical 九个字符串，映射到 F–N 的 WAV 文件。枚举决定菜单顺序；预览和剪切均使用已保存的选择。缺失/损坏资源与未知 ID 仍遵循 IN-003 的错误及回退契约。

CON-002 / OOS-002：保留原始音频，不重新合成或归一化；不改剪切、权限、Finder 和终端逻辑。默认音效继续为轻快剪切，不替用户更改偏好。仅发布 Apple Silicon 测试包，不宣称 Intel、公证或全系统兼容。

实施及门禁：扩展枚举 → 构建及测试资源同时收集两组音效 → 实际十四款加载、旧设置兼容、逐项试听/剪切选择与持久化测试 → App、DMG、ZIP、包含两组源文件及 MIT 许可的音效包 → 设置 UI 检查 → 推送 main/tag 并发布 beta.6 → 重新下载全部资产校验。TC-068 覆盖旧 ID 兼容及十四项选择行为，TC-069 为设置菜单检查，TC-070 为十四款资源打包与下载验证。REQ-006 的发布授权持续适用。

## Sparkle 接入（2026-10-09）

REQ-015 / REQ-016、AC-015 / AC-016、MOD-009 / ADR-007、IN-005 / OUT-005、TC-071–075 与发布契约见 [SPARKLE.md](SPARKLE.md)。本次用户限定先完成代码与本地验证；未授权的公开发布及现有安装替换不在本轮交付范围。
