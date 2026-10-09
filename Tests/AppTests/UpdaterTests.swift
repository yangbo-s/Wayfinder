import AppKit
import Foundation
import WayfinderCore

@main enum UpdaterTests {
    static func main() {
        let identifier = Bundle.main.bundleIdentifier!
        precondition(identifier == "local.wayfinder.tests.updater")
        UserDefaults.standard.removePersistentDomain(forName: identifier)
        defer { UserDefaults.standard.removePersistentDomain(forName: identifier) }
        _ = NSApplication.shared
        let updater = AppUpdater()
        precondition(!updater.canCheckForUpdates && !updater.automaticallyChecksForUpdates
                     && !updater.automaticallyInstallsUpdates)
        updater.checkForUpdates()
        precondition(!updater.canCheckForUpdates)
        print("PASS updater defaults are opt-in and cannot check before starting")

        updater.start()
        precondition(updater.startupError == nil && updater.canCheckForUpdates)
        updater.start()
        precondition(updater.startupError == nil && updater.canCheckForUpdates)
        print("PASS real Sparkle starts with signed-feed configuration and start is idempotent")

        precondition(!updater.allowsAutomaticUpdates)
        updater.setAutomaticallyInstalls(true)
        precondition(!updater.automaticallyInstallsUpdates)
        updater.setAutomaticallyChecks(true)
        precondition(updater.automaticallyChecksForUpdates && updater.allowsAutomaticUpdates)
        updater.setAutomaticallyInstalls(true)
        precondition(updater.automaticallyInstallsUpdates)
        print("PASS automatic installation requires automatic checking")

        updater.setAutomaticallyChecks(false)
        precondition(!updater.allowsAutomaticUpdates)
        updater.setAutomaticallyChecks(true)
        precondition(updater.automaticallyInstallsUpdates)
        print("PASS disabling checks suspends installation without erasing the saved choice")

        let reopened = AppUpdater()
        precondition(reopened.automaticallyChecksForUpdates && reopened.automaticallyInstallsUpdates)
        precondition(UserDefaults.standard.bool(forKey: "SUEnableAutomaticChecks")
                     && UserDefaults.standard.bool(forKey: "SUAutomaticallyUpdate"))
        updater.setAutomaticallyChecks(false)
        print("PASS real Sparkle preferences persist across controller recreation")

        let gate = updater.relaunchGate
        var resumes = 0
        precondition(!gate.postpone { resumes += 1 })
        precondition(resumes == 0)
        gate.isBusy = true
        precondition(gate.postpone { resumes += 1 })
        precondition(resumes == 0)
        gate.isBusy = false
        gate.isBusy = false
        precondition(resumes == 1)
        print("PASS updater relaunch waits for a file operation and resumes exactly once")
        print("6 updater integration tests, 0 failures")
    }
}
