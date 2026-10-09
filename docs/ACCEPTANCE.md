# 验收记录

日期：2026-10-06（用户时区 America/New_York）。环境：Apple Silicon、macOS 27.0.1、Swift 6.0.3 Command Line Tools。构建目标 macOS 13+，本次未在其他 macOS / Intel 设备运行。

初版状态记录如下；最新 beta.2 验收见文末。不得将部分系统联调通过表述为全部验收通过。

| 测试 | 需求 / 验收 | 级别 | 结果与证据 |
|---|---|---|---|
| TC-001–007 | REQ-001 / AC-001 | P0 单元 | 通过：只接受本次新文件剪贴板，替换/取消/重复剪切/普通复制/仅消费一次，`./scripts/test.sh` |
| TC-008–011 | REQ-003 / AC-003 | P1 文件边界 | 通过：真实临时文件与 symlink，中文/空格/引号，文件父目录、多选、无效路径与不存在位置 |
| TC-012–014 | REQ-002 / AC-002 | P1 契约 | 通过：URL 特殊字符往返、未知动作/多余字段/重复参数拒绝、自定义参数数组 |
| TC-015–017 | REQ-002 / AC-002 | P0 安全/默认 | 通过：实际 zsh 不执行路径中的命令替换；AppleScript 转义；Terminal 默认和 bundle IDs |
| TC-018 | REQ-004 / AC-004 | P1 构建 | 通过：release 宿主与 Finder 扩展构建，四个 plist lint，deep/strict 签名验证，arm64 Mach-O，zip 包 |
| TC-019 | REQ-004 / AC-004 | P1 UI | 通过：真实 App 启动；概览、终端与权限页可见，默认 Terminal；Ghostty 切换后恢复 Terminal；无明显文本裁切 |
| TC-020 | REQ-002 / AC-002 | P1 集成语法 | 通过：使用本机 Terminal / Ghostty / iTerm2 字典编译实际命令模板，仅编译未执行 |
| TC-021 | REQ-003 / AC-003 | P1 扩展注册 | 部分通过：`pluginkit -m -A -D -i local.wayfinder.mac.finder` 返回 1.0.0；系统开关未启用，右键尚未实测 |
| TC-022 | REQ-001 / AC-001 | P1 E2E | 待用户授权：Wayfinder 辅助功能未开；实际 ⌘X/⌘V、撤销、跨卷和文本编辑回归未运行 |
| TC-023 | REQ-002 / AC-002 | P1 E2E | 待用户授权：Terminal / Ghostty 工作目录实开、工具栏单击尚未运行；未触发自动化授权弹窗 |
| TC-024 | REQ-003 / AC-003 | P1 E2E | 待用户启用扩展：空白处/文件/多选/链接右键复制尚未在 Finder 宿主进程验证 |
| TC-025 | REQ-005 / AC-005 | P1 功能 | UI 通过：提示音默认开，登录启动开关可见。声音播放、登录注册与重新登录启动未实测；未替用户改变登录项 |

## 已解决的验证问题

- 完整 Xcode 未接受许可：没有代用户接受 EULA，改用可用 Command Line Tools。
- Command Line Tools 不含 XCTest：保留 XCTest 测试源，通过轻量断言适配器运行相同测试；17 项实际通过。
- symlink 目录 URL 的目录标志不一致：规范 directory(for:) 输出为明确的目录 URL，原断言通过；没有放宽断言。
- iconutil 在执行沙盒中错误报告 Invalid Iconset：验证尺寸后，在获工具审批的普通主机进程中编译成功。未降低系统安全配置。
- 沙盒内 Launch Services 不可见：已通过获工具审批的启动与只读注册检查确认 App 可运行和扩展已登记。

## 最终人工验收步骤

先将 App 放在固定安装位置，开启「辅助功能」（macOS 27 为「设备控制与数据访问」）和 Finder 扩展。退出正在运行的 Command X，避免混淆结果。只用临时测试文件：

