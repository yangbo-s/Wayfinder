import AppKit
import SwiftUI
import Carbon
import WayfinderCore

@main
enum WayfinderMain {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        withExtendedLifetime(delegate) { app.run() }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    let model = AppModel()
    let updater = AppUpdater()
    private var status: NSStatusItem!
    private var window: NSWindow?
    private var handledExternalAction = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        model.showSettings = { [weak self] in self?.showSettings() }
        model.start()
        model.folderActivityChanged = { [weak self] busy in self?.updater.relaunchGate.isBusy = busy }
        updater.start()
        setupApplicationMenu()
        status = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        status.button?.image = WayfinderSymbol.image()
        status.button?.toolTip = "Wayfinder · Finder 工具"
        let menu = NSMenu(); menu.delegate = self; status.menu = menu
        let event = NSAppleEventManager.shared().currentAppleEvent
        let isLoginLaunch = event?.paramDescriptor(forKeyword: keyAEPropData)?.enumCodeValue == keyAELaunchedAsLogInItem
        let firstLaunch = !UserDefaults.standard.bool(forKey: "hasLaunched")
        UserDefaults.standard.set(true, forKey: "hasLaunched")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            guard let self else { return }
            self.performLaunchAction(LaunchPolicy.initial(hasLaunchedBefore: !firstLaunch,
                isLoginLaunch: isLoginLaunch, arguments: CommandLine.arguments,
                handledExternalAction: self.handledExternalAction))
        }
    }
    func application(_ application: NSApplication, open urls: [URL]) {
        handledExternalAction = true
        for url in urls { model.handleURL(url) }
    }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        performLaunchAction(LaunchPolicy.reopen())
        return false
    }
    private func performLaunchAction(_ action: LaunchAction) {
        switch action {
        case .showSettings: showSettings()
        case .stayInBackground: break
        }
    }
    func applicationDidBecomeActive(_ notification: Notification) { model.refresh() }
    func applicationWillTerminate(_ notification: Notification) { model.cut.stop() }
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard !model.folderBusy else {
            model.noticeIsError = true; model.notice = "文件夹操作尚未完成，请完成或取消后再退出。"
            return .terminateCancel
        }
        return .terminateNow
    }
    func menuWillOpen(_ menu: NSMenu) {
        menu.removeAllItems()
        let statusText = model.cutStatus.isEmpty
            ? model.keyboardReadiness.title
            : model.cutStatus
        let summary = menu.addItem(withTitle: statusText, action: nil, keyEquivalent: ""); summary.isEnabled = false
        menu.addItem(.separator())
        add(menu, "在当前目录下打开终端（\(model.terminal.name)）", #selector(openTerminal))
        add(menu, "复制当前文件夹实际路径", #selector(copyPath))
        if model.lastCreatedFolder != nil {
            add(menu, "撤销新建文件夹", #selector(undoFolder))
            menu.items.last?.isEnabled = model.canUndoFolder
        }
        menu.addItem(.separator())
        add(menu, "设置…", #selector(showSettings), key: ",")
        add(menu, updater.availableVersion.map { "查看更新（\($0)）…" } ?? "检查更新…", #selector(checkForUpdates))
        menu.items.last?.isEnabled = updater.canCheckForUpdates
        add(menu, "退出 Wayfinder", #selector(quit), key: "q")
    }
    private func add(_ menu: NSMenu, _ title: String, _ action: Selector, key: String = "") {
        let item = menu.addItem(withTitle: title, action: action, keyEquivalent: key); item.target = self
    }
    @objc func showSettings() {
        if window == nil {
            let host = NSHostingController(rootView: SettingsView(model: model, updater: updater))
            let w = NSWindow(contentViewController: host)
            w.title = "Wayfinder"; w.setContentSize(NSSize(width: 800, height: 660))
            w.styleMask = [.titled, .closable, .miniaturizable, .resizable]
            w.minSize = NSSize(width: 780, height: 640)
            w.isReleasedWhenClosed = false; w.center()
            window = w
        }
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
    @objc private func openTerminal() { model.openTerminal() }
    @objc private func copyPath() { model.copyCurrentPath() }
    @objc private func undoFolder() { model.undoFolderCreation() }
    @objc private func quit() { NSApp.terminate(nil) }
    @objc private func checkForUpdates() { updater.checkForUpdates() }
    private func setupApplicationMenu() {
        let bar = NSMenu()
        let appItem = NSMenuItem(); bar.addItem(appItem)
        let appMenu = NSMenu(); appItem.submenu = appMenu
        add(appMenu, "设置…", #selector(showSettings), key: ",")
        add(appMenu, "退出 Wayfinder", #selector(quit), key: "q")
        let edit = NSMenuItem(); bar.addItem(edit); edit.submenu = NSMenu(title: "编辑")
        for (title, selector, key) in [("撤销", "undo:", "z"), ("剪切", "cut:", "x"), ("复制", "copy:", "c"), ("粘贴", "paste:", "v"), ("全选", "selectAll:", "a")] {
            edit.submenu?.addItem(withTitle: title, action: Selector(selector), keyEquivalent: key)
        }
        NSApp.mainMenu = bar
    }
}
