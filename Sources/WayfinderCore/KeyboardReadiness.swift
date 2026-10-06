public enum KeyboardReadiness: Equatable {
    case needsPermission, paused, listenerUnavailable, ready

    public init(accessGranted: Bool, featureEnabled: Bool, listenerRunning: Bool) {
        if !accessGranted { self = .needsPermission }
        else if !featureEnabled { self = .paused }
        else if !listenerRunning { self = .listenerUnavailable }
        else { self = .ready }
    }
    public var title: String {
        switch self {
        case .needsPermission: return "当前 App 的授权尚未生效"
        case .paused: return "Finder 剪切已暂停"
        case .listenerUnavailable: return "已授权 · 快捷键监听未启动"
        case .ready: return "Finder 剪切已就绪"
        }
    }
}
