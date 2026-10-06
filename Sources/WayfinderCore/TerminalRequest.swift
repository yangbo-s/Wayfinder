import Foundation

public enum TerminalChoice: String, CaseIterable, Identifiable {
    case terminal, ghostty, iterm, warp, custom
    public var id: String { rawValue }
    public var name: String {
        switch self {
        case .terminal: return "Terminal"
        case .ghostty: return "Ghostty"
        case .iterm: return "iTerm2"
        case .warp: return "Warp"
        case .custom: return "自定义终端"
        }
    }
    public var bundleID: String? {
        switch self {
        case .terminal: return "com.apple.Terminal"
        case .ghostty: return "com.mitchellh.ghostty"
        case .iterm: return "com.googlecode.iterm2"
        case .warp: return "dev.warp.Warp-Stable"
        case .custom: return nil
        }
    }
}

public enum TerminalRequest {
    public static func url(path: String) -> URL? {
        var parts = URLComponents()
        parts.scheme = "wayfinder"; parts.host = "terminal"
        parts.queryItems = [URLQueryItem(name: "path", value: path)]
        return parts.url
    }
    public static func path(from url: URL) throws -> String {
        guard url.scheme == "wayfinder", url.host == "terminal",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.path.isEmpty, components.fragment == nil,
              let items = components.queryItems, items.count == 1,
              items[0].name == "path", let path = items[0].value else { throw WayfinderError.invalidPath }
        _ = try PathResolver.actualURL(path)
        return path
    }
}
