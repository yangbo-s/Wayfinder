import Foundation
#if !STANDALONE_TESTS
import XCTest
#endif
@testable import WayfinderCore

final class CoreTests: XCTestCase {
    func testCutMovesOnlyAfterFreshFileCopy() {
        var cut = CutSession(); cut.begin(changeCount: 10)
        cut.observe(changeCount: 10, fileCount: 3)
        XCTAssertEqual(cut.state, .awaitingCopy(10))
        cut.observe(changeCount: 11, fileCount: 3)
        XCTAssertTrue(cut.consumeMove(changeCount: 11))
        XCTAssertFalse(cut.consumeMove(changeCount: 11))
    }
    func testTextClipboardCannotBecomePendingMove() {
        var cut = CutSession(); cut.begin(changeCount: 2)
        cut.observe(changeCount: 3, fileCount: 0)
        XCTAssertEqual(cut.state, .idle)
        XCTAssertFalse(cut.consumeMove(changeCount: 3))
    }
    func testReplacingClipboardCancelsMove() {
        var cut = CutSession(); cut.begin(changeCount: 2)
        cut.observe(changeCount: 3, fileCount: 1)
        cut.observe(changeCount: 4, fileCount: 1)
        XCTAssertEqual(cut.state, .idle)
        XCTAssertFalse(cut.consumeMove(changeCount: 4))
    }
    func testPasteChecksClipboardEvenBeforePoll() {
        var cut = CutSession(); cut.begin(changeCount: 1)
        cut.observe(changeCount: 2, fileCount: 1)
        XCTAssertFalse(cut.consumeMove(changeCount: 3))
    }
    func testEscapeAndDisabledCancel() {
        var cut = CutSession(); cut.begin(changeCount: 1)
        cut.observe(changeCount: 2, fileCount: 1); cut.cancel()
        XCTAssertFalse(cut.consumeMove(changeCount: 2))
    }
    func testRepeatedCutReplacesOriginalSession() {
        var cut = CutSession(); cut.begin(changeCount: 1)
        cut.observe(changeCount: 2, fileCount: 1)
        cut.begin(changeCount: 2)
        XCTAssertFalse(cut.consumeMove(changeCount: 2))
    }
    func testUncutClipboardRemainsNormalPaste() {
        var cut = CutSession()
        cut.observe(changeCount: 2, fileCount: 4)
        XCTAssertFalse(cut.consumeMove(changeCount: 2))
    }
    func testPathRejectsRelativeAndNull() {
        for path in ["", "~/Desktop", "relative", "/tmp/a\0b"] {
            XCTAssertThrowsError(try PathResolver.actualURL(path))
        }
    }
    func testRealPathResolvesSymlinkAndFileParent() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let real = root.appendingPathComponent("中文 folder ' $()")
        try FileManager.default.createDirectory(at: real, withIntermediateDirectories: true)
        let link = root.appendingPathComponent("shortcut")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: real)
        XCTAssertEqual(try PathResolver.directory(for: link.path), real.resolvingSymlinksInPath())
        let file = real.appendingPathComponent("hello.txt")
        try Data("hello".utf8).write(to: file)
        XCTAssertEqual(try PathResolver.directory(for: file.path), real.resolvingSymlinksInPath())
        XCTAssertEqual(try PathResolver.copiedPaths([link, file]), real.resolvingSymlinksInPath().path + "\n" + file.resolvingSymlinksInPath().path)
    }
    func testMissingDirectoryIsExplicitError() {
        XCTAssertThrowsError(try PathResolver.directory(for: "/tmp/" + UUID().uuidString))
    }
    func testCopyRejectsEmptyAndRemoteURLs() {
        XCTAssertThrowsError(try PathResolver.copiedPaths([]))
        XCTAssertThrowsError(try PathResolver.copiedPaths([URL(string: "https://example.com")!]))
    }
    func testURLRoundTripPreservesSpecialCharacters() throws {
        let path = "/tmp/中文 'a' # & ? + % \\ \nname"
        let url = try XCTUnwrap(TerminalRequest.url(path: path))
        XCTAssertEqual(try TerminalRequest.path(from: url), path)
    }
    func testURLRejectsOtherActionsAndExtraParameters() {
        for value in ["wayfinder://delete?path=/tmp", "https://terminal?path=/tmp", "wayfinder://terminal?path=relative", "wayfinder://terminal?path=/tmp&command=rm", "wayfinder://terminal?path=/tmp&path=/", "wayfinder://terminal/extra?path=/tmp"] {
            XCTAssertThrowsError(try TerminalRequest.path(from: URL(string: value)!))
        }
    }
    func testCustomArgumentsStaySeparateAndLiteral() throws {
        let path = "/tmp/中文 ' $(touch nope)"
        XCTAssertEqual(try Escaping.customArguments("[\"--working-directory\",\"{path}\"]", path: path), ["--working-directory", path])
        for invalid in ["--directory={path}", "{}", "[3]", "[null]"] {
            XCTAssertThrowsError(try Escaping.customArguments(invalid, path: path))
        }
    }
    func testShellQuoteSurvivesShellWithoutExecutingPath() throws {
        let text = "/tmp/中文 ' \" $HOME $(printf INJECTED) `printf BAD`\nend"
        let process = Process(); let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", "printf '%s' " + Escaping.shell(text)]
        process.standardOutput = pipe
        try process.run()
        let output = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        XCTAssertEqual(process.terminationStatus, 0)
        XCTAssertEqual(String(decoding: output, as: UTF8.self), text)
    }
    func testAppleScriptEscapesEachLayer() {
        XCTAssertEqual(Escaping.appleScript("a\"b\\c\nd\re"), "\"a\\\"b\\\\c\\nd\\re\"")
    }
    func testTerminalDefaultAndKnownIdentifiers() {
        XCTAssertEqual(TerminalChoice.terminal.bundleID, "com.apple.Terminal")
        XCTAssertEqual(TerminalChoice.ghostty.bundleID, "com.mitchellh.ghostty")
        XCTAssertNil(TerminalChoice.custom.bundleID)
    }
}
