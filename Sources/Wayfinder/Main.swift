import AppKit
import SwiftUI
import Carbon

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
    private var status: NSStatusItem!
    private var window: NSWindow?
    private var handledExternalAction = false
    private var launched = Date()

    func applicationDidFinishLaunching(_ notification: Notification) {
        model.showSettings = { [weak self] in self?.showSettings() }
        model.start()
        setupApplicationMenu()
        status = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        status.button?.image = NSImage(systemSymbolName: "arrow.turn.down.right", accessibilityDescription: "Wayfinder")
        status.button?.toolTip = "Wayfinder · Finder 工具"
        let menu = NSMenu(); menu.delegate = self; status.menu = menu
        let event = NSAppleEventManager.shared().currentAppleEvent
        let isLoginLaunch = event?.paramDescriptor(forKeyword: keyAEPropData)?.enumCodeValue == keyAELaunchedAsLogInItem
        let firstLaunch = !UserDefaults.standard.bool(forKey: "hasLaunched")
        UserDefaults.standard.set(true, forKey: "hasLaunched")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            guard let self, !self.handledExternalAction else { return }
            if isLoginLaunch || CommandLine.arguments.contains("--background") { return }
            if firstLaunch || CommandLine.arguments.contains("--settings") { self.showSettings() }
            else { self.model.openTerminal() }
        }
    }
    func application(_ application: NSApplication, open urls: [URL]) {
        handledExternalAction = true
        for url in urls { model.handleURL(url) }
    }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        guard Date().timeIntervalSince(launched) > 1 else { return false }
        model.openTerminal()
        return false
    }
    func applicationWillTerminate(_ notification: Notification) { model.cut.stop() }
    func menuWillOpen(_ menu: NSMenu) {
        menu.removeAllItems()
        let statusText = model.cutStatus.isEmpty
            ? (model.trusted ? (model.cutEnabled ? "Finder 剪切已启用" : "Finder 剪切已暂停") : "剪切需要辅助功能权限")
            : model.cutStatus
        let summary = menu.addItem(withTitle: statusText, action: nil, keyEquivalent: ""); summary.isEnabled = false
        menu.addItem(.separator())
        add(menu, "在当前位置打开 \(model.terminal.name)", #selector(openTerminal))
        add(menu, "复制当前文件夹实际路径", #selector(copyPath))
        menu.addItem(.separator())
        add(menu, "设置…", #selector(showSettings), key: ",")
        add(menu, "退出 Wayfinder", #selector(quit), key: "q")
    }
    private func add(_ menu: NSMenu, _ title: String, _ action: Selector, key: String = "") {
        let item = menu.addItem(withTitle: title, action: action, keyEquivalent: key); item.target = self
    }
    @objc func showSettings() {
        if window == nil {
            let host = NSHostingController(rootView: SettingsView(model: model))
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
    @objc private func quit() { NSApp.terminate(nil) }
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
