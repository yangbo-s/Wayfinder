import Foundation

/// Only the native Finder performs file operations. This state never owns files.
public struct CutSession {
    public enum State: Equatable { case idle, awaitingCopy(Int), ready(Int, Int) }
    public private(set) var state: State = .idle
    public init() {}
    public mutating func begin(changeCount: Int) { state = .awaitingCopy(changeCount) }
    public mutating func observe(changeCount: Int, fileCount: Int) {
        switch state {
        case .awaitingCopy(let original) where original != changeCount:
            state = fileCount > 0 ? .ready(changeCount, fileCount) : .idle
        case .ready(let recorded, _) where recorded != changeCount:
            state = .idle
        default: break
        }
    }
    public mutating func consumeMove(changeCount: Int) -> Bool {
        guard case .ready(let recorded, _) = state, recorded == changeCount else {
            cancel(); return false
        }
        cancel(); return true
    }
    public mutating func cancel() { state = .idle }
}
