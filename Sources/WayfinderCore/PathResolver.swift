import Foundation

public enum WayfinderError: LocalizedError {
    case invalidPath, missingPath(String), invalidArguments, noFinderFolder
    public var errorDescription: String? {
        switch self {
        case .invalidPath: return "需要有效的绝对文件路径。"
        case .missingPath(let path): return "位置不存在或无法访问：\(path)"
        case .invalidArguments: return "启动参数必须是 JSON 字符串数组，例如 [\"--working-directory={path}\"]。"
        case .noFinderFolder: return "当前位置没有实际文件夹。请在 Finder 中打开一个普通文件夹后重试。"
        }
    }
}

public enum PathResolver {
    public static func actualURL(_ path: String) throws -> URL {
        guard path.hasPrefix("/"), !path.contains("\0") else { throw WayfinderError.invalidPath }
        return URL(fileURLWithPath: path).standardizedFileURL.resolvingSymlinksInPath()
    }
    public static func directory(for path: String) throws -> URL {
        let url = try actualURL(path)
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            throw WayfinderError.missingPath(url.path)
        }
        let directory = isDirectory.boolValue ? url : url.deletingLastPathComponent()
        return URL(fileURLWithPath: directory.path, isDirectory: true)
    }
    public static func copiedPaths(_ urls: [URL]) throws -> String {
        guard !urls.isEmpty, urls.allSatisfy(\.isFileURL) else { throw WayfinderError.invalidPath }
        return try urls.map { try actualURL($0.path).path }.joined(separator: "\n")
    }
}

public enum Escaping {
    public static func shell(_ text: String) -> String { "'" + text.replacingOccurrences(of: "'", with: "'\\''") + "'" }
    public static func appleScript(_ text: String) -> String {
        "\"" + text.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\n", with: "\\n") + "\""
    }
    public static func customArguments(_ json: String, path: String) throws -> [String] {
        guard let data = json.data(using: .utf8),
              let args = try? JSONDecoder().decode([String].self, from: data),
              args.allSatisfy({ !$0.contains("\0") }) else { throw WayfinderError.invalidArguments }
        return args.map { $0.replacingOccurrences(of: "{path}", with: path) }
    }
}
