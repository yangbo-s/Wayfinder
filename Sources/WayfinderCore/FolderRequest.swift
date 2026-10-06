import Foundation

public struct FolderRequest: Codable {
    public enum Mode: String, Codable { case empty, selection }
    public let mode: Mode
    public let directory: String
    public let items: [String]
    public let createdAt: Date

    public init(mode: Mode, directory: String, items: [String] = [], createdAt: Date = Date()) {
        self.mode = mode; self.directory = directory; self.items = items; self.createdAt = createdAt
    }
    public func validate(at now: Date = Date()) throws {
        let age = now.timeIntervalSince(createdAt)
        guard (-5...300).contains(age), Self.validPath(directory), items.allSatisfy(Self.validPath),
              mode == .empty ? items.isEmpty : !items.isEmpty else { throw FolderError.invalidRequest }
    }
    private static func validPath(_ path: String) -> Bool { path.hasPrefix("/") && !path.contains("\0") }
    public static func url(token: UUID) -> URL {
        URL(string: "wayfinder://folder?token=\(token.uuidString)")!
    }
    public static func token(from url: URL) throws -> UUID {
        guard let parts = URLComponents(url: url, resolvingAgainstBaseURL: false),
              parts.scheme == "wayfinder", parts.host == "folder", parts.user == nil, parts.password == nil,
              parts.port == nil, parts.path.isEmpty, parts.fragment == nil,
              let items = parts.queryItems, items.count == 1, items[0].name == "token",
              let value = items[0].value, let token = UUID(uuidString: value) else { throw FolderError.invalidRequest }
        return token
    }
    public static func pasteboardName(_ token: UUID) -> String { "local.wayfinder.folder.\(token.uuidString)" }
    public static let pasteboardType = "local.wayfinder.folder-request"
}

public enum FolderError: LocalizedError {
    case invalidRequest, invalidName, invalidDirectory, invalidSelection, nameExists, changedItem
    case recoveryRequired(String)
    public var errorDescription: String? {
        switch self {
        case .invalidRequest: return "新建文件夹请求已失效。请从 Finder 菜单重试。"
        case .invalidName: return "请填写文件夹名称，不能使用 /、:、空名称、. 或 ..。"
        case .invalidDirectory: return "当前位置没有可用的实际目录。请打开普通文件夹后重试。"
        case .invalidSelection: return "所选项目必须存在，并位于同一个文件夹。原文件未改动。"
        case .nameExists: return "该名称已存在，请换一个名称。不会覆盖已有项目。"
        case .changedItem: return "文件位置或内容身份已变化，无法安全撤销。现有文件未被覆盖。"
        case .recoveryRequired(let path): return "操作未完全完成，部分项目保留在：\(path)。请在 Finder 中检查；没有覆盖或删除文件。"
        }
    }
}
