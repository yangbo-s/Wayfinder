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
    override var toolbarItemToolTip: String { "打开 Wayfinder 功能菜单" }
    override var toolbarItemImage: NSImage {
        WayfinderSymbol.image()
    }
    private var context: FinderActionContext {
        let controller = FIFinderSyncController.default()
        return FinderActionContext(target: controller.targetedURL(), selection: controller.selectedItemURLs() ?? [])
    }
    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        let current = context
        let menu = NSMenu()
        let isItem = menuKind == .contextualMenuForItems
        guard isItem ? !current.selectedOrTarget.isEmpty : current.target != nil else {
            let item = menu.addItem(withTitle: "请先打开一个实际文件夹", action: nil, keyEquivalent: "")
            item.isEnabled = false
            return menu
        }
        add("在当前目录下打开终端", isItem ? #selector(openSelectedTerminal(_:)) : #selector(openCurrentTerminal(_:)), symbol: "terminal", to: menu)
        add(isItem ? "复制所选项目的实际路径" : "复制当前文件夹的实际路径",
            isItem ? #selector(copySelectedPaths(_:)) : #selector(copyCurrentPath(_:)), symbol: "doc.on.doc", to: menu)
        if isItem, current.commonParent != nil {
            add("复制所在文件夹的实际路径", #selector(copyParentPath(_:)), symbol: "folder", to: menu)
        }
        menu.addItem(.separator())
        add("新建空文件夹", isItem ? #selector(newEmptyBesideSelection(_:)) : #selector(newEmptyInCurrent(_:)), symbol: "folder.badge.plus", to: menu)
        if !current.selection.isEmpty {
            let title = current.selection.count == 1 ? "将所选项目放入新文件夹" : "将所选的 \(current.selection.count) 个项目放入新文件夹"
            add(title, #selector(newFolderWithSelection(_:)), symbol: "folder.fill.badge.plus", to: menu)
            menu.items.last?.isEnabled = current.commonParent != nil
        }
        return menu
    }
    private func add(_ title: String, _ action: Selector, symbol: String, to menu: NSMenu) {
        // Finder recreates NSMenuItem across processes. Query its context in
        // the action instead of depending on representedObject or identity.
        let item = menu.addItem(withTitle: title, action: action, keyEquivalent: "")
        item.image = menuImage(symbol)
    }
    private func menuImage(_ name: String) -> NSImage? {
        guard let symbol = NSImage(systemSymbolName: name, accessibilityDescription: nil) else { return nil }
        // Finder's menu transport drops template tinting. Resolve the system text
        // color in the current appearance before sending pixels across processes.
        let image = NSImage(size: NSSize(width: 16, height: 16))
        NSApplication.shared.effectiveAppearance.performAsCurrentDrawingAppearance {
            image.lockFocus()
            let rect = NSRect(x: 0, y: 0, width: 16, height: 16)
            symbol.draw(in: rect)
            NSColor.labelColor.setFill()
            rect.fill(using: .sourceIn)
            image.unlockFocus()
        }
        return image
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
    @objc private func newEmptyBesideSelection(_ sender: NSMenuItem) {
        sendFolderRequest(directory: context.commonParent, items: [], mode: .empty)
    }
    @objc private func newEmptyInCurrent(_ sender: NSMenuItem) {
        sendFolderRequest(directory: context.target, items: [], mode: .empty)
    }
    @objc private func newFolderWithSelection(_ sender: NSMenuItem) {
        let current = context
        sendFolderRequest(directory: current.commonParent, items: current.selection, mode: .selection)
    }
    private func sendFolderRequest(directory: URL?, items: [URL], mode: FolderRequest.Mode) {
        guard let directory else { reportFailure("missing-location"); return }
        let token = UUID()
        let board = NSPasteboard(name: .init(FolderRequest.pasteboardName(token)))
        do {
            board.declareTypes([.init(FolderRequest.pasteboardType)], owner: nil)
            let request = FolderRequest(mode: mode, directory: directory.path, items: items.map(\.path))
            try request.validate()
            let data = try JSONEncoder().encode(request)
            guard board.setData(data, forType: .init(FolderRequest.pasteboardType)) else { throw FolderError.invalidRequest }
            openHost(FolderRequest.url(token: token)) { board.releaseGlobally() }
            // A killed host must not leave request data around indefinitely.
            DispatchQueue.main.asyncAfter(deadline: .now() + 300) { board.releaseGlobally() }
        } catch {
            board.releaseGlobally(); reportFailure("missing-location")
        }
    }
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
    private func openHost(_ request: URL, onFailure: (() -> Void)? = nil) {
        // Use the matching containing app when more than one build exists.
        let appURL = Bundle.main.bundleURL.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let configuration = NSWorkspace.OpenConfiguration()
        // Folder actions finish in Finder. Launching the host must not take
        // focus back after it reveals the new folder for inline rename.
        if request.host == "folder" { configuration.activates = false }
        NSWorkspace.shared.open([request], withApplicationAt: appURL, configuration: configuration) { [weak self] _, error in
            if let error {
                onFailure?()
                self?.logger.error("Cannot open containing app: \(error.localizedDescription, privacy: .public)")
                DispatchQueue.main.async { NSSound.beep() }
            }
        }
    }
}
