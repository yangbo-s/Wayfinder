import AppKit
import WayfinderCore

enum FolderActions {
    static func receive(_ url: URL) throws -> FolderRequest {
        let token = try FolderRequest.token(from: url)
        let board = NSPasteboard(name: .init(FolderRequest.pasteboardName(token)))
        defer { board.releaseGlobally() }
        guard let data = board.data(forType: .init(FolderRequest.pasteboardType)) else { throw FolderError.invalidRequest }
        let request = try JSONDecoder().decode(FolderRequest.self, from: data)
        try request.validate()
        return request
    }
    static func askName(for request: FolderRequest, suggested: String) -> String? {
        let alert = NSAlert()
        alert.messageText = request.mode == .empty ? "新建空文件夹" : "将 \(request.items.count) 个所选项目放入新文件夹"
        alert.informativeText = "创建位置：\(request.directory)"
        alert.icon = NSImage(systemSymbolName: "folder.badge.plus", accessibilityDescription: nil)
        alert.addButton(withTitle: "新建")
        alert.addButton(withTitle: "取消")
        let field = NSTextField(string: suggested)
        field.frame = NSRect(x: 0, y: 0, width: 340, height: 24)
        field.setAccessibilityLabel("新文件夹名称")
        alert.accessoryView = field
        alert.window.initialFirstResponder = field
        NSApp.activate(ignoringOtherApps: true)
        guard alert.runModal() == .alertFirstButtonReturn else { return nil }
        return field.stringValue
    }
}
