import AppKit
import WayfinderCore

enum AppleScriptRunner {
    static func run(_ source: String) throws -> NSAppleEventDescriptor {
        var error: NSDictionary?
        guard let script = NSAppleScript(source: "with timeout of 10 seconds\n\(source)\nend timeout") else {
            throw NSError(domain: "Wayfinder", code: 1, userInfo: [NSLocalizedDescriptionKey: "无法创建自动化脚本。"])
        }
        let result = script.executeAndReturnError(&error)
        if let error {
            let code = error[NSAppleScript.errorNumber] as? Int ?? -1
            let message = code == -1743
                ? "自动化权限被拒绝。请在系统设置 → 隐私与安全性 → 自动化中允许 Wayfinder 控制 Finder 或所选终端。"
                : (error[NSAppleScript.errorMessage] as? String ?? "自动化失败，请检查目标应用是否已安装。")
            throw NSError(domain: "Wayfinder.Automation", code: code, userInfo: [NSLocalizedDescriptionKey: message])
        }
        return result
    }
}

enum FinderLocation {
    static func currentDirectory() throws -> URL {
        let value = try AppleScriptRunner.run("""
        tell application id "com.apple.finder"
            if (count of windows) is 0 then return POSIX path of (desktop as alias)
            try
                return POSIX path of (target of front window as alias)
            on error
                return ""
            end try
        end tell
        """).stringValue ?? ""
        guard !value.isEmpty else { throw WayfinderError.noFinderFolder }
        return try PathResolver.directory(for: value)
    }
}
