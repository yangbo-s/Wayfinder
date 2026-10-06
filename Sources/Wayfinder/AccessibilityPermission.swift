import AppKit
import ApplicationServices

/// The AX server is the authority. A successful protected query can confirm
/// a grant when the process-level trust preflight has not refreshed yet.
enum AccessibilityPermission {
    static func isGranted() -> Bool {
        if AXIsProcessTrusted() { return true }
        guard let finder = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.finder").first else {
            return false
        }
        let application = AXUIElementCreateApplication(finder.processIdentifier)
        AXUIElementSetMessagingTimeout(application, 0.1)
        var role: CFTypeRef?
        return AXUIElementCopyAttributeValue(application, kAXRoleAttribute as CFString, &role) == .success
            && (role as? String) == kAXApplicationRole
    }
}