1. 两个临时目录中移动一个测试文件，确认来源消失、目标存在；⌘Z 恢复。取消冲突提示后重新 ⌘X 再试。
2. ⌘X 后 ⌘C 其他内容，确认不会移动先前文件；Finder 重命名/搜索输入框 ⌘X 保持文本剪切；其他 App 不受影响。
3. 从含中文、空格、单引号和 symlink 的路径分别打开 Terminal 与 Ghostty，在新窗口确认 `pwd -P`。
4. 空白处、单个文件、多选文件、符号链接右键复制，与实际绝对路径比较。网络/只读卷行为由 Finder 权限决定。
5. 提示音开/关各剪切一次；登录启动开/关，重新登录后确认只出现菜单栏、不打开设置和终端。

## 100 分证据评分（临时）

| 维度 | 分数 | 证据与扣分 |
|---|---:|---|
| 需求与验收覆盖 | 19/25 | 三项原需求和两项追加功能均有实现；P1 系统交互待授权验证 |
| 功能正确性与边界 | 19/25 | 核心状态、真实路径与注入边界通过；Finder AX 各视图与跨卷未验证 |
| 测试充分性 | 13/20 | 17 项自动测试、真实 UI、脚本语法、签名与注册；缺 E2E |
| 架构与接口 | 9/10 | 原生移动、独立核心、扩展复用路径/URL 契约；终端适配需逐版本回归 |
| 代码质量与安全 | 9/10 | 无第三方依赖、无直接文件删除、参数转义与校验；未做正式安全审计 |
| 文档与交付 | 10/10 | 可构建源代码、App/zip、权限/安装/卸载与测试记录 |
| **合计** | **79/100** | **适合作为本地测试版；尚未满足全部 P1 验收门槛** |

## 独立交付检查

完成一次独立只读检查，结论为 ship（仅限代码和权限页界面检查范围）。未发现有证据的关键实现阻断或必须修复的布局问题；明确不替代 TCC、Finder、终端、音效及登录启动的端到端验收。检查未改变系统权限或用户文件。


## v0.1.0-beta.1 发布验证

REQ-006：首个公开发布明确标记为预发布。README 已列出 arm64、macOS 最低版本、未公证状态和尚待系统权限的 E2E 验收项。版本号 0.1.0，构建号 1；MIT License 随 App 打包。

- TC-026：release 重新构建通过；17 项核心测试回归通过。
- TC-027：DMG 校验和、ZIP 压缩完整性通过；DMG 只读挂载，包内 deep/strict 签名验证通过，主二进制与构建产物完全一致，版本正确，Applications 链接和许可文本存在。
- TC-028：GitHub 仓库改名为 `yangbo-s/Wayfinder`，保持 PUBLIC；origin 已更新，简介与标签已设置。
- TC-029：通过。GitHub Release 已发布（isDraft=false，isPrerelease=true），三个资产均 uploaded；源码提交与标签均为 `4320aeb300a6edc8e92c144701ab281b216263cd`。重新下载 DMG / ZIP，SHA-256 均与本地及随包 SHA256SUMS 一致。发布页：https://github.com/yangbo-s/Wayfinder/releases/tag/v0.1.0-beta.1 。后续 main 的文档验收提交不改变此标签对应的二进制源码。

整体应用评分仍为 79/100：公开测试版发布不改变系统集成验证缺口，也不代表稳定版验收通过。

## v0.1.0-beta.2 修复验收

版本 0.1.0，构建号 2。针对用户报告的普通启动误开终端、图标不一致、重复授权显示和 Finder 两个无响应菜单进行修复。

| 测试 | 需求 | 结果与证据 |
|---|---|---|
| TC-030 | REQ-007 | 先将旧启动分支提取到真实 AppDelegate 使用的 LaunchPolicy；`./scripts/test.sh` 实际出现 21 项中 2 项失败（普通重复启动 / reopen）。修复后共 25 项全通过 |
| TC-031 | REQ-008 | 通过纯逻辑：已授权/监听失败、功能关闭、就绪和未授权分别断言。真实系统设置中旧 Wayfinder 开关开启，但更新后 App 自身受保护访问仍失败；显示“当前 App 的授权尚未生效”，没有伪报已就绪 |
| TC-032 | REQ-009 | Finder 真机复现旧版：点击测试目录的复制菜单后，剪贴板未写入；修复后文件复制、符号链接解析、空白处复制当前目录均实际写入正确值。临时目录含中文与空格；后台菜单不跟随选中的子目录 |
| TC-033 | REQ-002/009 | 部分通过：点击 Finder 工具栏，宿主收到准确目录，Ghostty 脚本成功返回。电脑控制工具禁止访问 Ghostty，因此没有读取终端窗口或确认 pwd；不冒称终端工作目录端到端验收通过 |
| TC-034 | REQ-007 | 通过：安装构建 2 后普通启动显示设置；保留用户当前 Ghostty 选择；菜单栏 / Finder 工具栏为同风格的简化“文件夹＋转向箭头”。设置页图标改为 NSApplication.applicationIconImage，与外部 App 共享资源 |
| TC-035 | REQ-001/008 | 未运行：新二进制尚未获得有效系统辅助功能授权，真实 ⌘X/⌘V 仍需用户授权后验证。没有自动更改权限或重置 TCC |

