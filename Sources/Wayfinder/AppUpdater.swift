import AppKit
import Combine
import Sparkle
import WayfinderCore

/// Sparkle owns preference persistence, scheduling, downloads and signature checks.
final class AppUpdater: NSObject, ObservableObject, SPUUpdaterDelegate, SPUStandardUserDriverDelegate {
    @Published private(set) var canCheckForUpdates = false
    @Published private(set) var automaticallyChecksForUpdates = false
    @Published private(set) var automaticallyInstallsUpdates = false
    @Published private(set) var allowsAutomaticUpdates = false
    @Published private(set) var lastCheckDate: Date?
    @Published private(set) var startupError: String?
    @Published private(set) var availableVersion: String?
    let relaunchGate = UpdateRelaunchGate()
    private var controller: SPUStandardUpdaterController!
    private var started = false

    override init() {
        super.init()
        controller = SPUStandardUpdaterController(startingUpdater: false, updaterDelegate: self, userDriverDelegate: self)
        let updater = controller.updater
        updater.publisher(for: \.canCheckForUpdates).assign(to: &$canCheckForUpdates)
        updater.publisher(for: \.automaticallyChecksForUpdates).assign(to: &$automaticallyChecksForUpdates)
        updater.publisher(for: \.automaticallyDownloadsUpdates).assign(to: &$automaticallyInstallsUpdates)
        updater.publisher(for: \.allowsAutomaticUpdates).assign(to: &$allowsAutomaticUpdates)
        updater.publisher(for: \.lastUpdateCheckDate).assign(to: &$lastCheckDate)
    }

    func start() {
        guard !started else { return }
        do {
            try controller.updater.start()
            started = true
            startupError = nil
        } catch {
            startupError = "更新服务无法启动：\(error.localizedDescription)"
        }
    }
    func checkForUpdates() {
        guard canCheckForUpdates else { return }
        controller.checkForUpdates(nil)
    }
    func setAutomaticallyChecks(_ enabled: Bool) {
        controller.updater.automaticallyChecksForUpdates = enabled
    }
    func setAutomaticallyInstalls(_ enabled: Bool) {
        guard allowsAutomaticUpdates else { return }
        controller.updater.automaticallyDownloadsUpdates = enabled
    }

    func updater(_ updater: SPUUpdater, shouldPostponeRelaunchForUpdate item: SUAppcastItem,
                 untilInvokingBlock installHandler: @escaping () -> Void) -> Bool {
        relaunchGate.postpone(installHandler)
    }

    // The standard driver keeps scheduled alerts behind other applications. The
    // settings page and menu entry also surface the pending version for this dockless app.
    var supportsGentleScheduledUpdateReminders: Bool { true }
    func standardUserDriverWillHandleShowingUpdate(_ handleShowingUpdate: Bool,
                                                  forUpdate update: SUAppcastItem, state: SPUUserUpdateState) {
        availableVersion = update.displayVersionString
    }
    func standardUserDriverDidReceiveUserAttention(forUpdate update: SUAppcastItem) {
        availableVersion = nil
    }
    func standardUserDriverWillFinishUpdateSession() { availableVersion = nil }
}
