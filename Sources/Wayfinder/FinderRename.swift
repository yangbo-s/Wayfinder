import AppKit
import ApplicationServices
import WayfinderCore

/// Revealing a file is asynchronous. Only request rename once Finder has selected
/// the exact new folder, and abandon the request if the user starts another task.
enum FinderRename {
    static func revealAndRename(_ folder: URL, completion: @escaping (String?) -> Void) {
        let input = InputSnapshot()
        NSWorkspace.shared.activateFileViewerSelecting([folder])
        guard AccessibilityPermission.isGranted() else {
            completion("自动进入重命名需要辅助功能权限；也可以在 Finder 中按 Return 重命名。")
            return
        }
        waitForSelection(folder, input: input, remaining: 20, reason: "Finder 尚未就绪", completion: completion)
    }

    private static func waitForSelection(_ folder: URL, input: InputSnapshot, remaining: Int, reason: String,
                                         completion: @escaping (String?) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            guard input == InputSnapshot() else {
                completion("已保留文件夹；在 Finder 中按 Return 可重命名。")
                return
            }
            guard remaining > 0 else {
                completion("\(reason)；选中新文件夹后按 Return 即可重命名。")
                return
            }
            let finder = NSWorkspace.shared.frontmostApplication
            let active = finder?.bundleIdentifier == "com.apple.finder"
            let focused = active && CutController.finderFileAreaIsFocused()
            let selected = focused && selectionMatches(folder)
            guard active, focused, selected, let finder else {
                let reason = !active ? "Finder 未处于前台" : !focused ? "Finder 焦点未在文件区域" : "Finder 尚未选中新文件夹"
                waitForSelection(folder, input: input, remaining: remaining - 1, reason: reason, completion: completion)
                return
            }
            let application = AXUIElementCreateApplication(finder.processIdentifier)
            AXUIElementSetMessagingTimeout(application, 0.1)
            let command = renameCommand(in: application)
            guard input == InputSnapshot(), NSEvent.modifierFlags.intersection([.command, .control, .option, .shift]).isEmpty else {
                completion("在 Finder 中按 Return 可重命名新文件夹。")
                return
            }
            guard let command, AXUIElementPerformAction(command, kAXPressAction as CFString) == .success else {
                completion("Finder 的重命名菜单暂不可用；选中新文件夹后按 Return 即可。")
                return
            }
            completion(nil)
        }
    }

    private static func selectionMatches(_ folder: URL) -> Bool {
        guard let finder = NSWorkspace.shared.frontmostApplication else { return false }
        let app = AXUIElementCreateApplication(finder.processIdentifier)
        AXUIElementSetMessagingTimeout(app, 0.1)
        guard let focused = element(attribute(app, kAXFocusedUIElementAttribute)),
              let selected = selectedItems(in: focused, depth: 3), selected.count == 1,
              let url = fileURL(in: selected[0], depth: 4) else { return false }
        return (try? PathResolver.actualURL(url.path).path) == (try? PathResolver.actualURL(folder.path).path)
    }

    private static func attribute(_ element: AXUIElement, _ name: String) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else { return nil }
        return value
    }
    private static func element(_ value: CFTypeRef?) -> AXUIElement? {
        guard let value, CFGetTypeID(value) == AXUIElementGetTypeID() else { return nil }
        return (value as! AXUIElement)
    }
    private static func selectedItems(in root: AXUIElement, depth: Int) -> [AXUIElement]? {
        for name in [kAXSelectedRowsAttribute, kAXSelectedChildrenAttribute] {
            if let items = attribute(root, name) as? [AXUIElement], !items.isEmpty { return items }
        }
        guard depth > 0 else { return nil }
        for child in attribute(root, kAXChildrenAttribute) as? [AXUIElement] ?? [] {
            if let items = selectedItems(in: child, depth: depth - 1) { return items }
        }
        return nil
    }
    private static func fileURL(in root: AXUIElement, depth: Int) -> URL? {
        let value = attribute(root, kAXURLAttribute)
        if let url = value as? URL, url.isFileURL { return url }
        if let text = value as? String, let url = URL(string: text), url.isFileURL { return url }
        guard depth > 0 else { return nil }
        for child in attribute(root, kAXChildrenAttribute) as? [AXUIElement] ?? [] {
            if let url = fileURL(in: child, depth: depth - 1) { return url }
        }
        return nil
    }

    private static func renameCommand(in application: AXUIElement) -> AXUIElement? {
        guard let bar = element(attribute(application, kAXMenuBarAttribute)) else { return nil }
        // Match the native command by its title, never a menu position. These
        // are Finder's English, Simplified and Traditional Chinese labels.
        let titles: Set<String> = ["Rename", "重命名", "重新命名"]
        var matches: [AXUIElement] = []
        for category in attribute(bar, kAXChildrenAttribute) as? [AXUIElement] ?? [] {
            for menu in attribute(category, kAXChildrenAttribute) as? [AXUIElement] ?? [] {
                for item in attribute(menu, kAXChildrenAttribute) as? [AXUIElement] ?? [] {
                    if let title = attribute(item, kAXTitleAttribute) as? String, titles.contains(title),
                       attribute(item, kAXEnabledAttribute) as? Bool == true {
                        matches.append(item)
                    }
                }
            }
        }
        return matches.count == 1 ? matches[0] : nil
    }

    private struct InputSnapshot: Equatable {
        let keys = CGEventSource.counterForEventType(.combinedSessionState, eventType: .keyDown)
        let leftClicks = CGEventSource.counterForEventType(.combinedSessionState, eventType: .leftMouseDown)
        let rightClicks = CGEventSource.counterForEventType(.combinedSessionState, eventType: .rightMouseDown)
    }
}