路径输出采用 Foundation 的解析规则；Apple 文档说明 resolvingSymlinksInPath 可能省略 /private。实测 /tmp 与 /private/tmp 指向同一目标，链接名称会被替换为真实目标。测试核对的是目标路径，不将系统等价前缀误判为复制失败。

本轮证据评分 **84/100**：需求覆盖21/25、正确性20/25、测试15/20、接口9/10、代码与安全9/10、文档交付10/10。提升来自真实 Finder 复制联调和启动回归；扣分仍包括剪切系统授权、完整终端 cwd、跨卷与登录 E2E。发布仍为测试版。

TC-036 / REQ-006：最终 beta.2 宿主及扩展 release 构建通过；四份 plist 校验通过，DMG 校验和、ZIP 完整性通过。只读挂载 DMG 后，宿主与扩展二进制均与 dist 完全一致，deep/strict 签名通过，构建号为 2。本机 Applications 已安装该最终构建，并实看设置页完整 App 图标及 Finder 的简版图标。

TC-037 / REQ-006：已推送源码 `04b483daa5584870ca13653b9524eb2a32323bfb`，标签 `v0.1.0-beta.2` 对应该源码。GitHub Release 已公开发布（isDraft=false / isPrerelease=true），三个资产均为 uploaded；从 GitHub 重新下载 DMG 和 ZIP，`shasum -a 256 -c SHA256SUMS.txt` 两项均 OK。发布页：https://github.com/yangbo-s/Wayfinder/releases/tag/v0.1.0-beta.2 。后续验收文档提交不改变发布标签与二进制。

## v0.1.0-beta.3 验收（2026-10-06）

版本 0.1.0，构建号 3。用户选择保留 Finder 系统下箭头，并改为真正的功能菜单。

| 测试 | 需求 | 结果与证据 |
|---|---|---|
| TC-038 | REQ-011 / API-005 | 通过：严格 URL token、过期/非法请求拒绝、2000 项中文文件请求 JSON 往返；传输使用独立命名 pasteboard，不将路径塞入 URL |
| TC-039 | REQ-011 | 通过：空目录创建、中文/空格/引号名称，原文件不变，撤销删除空目录 |
| TC-040 | REQ-011 | 通过：1 项及 30 项真实文件分组/撤销，逐个检查源位置、目标内容与恢复结果 |
| TC-041 | REQ-011 | 通过：空/非法名称、同名文件与目录、重复选择、缺失源、非目录目标、跨目录源拒绝；无覆盖 |
| TC-042 | REQ-011 | 通过：普通与断裂 symlink 移动链接本身，目标内容未移动；撤销恢复 |
| TC-043 | REQ-011 | 通过：第二个移动注入失败，恢复第一项并清理空目录 |
| TC-044 | REQ-011 | 通过：同时注入移动和回退失败，已移动内容保留在新目录、其余原文件保留；没有递归清理 |
| TC-045 | REQ-011 | 通过：撤销时新源位置占用、目录新增内容、同名文件已替换均拒绝，原内容和替换内容均保留 |
| TC-046 | REQ-011 | Finder E2E 通过：工具栏无选择新建空目录；选中文件后右键新建仍为空，已选文件不动；背景菜单请求显示正确目录，取消后文件列表不变 |
| TC-047 | REQ-011 | Finder E2E 通过：右键单文件移入命名目录；右键两个文件移入命名目录；原位置消失、逐个内容匹配；实际点击撤销恢复两个原文件 |
| TC-048 | REQ-010 | Finder UI 通过：工具栏显示真实菜单；终端文案已统一；所有动作前有图标。首轮发现 Finder 丢失模板着色导致深色图标发黑，已改为发送解析系统 labelColor 的像素，第二轮截图确认清晰可读 |
| TC-049 | REQ-006 | 通过：33 项测试、宿主/扩展 release 构建、4 份 plist、deep/strict 签名、DMG 校验和、ZIP 完整性；只读挂载 DMG 后主程序和扩展与 dist 二进制完全一致，构建号 3 |

