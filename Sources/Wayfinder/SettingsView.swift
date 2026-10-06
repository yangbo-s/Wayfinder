import SwiftUI
import WayfinderCore

struct SettingsView: View {
    @ObservedObject var model: AppModel
    @State private var page: Page = .general
    enum Page: String, CaseIterable {
        case general = "概览", terminal = "终端", permissions = "权限与设置"
        var symbol: String {
            switch self { case .general: return "folder"; case .terminal: return "terminal"; case .permissions: return "slider.horizontal.3" }
        }
    }
    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 22) {
                HStack(spacing: 10) {
                    Image(nsImage: NSApplication.shared.applicationIconImage)
                        .resizable().frame(width: 34, height: 34).accessibilityHidden(true)
                    Text("Wayfinder").font(.system(size: 17, weight: .semibold))
                }.padding(.top, 14).padding(.horizontal, 8)
                VStack(spacing: 5) {
                    ForEach(Page.allCases, id: \.self) { item in
                        Button { page = item } label: {
                            Label(item.rawValue, systemImage: item.symbol)
                                .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 12).padding(.vertical, 10)
                                .background(page == item ? Color.accentColor.opacity(0.13) : .clear, in: RoundedRectangle(cornerRadius: 7))
                                .foregroundStyle(page == item ? Color.accentColor : .primary)
                        }.buttonStyle(.plain).accessibilityAddTraits(page == item ? .isSelected : [])
                    }
                }
                Spacer()
                VStack(alignment: .leading, spacing: 5) {
                    Text("Finder，顺手一点。").font(.system(size: 12))
                    Text("Wayfinder \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.1.0") (\(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "2")) · 本地运行").font(.system(size: 11)).foregroundStyle(.secondary)
                }.padding(.horizontal, 8).padding(.bottom, 10)
            }.padding(16).frame(width: 190).background(Color(nsColor: .controlBackgroundColor))
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 7) {
                        Text(page.rawValue).font(.system(size: 27, weight: .semibold))
                        Text(subtitle).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    }
                    if let notice = model.notice {
                        HStack(alignment: .top, spacing: 9) {
                            Image(systemName: model.noticeIsError ? "exclamationmark.circle" : "checkmark.circle")
                            Text(notice).textSelection(.enabled).fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 0)
                            Button { model.notice = nil } label: { Image(systemName: "xmark") }
                                .buttonStyle(.plain).accessibilityLabel("关闭提示")
                        }.font(.system(size: 12)).padding(12)
                            .background((model.noticeIsError ? Color.orange : Color.accentColor).opacity(0.10), in: RoundedRectangle(cornerRadius: 8))
                    }
                    switch page {
                    case .general: general
                    case .terminal: terminal
                    case .permissions: permissions
                    }
                }.padding(30).frame(maxWidth: .infinity, alignment: .leading)
            }.background(Color(nsColor: .windowBackgroundColor))
        }.frame(minWidth: 760, idealWidth: 780, minHeight: 610, idealHeight: 650)
    }
    private var subtitle: String {
        switch page {
        case .general: return "移动文件、打开终端、复制路径，都留在 Finder 里。"
        case .terminal: return "从当前位置出发，打开你习惯的终端。"
        case .permissions: return "只在需要时授权，随时可以关闭。"
        }
    }
    private var general: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(spacing: 0) {
                feature("剪切文件", detail: "选中文件按 ⌘X，在目标文件夹按 ⌘V。", symbol: "scissors", trailing: "⌘X  →  ⌘V")
                Divider().padding(.leading, 36)
                feature("在当前目录下打开终端", detail: "从右键菜单或 Finder 工具栏菜单打开。", symbol: "terminal", trailing: model.terminal.name)
                Divider().padding(.leading, 36)
                feature("复制实际路径", detail: "右键文件或空白处，复制完整绝对路径。", symbol: "link", trailing: "/path")
            }
            if model.lastCreatedFolder != nil {
                Button("撤销新建文件夹", action: model.undoFolderCreation).disabled(!model.canUndoFolder)
            }
            if !model.cutStatus.isEmpty {
                Label(model.cutStatus, systemImage: "scissors").font(.system(size: 12)).foregroundStyle(Color.accentColor)
            }
            if model.conflictingApp {
                Label("检测到 Command X 正在运行。使用剪切功能前，请先退出 Command X，避免快捷键冲突。", systemImage: "exclamationmark.triangle")
                    .font(.system(size: 12)).fixedSize(horizontal: false, vertical: true)
            }
            VStack(alignment: .leading, spacing: 14) {
                Text("准备好 Finder").font(.headline)
                accessibilityStatus
                permissionRow("Finder 扩展", detail: "用于右键菜单与工具栏菜单", enabled: model.extensionEnabled, action: model.manageExtension)
            }.padding(18).background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
            HStack {
                Button("在当前目录下打开终端") { model.openTerminal() }.buttonStyle(.borderedProminent)
                Button("复制当前位置") { model.copyCurrentPath() }
            }.controlSize(.large)
        }
    }
    private func feature(_ title: String, detail: String, symbol: String, trailing: String) -> some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: symbol).font(.system(size: 19)).frame(width: 24).foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.system(size: 14, weight: .medium))
                Text(detail).font(.system(size: 12)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 6)
            Text(trailing).font(.system(size: 12, design: .monospaced)).foregroundStyle(.secondary)
        }.padding(.vertical, 17)
    }
    private var terminal: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 12) {
                Text("默认终端").font(.headline)
                Picker("选择终端", selection: $model.terminal) {
                    ForEach(TerminalChoice.allCases) { choice in
                        Text(choice.name + (TerminalLauncher.installed(choice) ? "" : "（未安装）")).tag(choice)
                    }
                }.labelsHidden().frame(maxWidth: .infinity, alignment: .leading)
                Text("初始为系统 Terminal。更改后，所有 Finder 入口立即使用所选终端。")
                    .font(.system(size: 12)).foregroundStyle(.secondary)
            }
            if model.terminal == .custom {
                Divider()
                VStack(alignment: .leading, spacing: 12) {
                    HStack { Text("终端应用").font(.headline); Spacer(); Button("选择 .app…", action: model.chooseCustomApp) }
                    Text(model.customApp.isEmpty ? "尚未选择" : model.customApp).font(.system(size: 12, design: .monospaced)).textSelection(.enabled)
                    Text("启动参数（JSON 数组）").font(.system(size: 12, weight: .medium))
                    TextField("[\"--working-directory={path}\"]", text: $model.customArguments, axis: .vertical)
                        .font(.system(size: 12, design: .monospaced)).textFieldStyle(.roundedBorder).lineLimit(2...4)
                    Text("{path} 会替换为实际目录；请按该终端的文档填写参数。每次启动新实例，参数不经过 shell。")
                        .font(.system(size: 12)).foregroundStyle(.secondary)
                }
            }
            Divider()
            VStack(alignment: .leading, spacing: 12) {
                Label("工具栏快捷菜单", systemImage: "cursorarrow.click").font(.headline)
                Text("启用 Finder 扩展后，在 Finder 工具栏右键选择“自定工具栏”，加入 Wayfinder 文件夹按钮。点击按钮可选择打开终端、复制路径或新建文件夹。普通打开 Wayfinder.app 始终显示设置。")
                    .font(.system(size: 13)).fixedSize(horizontal: false, vertical: true)
                Text("右键文件时打开其所在目录；右键文件夹时打开该文件夹。Finder 的“最近使用”等虚拟视图没有单一实际目录。")
                    .font(.system(size: 12)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
            Button("用 Finder 当前文件夹测试") { model.openTerminal() }.controlSize(.large)
            Text("无论是否选中文件，都可右键新建空文件夹；选中单个或多个项目时，还可将它们一起放入新文件夹。操作后可从 Wayfinder 菜单栏撤销本次新建。")
                .font(.system(size: 12)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            if model.terminal == .ghostty {
                Text("Ghostty 需要提供 new window / surface configuration 的 AppleScript 接口；旧版本请先更新。")
                    .font(.system(size: 12)).foregroundStyle(.secondary)
            }
        }
    }
    private var permissions: some View {
        VStack(alignment: .leading, spacing: 22) {
            Toggle("启用 Finder 文件剪切", isOn: $model.cutEnabled).toggleStyle(.switch)
            Text("只转换 Finder 文件区域的快捷键。重命名、搜索框和其他应用保持原有行为。按 Esc 或复制其他内容可取消剪切。")
                .font(.system(size: 12)).foregroundStyle(.secondary)
            Toggle("剪切成功时播放提示音", isOn: $model.playCutSound).toggleStyle(.switch)
            Text("确认文件已进入待移动状态后，播放一次轻提示音。")
                .font(.system(size: 12)).foregroundStyle(.secondary)
            Divider()
            accessibilityStatus
            permissionRow("Finder 扩展", detail: "在系统设置中勾选 Wayfinder Finder", enabled: model.extensionEnabled, action: model.manageExtension)
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("自动化").font(.system(size: 13, weight: .medium))
                    Text("首次打开终端时，允许控制 Finder 与所选终端。").font(.system(size: 12)).foregroundStyle(.secondary)
                }
                Spacer()
                Button("系统设置…") { model.openSettings("x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") }
            }
            Divider()
            Toggle("登录时启动", isOn: Binding(get: { model.launchAtLogin }, set: model.setLogin)).toggleStyle(.switch)
            Text("关闭窗口后仍在菜单栏运行。从菜单栏选择“退出 Wayfinder”可停止快捷键功能。")
                .font(.system(size: 12)).foregroundStyle(.secondary)
            Text("所有操作在本机完成，不上传路径或文件。")
                .font(.system(size: 12)).foregroundStyle(.secondary)
        }
    }
    private var accessibilityStatus: some View {
        VStack(alignment: .leading, spacing: 10) {
            permissionRow(model.accessibilityTitle, detail: "系统授权状态，与快捷键监听分别检查", enabled: model.trusted, action: model.requestAccessibility)
            HStack {
                Text(model.keyboardReadiness.title).font(.system(size: 12)).foregroundStyle(.secondary)
                Spacer()
                Button(model.trusted ? "重试监听" : "重新检查", action: model.retryListener)
            }
            if !model.trusted || (model.cutEnabled && !model.listenerRunning) {
                Text("系统开关已打开但这里未刷新？先重新检查，或重启 App。测试版更新后，macOS 可能要求重新授权当前版本。")
                    .font(.system(size: 11)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                HStack {
                    Button("重新启动 Wayfinder", action: model.restartApp)
                    Button("显示当前 App") { NSWorkspace.shared.activateFileViewerSelecting([Bundle.main.bundleURL]) }
                }.font(.system(size: 11))
            }
        }
    }
    private func permissionRow(_ title: String, detail: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            Image(systemName: enabled ? "checkmark.circle.fill" : "circle.dashed")
                .foregroundStyle(enabled ? Color.green : Color.secondary).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 13, weight: .medium))
                Text(detail).font(.system(size: 11)).foregroundStyle(.secondary)
            }
            Spacer()
            if enabled { Text("已启用").font(.system(size: 12)).foregroundStyle(.secondary) }
            else { Button("去启用…", action: action) }
        }
    }
}
