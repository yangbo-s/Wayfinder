import Foundation

public struct FinderActionContext {
    public let target: URL?
    public let selection: [URL]
    public init(target: URL?, selection: [URL]) {
        self.target = target?.isFileURL == true ? target : nil
        self.selection = selection.filter(\.isFileURL)
    }
    public var selectedOrTarget: [URL] {
        selection.isEmpty ? target.map { [$0] } ?? [] : selection
    }
    public var commonParent: URL? {
        let parents = Set(selectedOrTarget.map { $0.deletingLastPathComponent() })
        return parents.count == 1 ? parents.first : nil
    }
}

public enum FinderActionFailure {
    public static func message(from url: URL) -> String? {
        guard url.scheme == "wayfinder", url.host == "error",
              let parts = URLComponents(url: url, resolvingAgainstBaseURL: false),
              parts.path.isEmpty, parts.fragment == nil,
              let items = parts.queryItems, items.count == 1, items[0].name == "reason" else { return nil }
        switch items[0].value {
        case "missing-location": return "Finder 没有返回实际文件位置。请打开一个普通文件夹，再从右键菜单或工具栏重试。"
        case "clipboard-write-failed": return "无法写入系统剪贴板。请重试复制路径。"
        default: return nil
        }
    }
}