本次功能范围证据评分 **87/100**：需求22/25、正确性22/25、测试16/20、架构9/10、代码与安全9/10、文档9/10。新功能核心与本机 Finder 交互已验证；扣分包括真实浅色/VoiceOver、网络卷/文件提供商/并发外部改动的端到端测试，以及整个 App 原有的剪切、终端 cwd 与重新登录验收缺口。单次模拟失败和回退已验证，不把多项移动称为原子事务。仍为 ad-hoc 测试版。

对比旧版本，本轮开始前观察到用户安装的 beta.2 已显示“设备控制与数据访问已启用 / Finder 剪切已就绪”；更新新代码后授权可能再次因签名身份改变而失效。本轮未代用户更改系统权限，且新建文件夹功能不依赖辅助功能或 Finder 自动化权限。

TC-050 / REQ-006：源码 `a884736809688a8151a24f40aa46a4c7b80ee5d9` 与标签 v0.1.0-beta.3 已推送。GitHub Release 为公开预发布（isDraft=false / isPrerelease=true），DMG、ZIP、SHA256SUMS 均 uploaded。重新下载 DMG/ZIP，校验文件两项均 OK。最终 App 已安装到 Applications，安装二进制与 dist 一致。发布页：https://github.com/yangbo-s/Wayfinder/releases/tag/v0.1.0-beta.3 。本条验收提交不改变发布标签对应二进制。


## v0.1.0-beta.4 验收（2026-10-06）

REQ-012 替代 beta.3 的命名弹窗流程。命名弹窗是先前实现选择，并非 Finder 限制。

| 用例 | 关联 | 实际结果与证据 |
|---|---|---|
| TC-051 | REQ-012 | 通过：默认名称、同名文件及断裂符号链接均保留，自动创建编号 4；`testAutomaticNamesPreserveExistingItems` |
| TC-052 | REQ-012 | 通过：注入查名后、mkdir 前的竞争目录，重试编号 2，不复用竞争者目录；`testAutomaticNameRetriesConcurrentCollision` |
| TC-053 | REQ-012 | 通过：空、1 项、3 项目录改名后撤销，按身份找回目录，保留旧路径上的无关替换文件，所有原内容恢复 |
| TC-054 | REQ-012 | 通过：改名后新增内容、移出原父目录均拒绝撤销，原内容保留 |
| TC-055 | REQ-012 | 通过：最终构建工具栏空目录、右键单文件与 3 文件分组三条入口均立即创建并自动进入 Finder 原生名称编辑；未额外按 Return 触发编辑，直接键入 renamed-empty / renamed-single / renamed-multiple 并确认成功。三种改名后的实际撤销均成功，文件内容逐个匹配 |
| TC-056 | REQ-012 | 部分通过：当前构建未获 AX 权限时仍创建并选中，状态解释手动 Return；没有命名/授权弹窗。用户输入取消分支已观察到状态反馈；其他语言菜单、图标/分栏/图库视图与 VoiceOver 本轮未实测 |
| TC-057 | REQ-006 | 通过：最终 DMG 只读挂载、host/extension 与已安装实测二进制逐字节一致、CFBundleVersion 均为 4、deep/strict 签名、DMG 校验、ZIP 解压测试和 SHA-256 均通过 |

核心回归：`./scripts/test.sh` 实际 37 tests, 0 failures。宿主和扩展编译、deep/strict 签名验证通过。测试仅使用本次独立临时目录。

实测修复记录：首个候选创建成功，但没有进入编辑；有限等待后报告 Finder 未就绪。修正扩展发送文件夹请求时的 `OpenConfiguration.activates=false`，防止宿主在揭示后夺回焦点；路径比较统一用 actualURL 的 path，避免 URL 表示差异。该阶段候选安装后，ad-hoc 签名改变使 AX 授权失效，需要用户对该构建重新启用，不能当成实测通过。


