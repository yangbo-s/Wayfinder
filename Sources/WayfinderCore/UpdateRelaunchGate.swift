/// Keeps a requested updater relaunch behind an in-progress file operation.
public final class UpdateRelaunchGate {
    private var completion: (() -> Void)?
    public var isBusy = false {
        didSet {
            guard !isBusy, let resume = completion else { return }
            completion = nil
            resume()
        }
    }
    public init() {}
    public func postpone(_ resume: @escaping () -> Void) -> Bool {
        guard isBusy else { return false }
        completion = resume
        return true
    }
}
