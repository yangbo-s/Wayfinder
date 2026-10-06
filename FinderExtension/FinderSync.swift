import AppKit
import FinderSync

final class FinderSync: FIFinderSync {
    override init() {
        super.init()
        // Observe navigation only: no recursion, file watching, badges or file I/O.
        FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]
    }
    override var toolbarItemName: String { "Wayfinder" }
    override var toolbarItemToolTip: String { "在这里打开终端或复制实际路径" }
    override var toolbarItemImage: NSImage {
        NSImage(systemSymbolName: "arrow.turn.down.right", accessibilityDescription: "Wayfinder")!
    }
    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        let controller = FIFinderSyncController.default()
        let menu = NSMenu()
        let selected = controller.selectedItemURLs() ?? []
        let target = controller.targetedURL()
        let isItem = menuKind == .contextualMenuForItems || menuKind == .contextualMenuForSidebar
        let items = isItem && !selected.isEmpty ? selected : target.map { [$0] } ?? []
        guard !items.isEmpty else { return nil }
        add("在这里打开终端", #selector(openTerminal(_:)), to: menu, urls: [items[0]])
        add(isItem ? "复制所选项目的实际路径" : "复制当前文件夹的实际路径", #selector(copyPaths(_:)), to: menu, urls: items)
        if isItem {
            let parents = Set(items.map { $0.deletingLastPathComponent() })
            if parents.count == 1, let parent = parents.first {
                add("复制所在文件夹的实际路径", #selector(copyPaths(_:)), to: menu, urls: [parent])
            }
        }
        return menu
    }
    private func add(_ title: String, _ action: Selector, to menu: NSMenu, urls: [URL]) {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self; item.representedObject = urls
        menu.addItem(item)
    }
    @objc private func openTerminal(_ sender: NSMenuItem) {
        guard let path = (sender.representedObject as? [URL])?.first?.path else { return }
        if let url = TerminalRequest.url(path: path) { NSWorkspace.shared.open(url) }
    }
    @objc private func copyPaths(_ sender: NSMenuItem) {
        guard let urls = sender.representedObject as? [URL], !urls.isEmpty else { return }
        guard let text = try? PathResolver.copiedPaths(urls) else { NSSound.beep(); return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}