进一步定位：用户真实点击同样没有进入编辑，否定“仅自动化测试焦点变化”的解释。App 明确反馈选中项目校验未通过，而辅助功能显示就绪、现有“复制当前位置”能成功读取 Finder 目录，离线 Foundation 路径规范化一致。最终实现改为读取 Finder AXSelectedRows / AXSelectedChildren 中的真实文件 URL，不再将 AppleScript 转换失败静默当作未选中；仍校验前台、文件区域和用户输入。该系统接口差异以真实 Finder 测试作为回归依据，不用模拟路径匹配的单元测试冒充 UI 联调。


最终 UI 修复证据：AX 文件 URL 校验通过后，PID 定向合成 Return 仍未进入编辑。对照 Finder 原生 File → Rename 菜单可稳定进入编辑；最终改为 AXPress 原生命令，工具栏触发后截图实际出现默认名称选中编辑框，单/多选同样无需额外 Return 即可输入新名称。两条失败候选均未推送或发布。最终进程显示辅助功能已启用、Finder 剪切已就绪；测试只操作独立临时文件。

本轮质量评分 **89/100**：需求与验收 23/25（目标三条主路径实测；英文 Finder 列表视图以外仍待测），正确性 23/25（37 项文件边界/回退/撤销测试；云盘和网络卷未覆盖），测试 16/20（真实 UI 的创建/改名/撤销通过；旧剪切/终端/登录完整 E2E 未重跑），架构 9/10（纯文件层与 AX 交互隔离；菜单标题有语言边界），代码 9/10（不发全局按键、身份校验、无覆盖；仍受外部并发变化限制），文档交付 9/10（说明、源码、DMG/ZIP 与公开下载校验齐全；仍无 Developer ID 公证及 Intel 实测包）。本次仅建议明确标示的测试版发布，不宣称稳定版全平台验收。


TC-058 / REQ-006：源码 `eae4e66` 与标签 v0.1.0-beta.4 已推送。公开 Release 非草稿、明确标记 prerelease；DMG（570680 字节）、ZIP（319574 字节）与 SHA256SUMS 全部 uploaded。重新下载后两项 SHA-256 校验均 OK，并与本地校验文件一致。最终 /Applications 构建与下载包源 App 的 designated cdhash 同为 `04dd853d18b6770df519096a60c7e62cfd16b917`，不因打包再次替换安装程序。授权在最终进程已生效。测试原文件已验证内容恢复，并清理本次临时目录与诊断资源。

- DMG SHA-256：`dbe1d59332ae314f764afbc42cd86f4e8c8bc06433c8a14e924c1380759c1a62`
- ZIP SHA-256：`0952816bd7d31dbe3eae826c249206d48ebf034c2b43fd7e99fb5388945156b2`
- 发布页：https://github.com/yangbo-s/Wayfinder/releases/tag/v0.1.0-beta.4

## v0.1.0-beta.5 验收（2026-10-06）

REQ-013 / AC-013：全部五款原创音效入包，在原生设置页选择、试听并持久化。新用户默认轻快剪切，升级保留原有静音开关。资源采用 MIT 许可，未打包 Command X 或系统音效素材。

| 用例 | 输入 / 预期 | 实际结果与证据 |
|---|---|---|
| TC-059 | 五款资源各加载两次，数据不同、ID 缓存且 IsUISound=1 | 通过；7 项音效集成测试在源资源、App 资源和只读 DMG 内各验证 |
| TC-060 | 缺失目录 / 损坏 WAV 应报错，不回退为 Tink | 通过；实际 AudioServices 加载失败路径 |
| TC-061 | 从旧设置升级；未知音效 ID 回到默认，静音保留 | 通过；独立 UserDefaults suite 与真实 AppModel |
| TC-062 | 五个选择保存后重新创建 AppModel | 通过；逐个恢复原选择，静音状态不变 |
| TC-063 | 自动提示关闭，准备剪切不响；主动试听仍可用 | 通过；真实 AppModel 回调与记录播放器 |
| TC-064 | 自动提示打开后准备剪切 | 通过；仅一次播放当前选择，开关持久化 |
| TC-065 | 播放器错误不能抢 Finder 焦点 | 通过；状态可见，不调用 showSettings |
| TC-066 | 实际设置页、五项菜单与试听按钮 | 通过；安装 build 5，真实深色界面无截断，菜单五项齐全。实际“干脆双击”试听触发后无错误，界面选择与 UserDefaults 的 doubleTick 一致。用户正在操作时停止批量切换，不冒称逐项人工听感验收。最终 Finder 权限、监听和扩展均已就绪 |
| TC-067 | App / DMG / ZIP / 单独音效 ZIP 资源完整性 | 本地通过；App 和 DMG 深度严格签名检查通过；ZIP 对五份原试听 WAV 逐字节校验，最早 105 ms 文件也完全保留；音效包含 MIT 许可和生成器。下载验收见下方发布记录 |

