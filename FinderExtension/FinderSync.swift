import AppKit
import FinderSync
import OSLog

final class FinderSync: FIFinderSync {
    private let logger = Logger(subsystem: "local.wayfinder.mac.finder", category: "actions")
    override init() {
        super.init()
        FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]
    }
    override var toolbarItemName: String { "Wayfinder" }
    override var toolbarItemToolTip: String { "在当前文件夹打开终端" }
    override var toolbarItemImage: NSImage {
        WayfinderSymbol.image()
    }
    private var context: FinderActionContext {
        let controller = FIFinderSyncController.default()
        return FinderActionContext(target: controller.targetedURL(), selection: controller.selectedItemURLs() ?? [])
    }
    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        let current = context
        if menuKind == .toolbarItemMenu, let target = current.target {
            // The extension button is an explicit terminal action; opening the
            // containing .app remains a settings action.
            openTerminal(at: target)
            return nil
        }
        let menu = NSMenu()
        let isItem = menuKind == .contextualMenuForItems || menuKind == .contextualMenuForSidebar
        guard isItem ? !current.selectedOrTarget.isEmpty : current.target != nil else {
            let item = menu.addItem(withTitle: "请先打开一个实际文件夹", action: nil, keyEquivalent: "")
            item.isEnabled = false
            return menu
        }
        add("在这里打开终端", isItem ? #selector(openSelectedTerminal(_:)) : #selector(openCurrentTerminal(_:)), to: menu)
        add(isItem ? "复制所选项目的实际路径" : "复制当前文件夹的实际路径",
            isItem ? #selector(copySelectedPaths(_:)) : #selector(copyCurrentPath(_:)), to: menu)
        if isItem, current.commonParent != nil {
            add("复制所在文件夹的实际路径", #selector(copyParentPath(_:)), to: menu)
        }
        return menu
    }
    private func add(_ title: String, _ action: Selector, to menu: NSMenu) {
        // Finder recreates NSMenuItem across processes. Query its context in
        // the action instead of depending on representedObject or identity.
        menu.addItem(withTitle: title, action: action, keyEquivalent: "")
    }
    @objc private func openCurrentTerminal(_ sender: NSMenuItem) {
        guard let url = context.target else { reportFailure("missing-location"); return }
        openTerminal(at: url)
    }
    @objc private func openSelectedTerminal(_ sender: NSMenuItem) {
        guard let url = context.selectedOrTarget.first else { reportFailure("missing-location"); return }
        openTerminal(at: url)
    }
    @objc private func copyCurrentPath(_ sender: NSMenuItem) {
        copy(context.target.map { [$0] } ?? [])
    }
    @objc private func copySelectedPaths(_ sender: NSMenuItem) { copy(context.selectedOrTarget) }
    @objc private func copyParentPath(_ sender: NSMenuItem) { copy(context.commonParent.map { [$0] } ?? []) }
    private func openTerminal(at url: URL) {
        guard let request = TerminalRequest.url(path: url.path) else { reportFailure("missing-location"); return }
        openHost(request)
    }
    private func copy(_ urls: [URL]) {
        do {
            let text = try PathResolver.copiedPaths(urls)
            NSPasteboard.general.clearContents()
            guard NSPasteboard.general.setString(text, forType: .string) else {
                reportFailure("clipboard-write-failed"); return
            }
        } catch { reportFailure("missing-location") }
    }
    private func reportFailure(_ code: String) {
        logger.error("Finder action failed: \(code, privacy: .public)")
        var parts = URLComponents()
        parts.scheme = "wayfinder"; parts.host = "error"
        parts.queryItems = [URLQueryItem(name: "reason", value: code)]
        if let url = parts.url { openHost(url) }
    }
    private func openHost(_ request: URL) {
        // Use the matching containing app when more than one build exists.
        let appURL = Bundle.main.bundleURL.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        NSWorkspace.shared.open([request], withApplicationAt: appURL, configuration: NSWorkspace.OpenConfiguration()) { [weak self] _, error in
            if let error {
                self?.logger.error("Cannot open containing app: \(error.localizedDescription, privacy: .public)")
                DispatchQueue.main.async { NSSound.beep() }
            }
        }
    }
}
