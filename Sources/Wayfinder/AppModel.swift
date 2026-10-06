import AppKit
import SwiftUI
import FinderSync
import ServiceManagement
import ApplicationServices
import WayfinderCore

final class AppModel: ObservableObject {
    @Published var terminal: TerminalChoice { didSet { defaults.set(terminal.rawValue, forKey: "terminal") } }
    @Published var customApp: String { didSet { defaults.set(customApp, forKey: "customApp") } }
    @Published var customArguments: String { didSet { defaults.set(customArguments, forKey: "customArguments") } }
    @Published var cutEnabled: Bool { didSet { defaults.set(cutEnabled, forKey: "cutEnabled"); cut.enabled = cutEnabled; refresh() } }
    @Published var playCutSound: Bool { didSet { defaults.set(playCutSound, forKey: "playCutSound") } }
    @Published var trusted = false
    @Published var extensionEnabled = false
    @Published var listenerRunning = false
    @Published var launchAtLogin = false
    @Published var cutStatus = ""
    @Published var notice: String?
    @Published var noticeIsError = false
    @Published var conflictingApp = false
    let cut = CutController()
    private let defaults = UserDefaults.standard
    private let launcher = TerminalLauncher()
    private var timer: Timer?
    var showSettings: (() -> Void)?
    var keyboardReadiness: KeyboardReadiness {
        KeyboardReadiness(accessGranted: trusted, featureEnabled: cutEnabled, listenerRunning: listenerRunning)
    }
    var accessibilityTitle: String {
        ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 27 ? "设备控制与数据访问" : "辅助功能"
    }

    init() {
        terminal = TerminalChoice(rawValue: defaults.string(forKey: "terminal") ?? "") ?? .terminal
        customApp = defaults.string(forKey: "customApp") ?? ""
        customArguments = defaults.string(forKey: "customArguments") ?? "[\"--working-directory={path}\"]"
        cutEnabled = defaults.object(forKey: "cutEnabled") as? Bool ?? true
        playCutSound = defaults.object(forKey: "playCutSound") as? Bool ?? true
        cut.enabled = cutEnabled
        cut.didPrepareCut = { [weak self] in
            guard self?.playCutSound == true else { return }
            NSSound(named: NSSound.Name("Tink"))?.play()
        }
        cut.statusChanged = { [weak self] value in if self?.cutStatus != value { self?.cutStatus = value } }
    }
    func start() {
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in self?.refresh() }
    }
    func refresh() {
        trusted = AccessibilityPermission.isGranted()
        extensionEnabled = FIFinderSyncController.isExtensionEnabled
        launchAtLogin = SMAppService.mainApp.status == .enabled
        conflictingApp = NSWorkspace.shared.runningApplications.contains { $0.localizedName == "Command X" }
        if trusted && cutEnabled { cut.start(accessGranted: trusted) } else { cut.stop() }
        listenerRunning = cut.isRunning
    }
    func retryListener() {
        cut.stop()
        refresh()
    }
    func requestAccessibility() {
        refresh()
        if trusted { retryListener(); return }
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        openSettings("x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
    }
    func restartApp() {
        let config = NSWorkspace.OpenConfiguration()
        config.createsNewApplicationInstance = true
        config.arguments = ["--settings"]
        NSWorkspace.shared.openApplication(at: Bundle.main.bundleURL, configuration: config) { _, error in
            DispatchQueue.main.async {
                if let error {
                    self.noticeIsError = true; self.notice = error.localizedDescription
                } else { NSApp.terminate(nil) }
            }
        }
    }
    func manageExtension() { FIFinderSyncController.showExtensionManagementInterface() }
    func openSettings(_ link: String) { if let url = URL(string: link) { NSWorkspace.shared.open(url) } }
    func setLogin(_ value: Bool) {
        perform {
            if value { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
            refresh()
            if SMAppService.mainApp.status == .requiresApproval {
                SMAppService.openSystemSettingsLoginItems()
            }
        }
    }
    func chooseCustomApp() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.applicationBundle]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.canChooseDirectories = false; panel.canChooseFiles = true; panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url { customApp = url.path }
    }
    func openTerminal(path: String? = nil) {
        perform {
            let directory = try path ?? FinderLocation.currentDirectory().path
            try launcher.open(path: directory, choice: terminal, customApp: customApp, arguments: customArguments)
            noticeIsError = false; notice = "已请求在 \(terminal.name) 打开：\(directory)"
        }
    }
    func copyCurrentPath() {
        perform {
            let text = try FinderLocation.currentDirectory().path
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
            noticeIsError = false; notice = "已复制：\(text)"
        }
    }
    func handleURL(_ url: URL) {
        if let message = FinderActionFailure.message(from: url) {
            noticeIsError = true; notice = message; showSettings?()
            return
        }
        perform { openTerminal(path: try TerminalRequest.path(from: url)) }
    }
    func perform(_ operation: () throws -> Void) {
        do { try operation() } catch {
            noticeIsError = true; notice = error.localizedDescription
            showSettings?()
        }
    }
}