`./scripts/test.sh`：37 项核心测试 + 7 项音效集成测试，零失败。构建与测试日志更新到 docs/build-results.txt、docs/test-results.txt。音频均为 mono PCM16 / 48 kHz，起止采样为零，峰值留有余量；原始五个文件未进行二次音量归一化，以保留已提供的试听版本。

验包脚本初次误将 ZIP 的 AppleDouble 元数据（`._*.wav`）计为音频；识别该格式后只统计实际 WAV，五个资源的名称、内容与源文件全部一致。没有删除资源或放宽资源内容断言。

未运行：真实扬声器的听感评估、切换系统音效开关/不同输出设备、剪切完整端到端与登录启动回归。试听本身不需要辅助功能；本轮代码未改动 CutController 的事件或文件移动逻辑。Intel、其他系统版本、浅色和 VoiceOver 保留既有验证边界。

本轮评分 **89/100**：需求 23/25（选择/试听/保存/入包均覆盖，未评估不同输出设备听感），正确性 23/25（资源错误和设置升级通过，真实系统静音开关未操作），测试 16/20（44 项通过及运行中 UI 检查，完整剪切 E2E 未重跑），架构 9/10（选择、播放与 AppModel 分离，无新依赖），代码 9/10（资源名白名单、缓存与释放、音效错误不打断 Finder），交付 9/10（源码、许可、安装包、音效源包与校验；无 Developer ID 公证及 Intel 实测）。仅作为明确标示的测试版交付。

### beta.5 公开发布记录

源码 `ac871e0` 及标签 `v0.1.0-beta.5` 已原子推送至 origin。Release 非草稿、明确标记 prerelease，四项资产全部 uploaded。重新下载后 DMG、App ZIP、音效 ZIP 的 SHA-256 均 OK，下载校验文件与本地一致。

| 资产 | 大小（字节） | SHA-256 |
|---|---:|---|
| Wayfinder-v0.1.0-beta.5-macOS-arm64.dmg | 657850 | 06b80b6127a9f512e6c759d16135c7e4f7629f4215cd95b1647c55972d533c9d |
| Wayfinder-v0.1.0-beta.5-macOS-arm64.zip | 396134 | 32c40e54a1f486d8da2a3e291514544655d1a25a549196496f038df2a150ccbc |
| Wayfinder-v0.1.0-beta.5-Cut-Sounds.zip | 183340 | 8c88c637a0f13710444debdf81057ca3ff375ec8d571d4d7dbee1f1cf67c2463 |

本机 `/Applications/Wayfinder.app` 已更新至 build 5，主程序与发布构建字节一致。保留用户当前“干脆双击”选择及提示音、登录启动开关。只读验收镜像已卸载。发布页：https://github.com/yangbo-s/Wayfinder/releases/tag/v0.1.0-beta.5

本条验收提交不改变发布标签对应二进制。

## v0.1.0-beta.6 验收（2026-10-06）

REQ-014 / AC-014：原五款与新增 F–N 九款合计十四款全部内置，使用已有选择、试听、保存与剪切提示流程。原声文件未重新合成或归一化，机械双击名称标明四种间隔。

