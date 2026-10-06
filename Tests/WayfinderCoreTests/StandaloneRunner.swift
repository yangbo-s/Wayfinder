import Foundation
@main enum TestRunner {
    static func main() {
        let suite = CoreTests()
        let tests: [(String, () throws -> Void)] = [
            ("cut moves only after fresh file copy", suite.testCutMovesOnlyAfterFreshFileCopy),
            ("text clipboard cannot become move", suite.testTextClipboardCannotBecomePendingMove),
            ("clipboard replacement cancels move", suite.testReplacingClipboardCancelsMove),
            ("paste validates before poll", suite.testPasteChecksClipboardEvenBeforePoll),
            ("cancel and disabled", suite.testEscapeAndDisabledCancel),
            ("repeat cut invalidates original", suite.testRepeatedCutReplacesOriginalSession),
            ("normal copy stays copy", suite.testUncutClipboardRemainsNormalPaste),
            ("invalid paths", suite.testPathRejectsRelativeAndNull),
            ("symlink, Unicode, file parent, multi-copy", suite.testRealPathResolvesSymlinkAndFileParent),
            ("missing directory", suite.testMissingDirectoryIsExplicitError),
            ("empty and remote copy", suite.testCopyRejectsEmptyAndRemoteURLs),
            ("URL special character roundtrip", suite.testURLRoundTripPreservesSpecialCharacters),
            ("URL rejects unknown actions and duplicate fields", suite.testURLRejectsOtherActionsAndExtraParameters),
            ("custom args remain literal", suite.testCustomArgumentsStaySeparateAndLiteral),
            ("actual zsh quoting without command substitution", suite.testShellQuoteSurvivesShellWithoutExecutingPath),
            ("AppleScript escaping", suite.testAppleScriptEscapesEachLayer),
            ("default terminal identifiers", suite.testTerminalDefaultAndKnownIdentifiers)
        ]
        for (name, test) in tests {
            let before = testFailures
            do { try test() } catch { fail(error.localizedDescription, file: #filePath, line: #line) }
            print("\(before == testFailures ? "PASS" : "FAIL") \(name)")
        }
        print("\(tests.count) tests, \(testFailures) failures")
        exit(testFailures == 0 ? 0 : 1)
    }
}
