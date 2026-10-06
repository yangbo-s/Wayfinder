import AppKit
import WayfinderCore

final class TerminalLauncher {
    static func installed(_ choice: TerminalChoice) -> Bool {
        guard let id = choice.bundleID else { return true }
        return NSWorkspace.shared.urlForApplication(withBundleIdentifier: id) != nil
    }

    func open(path: String, choice: TerminalChoice, customApp: String, arguments: String) throws {
        let directory = try PathResolver.directory(for: path).path
        guard Self.installed(choice) else {
            throw NSError(domain: "Wayfinder", code: 2, userInfo: [NSLocalizedDescriptionKey: "未安装 \(choice.name)。请安装它或在设置中选择其他终端。"])
        }
        let cd = Escaping.appleScript("cd -- " + Escaping.shell(directory))
        switch choice {
        case .terminal:
            _ = try AppleScriptRunner.run("""
            tell application id "com.apple.Terminal"
                do script \(cd)
                activate
            end tell
            """)
        case .iterm:
            _ = try AppleScriptRunner.run("""
            tell application id "com.googlecode.iterm2"
                set newWindow to (create window with default profile)
                tell current session of newWindow to write text \(cd)
                activate
            end tell
            """)
        case .ghostty:
            _ = try AppleScriptRunner.run("""
            tell application id "com.mitchellh.ghostty"
                set config to new surface configuration
                set initial working directory of config to \(Escaping.appleScript(directory))
                new window with configuration config
                activate
            end tell
            """)
        case .warp:
            var parts = URLComponents()
            parts.scheme = "warp"; parts.host = "action"; parts.path = "/new_window"
            parts.queryItems = [URLQueryItem(name: "path", value: directory)]
            guard let url = parts.url, NSWorkspace.shared.open(url) else {
                throw NSError(domain: "Wayfinder", code: 3, userInfo: [NSLocalizedDescriptionKey: "Warp 未接受打开请求，请检查安装及 URI 支持。"])
            }
        case .custom:
            guard let bundle = Bundle(path: customApp), bundle.executableURL != nil else {
                throw NSError(domain: "Wayfinder", code: 4, userInfo: [NSLocalizedDescriptionKey: "请先选择有效的终端 .app。"])
            }
            let args = try Escaping.customArguments(arguments, path: directory)
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            process.arguments = ["-na", customApp, "--args"] + args
            try process.run()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else {
                throw NSError(domain: "Wayfinder", code: 5, userInfo: [NSLocalizedDescriptionKey: "自定义终端启动失败。请检查 App 与启动参数。"])
            }
        }
    }
}