| 用例 | 输入 / 预期 | 实际结果与证据 |
|---|---|---|
| TC-068 | 十四款资源、五个旧 ID、升级偏好、逐项保存和回调 | 通过：`./scripts/test.sh` 共 37 项核心 + 8 项音效集成测试，零失败。十四款均可由真实 AudioServices 加载与缓存，IsUISound=1，文件数据和 ID 各不相同；五个 beta.5 ID 仍对应原文件。逐项验证静音时剪切不响、主动试听正确；开启后每次仅调用当前选择一次。缺失/损坏及播放错误不抢焦点 |
| TC-069 | build 6 设置页完整显示十四款，包括机械间隔标签 | 通过：已安装 `/Applications/Wayfinder.app`，首次检查保留原“干脆双击”、提示音开关、登录启动和 Ghostty。真实原生菜单及截图包含十四项，13/20/27/46 ms 名称完整，无截断。用户开始试选后保留其选择，未强行恢复旧值，也未逐个操作真实试听。辅助功能和 Finder 监听随后显示就绪，扩展已启用；未更改系统权限 |
| TC-070 | App、DMG、ZIP、音效源包完整性 | 本地通过：十四个单次 WAV 与源文件逐字节一致，均为 mono PCM16/48 kHz、首尾零采样且无削波。DMG 只读挂载后全部 App 文件与 dist 一致，宿主及扩展 build 均为 6、deep/strict 签名通过；ZIP 内容和两组生成器、指标、MIT 许可均匹配。源资源、App 资源、DMG 资源的八项音效集成测试均通过。公开下载校验通过，见下方发布记录 |

构建日志见 `docs/build-results.txt`，测试日志见 `docs/test-results.txt`。已备份旧本机 App 到 `.build/Wayfinder-before-beta6.zip`；最终安装二进制与已验包产物一致，验收 DMG 已卸载。

未运行：逐项真实扬声器听感、不同系统音效开关/输出设备、完整文件剪切/终端/重新登录 E2E、Intel、其他 macOS、浅色和 VoiceOver。本次仅扩展声音枚举、资源收集与测试，没有改动事件监听、文件移动、Finder、权限或终端逻辑。

本轮范围评分 **89/100**：需求 23/25（十四项入包、保存与播放选择覆盖；不同输出设备待测），正确性 23/25（旧 ID、开关、错误与实际音频加载通过；系统静音开关未实测），测试 16/20（45 项通过、真实菜单检查；未逐项人工听感或重跑完整剪切 E2E），架构 9/10（沿用枚举和缓存播放器，无依赖扩展），代码 9/10（资源白名单及错误边界保留；未做全平台审计），交付 9/10（源码、许可、安装与音效包完整；仍无 Developer ID 公证与 Intel 实测）。仅作为明确标示的测试版交付。


### beta.6 公开发布记录

源码 `bb96cfc4cd7070b8c7e7e3ff99e1e2305a6367eb` 与标签 `v0.1.0-beta.6` 已原子推送。Release 非草稿、明确标记 prerelease，四个资产均为 uploaded。从 GitHub 重新下载全部资产，三个包的 SHA-256 全部 OK，下载校验文件与本地一致。

| 资产 | 大小（字节） | SHA-256 |
|---|---:|---|
| Wayfinder-v0.1.0-beta.6-macOS-arm64.dmg | 680455 | 0eaa1625d7cd24b1d02dcacf37aa91c11ba49cb4412363c66ffe61278b8f636e |
| Wayfinder-v0.1.0-beta.6-macOS-arm64.zip | 424389 | e50ff5ef84e66eb9efc8dac7d87e1794d7016a619c572edbcf334d09972e5370 |
| Wayfinder-v0.1.0-beta.6-Cut-Sounds.zip | 339439 | 91941c2d9fdfe416740e5531d3d33cda11fe46a2daf4978932db134b3e219b57 |

发布页：https://github.com/yangbo-s/Wayfinder/releases/tag/v0.1.0-beta.6

本条验收提交仅补充公开下载证据，不改变发布标签与已安装二进制。

## Sparkle 接入本地验收（2026-10-09，build 7，未发布）

关联 REQ-015 / AC-015、REQ-016 / AC-016；需求、接口与发布顺序见 [SPARKLE.md](SPARKLE.md)。本轮按用户“先完成代码和验证”执行，未推送、发布或替换 `/Applications/Wayfinder.app`。Developer ID 并非 Sparkle 的必要条件；本轮实际验证 ad-hoc + Hardened Runtime + 仅宿主关闭 Library Validation 的组合，未更改系统 Gatekeeper。正式身份构建继续使用不含该例外的原 entitlement 文件。

