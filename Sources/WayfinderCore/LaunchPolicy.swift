import Foundation

public enum LaunchAction: Equatable {
    case showSettings, stayInBackground
}

public enum LaunchPolicy {
    // Keep legacy launch history as an input so upgrades are regression-tested;
    // it must never turn a normal app launch into a terminal command.
    public static func initial(hasLaunchedBefore: Bool, isLoginLaunch: Bool,
                               arguments: [String], handledExternalAction: Bool) -> LaunchAction {
        if handledExternalAction || isLoginLaunch || arguments.contains("--background") { return .stayInBackground }
        return .showSettings
    }
    public static func reopen() -> LaunchAction { .showSettings }
}
