import AppKit
import ApplicationServices
import WayfinderCore

final class CutController {
    var enabled = true { didSet { if !enabled { cancel() } } }
    var statusChanged: ((String) -> Void)?
    var didPrepareCut: (() -> Void)?
    private var tap: CFMachPort?
    private var source: CFRunLoopSource?
    private var poll: Timer?
    private var session = CutSession()
    private var deadline = Date.distantPast
    private var remappedKey: Int64?
    var isRunning: Bool { tap.map { CGEvent.tapIsEnabled(tap: $0) } ?? false }

    func start() {
        guard tap == nil, AXIsProcessTrusted() else { return }
        let mask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)
        guard let port = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap,
            options: .defaultTap, eventsOfInterest: CGEventMask(mask), callback: { _, type, event, context in
                guard let context else { return Unmanaged.passUnretained(event) }
                return Unmanaged<CutController>.fromOpaque(context).takeUnretainedValue().handle(type, event)
            }, userInfo: Unmanaged.passUnretained(self).toOpaque()) else {
            statusChanged?("快捷键监听未启动，请检查辅助功能权限后重新打开应用。")
            return
        }
        tap = port
        source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, port, 0)
        if let source { CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes) }
        CGEvent.tapEnable(tap: port, enable: true)
        poll = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in self?.observeClipboard() }
    }

    func stop() {
        poll?.invalidate(); poll = nil
        if let tap { CGEvent.tapEnable(tap: tap, enable: false); CFMachPortInvalidate(tap) }
        if let source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
        tap = nil; source = nil; remappedKey = nil; cancel()
    }

    private func cancel() { session.cancel(); statusChanged?("") }
    private func observeClipboard() {
        guard session.state != .idle else { return }
        let board = NSPasteboard.general
        let count = (board.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) ?? []).count
        let previous = session.state
        session.observe(changeCount: board.changeCount, fileCount: count)
        if case .awaitingCopy = previous, case .ready = session.state { didPrepareCut?() }
        if case .awaitingCopy = session.state, Date() > deadline { cancel() }
        switch session.state {
        case .ready(_, let files): statusChanged?("已剪切 \(files) 项 · 到目标文件夹按 ⌘V")
        case .idle: statusChanged?("")
        default: break
        }
    }

    private func handle(_ type: CGEventType, _ event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            // Losing events invalidates our clipboard ownership assumptions.
            cancel()
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
            return Unmanaged.passUnretained(event)
        }
        let key = event.getIntegerValueField(.keyboardEventKeycode)
        if type == .keyUp, key == remappedKey {
            event.setIntegerValueField(.keyboardEventKeycode, value: 8)
            remappedKey = nil
            return Unmanaged.passUnretained(event)
        }
        guard type == .keyDown else { return Unmanaged.passUnretained(event) }
        let modifiers = event.flags.intersection([.maskCommand, .maskControl, .maskAlternate, .maskShift])
        // Copy anywhere or Escape cancels pending cut even outside Finder.
        if (key == 8 && modifiers == .maskCommand) || key == 53 { cancel() }
        guard enabled, modifiers == .maskCommand, key == 7 || key == 9,
              NSWorkspace.shared.frontmostApplication?.bundleIdentifier == "com.apple.finder",
              Self.finderFileAreaIsFocused() else { return Unmanaged.passUnretained(event) }
        if key == 7 {
            if event.getIntegerValueField(.keyboardEventAutorepeat) != 0 { return nil }
            session.begin(changeCount: NSPasteboard.general.changeCount)
            deadline = Date().addingTimeInterval(1)
            remappedKey = key
            event.setIntegerValueField(.keyboardEventKeycode, value: 8) // X → Finder Copy
            return Unmanaged.passUnretained(event)
        }
        observeClipboard()
        if case .awaitingCopy = session.state {
            statusChanged?("正在读取 Finder 剪贴板，请稍后再按 ⌘V。")
            return nil
        }
        if session.consumeMove(changeCount: NSPasteboard.general.changeCount) {
            event.flags.insert(.maskAlternate) // Finder owns move, conflicts and Undo.
            statusChanged?("")
        }
        return Unmanaged.passUnretained(event)
    }

    private static func finderFileAreaIsFocused() -> Bool {
        guard let finder = NSWorkspace.shared.frontmostApplication else { return false }
        let app = AXUIElementCreateApplication(finder.processIdentifier)
        AXUIElementSetMessagingTimeout(app, 0.03)
        var focused: CFTypeRef?
        guard AXUIElementCopyAttributeValue(app, kAXFocusedUIElementAttribute as CFString, &focused) == .success,
              let focused, CFGetTypeID(focused) == AXUIElementGetTypeID() else { return false }
        var element = focused as! AXUIElement
        var isFileArea = false
        for _ in 0..<8 {
            var value: CFTypeRef?
            AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &value)
            let role = value as? String ?? ""
            if ["AXTextField", "AXTextArea", "AXComboBox", "AXSearchField"].contains(role) { return false }
            if ["AXOutline", "AXList", "AXBrowser", "AXScrollArea"].contains(role) { isFileArea = true }
            value = nil
            AXUIElementCopyAttributeValue(element, kAXSubroleAttribute as CFString, &value)
            if ["AXDialog", "AXSystemDialog"].contains(value as? String ?? "") { return false }
            value = nil
            guard AXUIElementCopyAttributeValue(element, kAXParentAttribute as CFString, &value) == .success,
                  let parent = value, CFGetTypeID(parent) == AXUIElementGetTypeID() else { break }
            element = parent as! AXUIElement
        }
        return isFileArea
    }
}