| 用例 | 实际结果与证据 |
|---|---|
| TC-071 | 通过：真实 SPUUpdater 启动、启动幂等、两个自动选项默认关闭、安装依赖自动检查、关掉检查保留安装偏好、跨控制器持久化；独立测试 bundle/domain，不修改用户设置 |
| TC-072 | 通过：文件操作期间保存 Sparkle 安装回调，结束时仅调用一次，空闲时不延迟；属于回调行为测试，未用真实 Finder 长时间操作触发更新重启 |
| TC-073 | 通过：真实官方工具对 archive/feed 签名并验证；篡改 archive/feed、错误 bundle ID、公钥、显示版本、禁用验签配置、重复构建号、被篡改旧 feed 均拒绝，失败不覆盖原输出。7 项 Python 测试 |
| TC-074 | 部分通过：独立测试 App 实际打开设置页、切换两个开关；有效本地签名 feed 被发现，下载、解压、安装成功，磁盘 build 从 7 变为 8，进程重启。首次界面读数仍为 7，再次退出并打开后实际显示 8；自动重启后的首次版本刷新未完全确认。空 feed 检查时间更新，但未捕获“已是最新版”窗口。关闭本机测试服务后出现 Sparkle Update Error，关闭错误后检查按钮重新可用 |
| TC-075 | 本地通过：arm64 宿主/扩展 build 7，嵌入 Sparkle 2.10.0 及安装助手、许可、rpath；最终 App deep/strict 签名通过，flags 为 adhoc/runtime。最终 ZIP 的 117 个文件及符号链接与 App 一致，DMG 校验和、App ZIP 与音效 ZIP 压缩完整性、四项 SHA-256 校验通过。未验证 Developer ID、公证或公开下载 |

自动化总计 **58 项通过，0 失败**：37 项核心、8 项音效、6 项真实 Sparkle/安装回调集成、7 项发布签名测试。日志见 [sparkle-test-results.txt](sparkle-test-results.txt) 与 [sparkle-build-results.txt](sparkle-build-results.txt)。沙盒内首次打包因 iconutil 权限失败；经工具批准在本机重跑完整打包成功，并非忽略失败继续交付。

真实 UI 更新使用独立 `local.wayfinder.preview.sparkle`、本次生成的测试目录和仅监听 `127.0.0.1:18763` 的服务；测试包去掉 Finder 扩展与 URL scheme，避免抢占正常安装。只在该测试包中允许本机 HTTP，正式 Info.plist 仍为 HTTPS。完成后已退出测试 App、停止本机服务。开发中的正式更新源仍是已签名空 feed，生成的 release appcast 仅在 dist，尚未对外生效。

UI 独立审查 disposition：**ship**（仅界面范围），实际深色截图见本地 `.impeccable/review/sparkle-macos.png` 与 `sparkle-macos-enabled.png`，未见裁切或状态解释缺失。浅色、VoiceOver、其他窗口宽度、其他 macOS/Intel、自动下载后退出安装的完整调度路径、真实文件操作与重启并发未实测；未重跑无关 Finder 全流程，不称作完整线上更新验收。

本轮范围评分 **88/100**：需求 24/25（三个控件及依赖状态齐全，后台安装完整调度仍待测），正确性 22/25（验签与本机安装通过，首次重启界面读数差异未确认），测试 16/20（58 项及真实安装/网络失败，正式签名与其他系统未覆盖），架构 9/10（Sparkle 负责调度与安装，宿主只适配状态和忙碌回调），代码 9/10（固定依赖、密钥留在钥匙串、原子写 feed、显式 ad-hoc 构建），文档交付 8/10（源码、说明、日志与本地包齐全；按本轮范围未做线上发布验证）。

本地包：`dist/Wayfinder-v0.1.0-beta.7-macOS-arm64.dmg` / `.zip`。SHA-256：DMG `6d7f13a83f391a6e749cd7ef43ec371629278aae5b90a33e302a6065befe941b`，App ZIP `f4edbfc1bd2dd690929e95588eb54724014fddf9d0c75a2977278d137fb99e01`。这些是待发布产物，不能据此声称 beta.7 已在 GitHub 上线。
