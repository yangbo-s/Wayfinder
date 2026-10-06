import Foundation
#if !STANDALONE_TESTS
import XCTest
#endif
@testable import WayfinderCore

final class FolderTests: XCTestCase {
    private func fixture(_ body: (URL) throws -> Void) throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("Wayfinder-Folder-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try body(root)
    }
    private func write(_ url: URL, _ value: String = "original") throws { try Data(value.utf8).write(to: url) }
    private func read(_ url: URL) throws -> String { String(decoding: try Data(contentsOf: url), as: UTF8.self) }
    func testFolderRequestContract() throws {
        let token = UUID()
        XCTAssertEqual(try FolderRequest.token(from: FolderRequest.url(token: token)), token)
        for url in ["wayfinder://folder?token=bad", "wayfinder://folder?token=\(token)&extra=1", "wayfinder://folder/path?token=\(token)", "wayfinder://user@folder?token=\(token)"] {
            XCTAssertThrowsError(try FolderRequest.token(from: URL(string: url)!))
        }
        let request = FolderRequest(mode: .selection, directory: "/tmp/中文", items: (0..<2000).map { "/tmp/中文/文件 \($0)" })
        let decoded = try JSONDecoder().decode(FolderRequest.self, from: JSONEncoder().encode(request))
        try decoded.validate()
        XCTAssertEqual(decoded.items, request.items)
        XCTAssertThrowsError(try FolderRequest(mode: .empty, directory: "relative").validate())
        XCTAssertThrowsError(try FolderRequest(mode: .selection, directory: "/tmp").validate())
        XCTAssertThrowsError(try FolderRequest(mode: .empty, directory: "/tmp", items: ["/tmp/a"]).validate())
        XCTAssertThrowsError(try FolderRequest(mode: .empty, directory: "/tmp", createdAt: Date().addingTimeInterval(-301)).validate())
    }
    func testEmptyFolderAndUndo() throws {
        try fixture { root in
            let source = root.appendingPathComponent("untouched.txt"); try write(source)
            let action = FolderCreation()
            let result = try action.create(FolderRequest(mode: .empty, directory: root.path), name: "中文 folder ' &")
            XCTAssertTrue(try FileManager.default.contentsOfDirectory(atPath: result.folder.path).isEmpty)
            XCTAssertEqual(try read(source), "original")
            try action.undo(result)
            XCTAssertFalse(FileManager.default.fileExists(atPath: result.folder.path))
            XCTAssertEqual(try read(source), "original")
        }
    }
    func testSingleAndMultipleGroupingAndUndo() throws {
        for count in [1, 30] {
            try fixture { root in
                let sources = (0..<count).map { root.appendingPathComponent("文件 '\($0).txt") }
                for (i, url) in sources.enumerated() { try write(url, "value \(i)") }
                let action = FolderCreation()
                let result = try action.create(FolderRequest(mode: .selection, directory: root.path, items: sources.map(\.path)), name: "group")
                for (i, url) in sources.enumerated() {
                    XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
                    XCTAssertEqual(try read(result.folder.appendingPathComponent(url.lastPathComponent)), "value \(i)")
                }
                try action.undo(result)
                for (i, url) in sources.enumerated() { XCTAssertEqual(try read(url), "value \(i)") }
                XCTAssertFalse(FileManager.default.fileExists(atPath: result.folder.path))
            }
        }
    }
    func testRejectsNamesCollisionsAndInvalidSelections() throws {
        try fixture { root in
            let source = root.appendingPathComponent("original"); try write(source)
            let action = FolderCreation()
            let request = FolderRequest(mode: .selection, directory: root.path, items: [source.path])
            for name in ["", " ", ".", "..", "../escape", "a:b", "a\0b", "original"] {
                XCTAssertThrowsError(try action.create(request, name: name))
                XCTAssertEqual(try read(source), "original")
            }
            for paths in [[source.path, source.path], [source.path, root.appendingPathComponent("missing").path], [root.deletingLastPathComponent().path]] {
                XCTAssertThrowsError(try action.create(FolderRequest(mode: .selection, directory: root.path, items: paths), name: "group"))
                XCTAssertFalse(FileManager.default.fileExists(atPath: root.appendingPathComponent("group").path))
            }
            XCTAssertThrowsError(try action.create(FolderRequest(mode: .empty, directory: source.path), name: "group"))
            try FileManager.default.createDirectory(at: root.appendingPathComponent("existing"), withIntermediateDirectories: false)
            XCTAssertThrowsError(try action.create(request, name: "existing"))
        }
    }
    func testGroupingMovesSymlinkNotTarget() throws {
        try fixture { root in
            let target = root.appendingPathComponent("target"); try write(target, "never move me")
            let link = root.appendingPathComponent("link")
            let broken = root.appendingPathComponent("broken")
            try FileManager.default.createSymbolicLink(atPath: link.path, withDestinationPath: target.path)
            try FileManager.default.createSymbolicLink(atPath: broken.path, withDestinationPath: "/missing/Wayfinder-test")
            let action = FolderCreation()
            let result = try action.create(FolderRequest(mode: .selection, directory: root.path, items: [link.path, broken.path]), name: "links")
            XCTAssertEqual(try read(target), "never move me")
            XCTAssertEqual(try FileManager.default.destinationOfSymbolicLink(atPath: result.folder.appendingPathComponent("link").path), target.path)
            XCTAssertEqual(try FileManager.default.destinationOfSymbolicLink(atPath: result.folder.appendingPathComponent("broken").path), "/missing/Wayfinder-test")
            try action.undo(result)
            XCTAssertEqual(try read(target), "never move me")
            XCTAssertEqual(try FileManager.default.destinationOfSymbolicLink(atPath: link.path), target.path)
        }
    }
    func testFailureRollsBackCompletedMoves() throws {
        try fixture { root in
            let a = root.appendingPathComponent("a"), b = root.appendingPathComponent("b")
            try write(a, "a"); try write(b, "b")
            let files = FailingMoveManager(); files.failures = [2]
            let action = FolderCreation(files: files)
            XCTAssertThrowsError(try action.create(FolderRequest(mode: .selection, directory: root.path, items: [a.path, b.path]), name: "group"))
            XCTAssertEqual(try read(a), "a"); XCTAssertEqual(try read(b), "b")
            XCTAssertFalse(FileManager.default.fileExists(atPath: root.appendingPathComponent("group").path))
        }
    }
    func testFailedRollbackPreservesRecoverableFiles() throws {
        try fixture { root in
            let a = root.appendingPathComponent("a"), b = root.appendingPathComponent("b")
            try write(a, "a"); try write(b, "b")
            let files = FailingMoveManager(); files.failures = [2, 3]
            let action = FolderCreation(files: files)
            XCTAssertThrowsError(try action.create(FolderRequest(mode: .selection, directory: root.path, items: [a.path, b.path]), name: "group"))
            XCTAssertEqual(try read(root.appendingPathComponent("group/a")), "a")
            XCTAssertEqual(try read(b), "b")
        }
    }
    func testUndoProtectsNewOrReplacedItems() throws {
        try fixture { root in
            let a = root.appendingPathComponent("a"); try write(a)
            let action = FolderCreation()
            let result = try action.create(FolderRequest(mode: .selection, directory: root.path, items: [a.path]), name: "group")
            try write(a, "new source")
            XCTAssertThrowsError(try action.undo(result))
            XCTAssertEqual(try read(a), "new source")
            XCTAssertEqual(try read(result.folder.appendingPathComponent("a")), "original")
            try FileManager.default.removeItem(at: a)
            try write(result.folder.appendingPathComponent("new.txt"), "new content")
            XCTAssertThrowsError(try action.undo(result))
            XCTAssertEqual(try read(result.folder.appendingPathComponent("new.txt")), "new content")
            try FileManager.default.removeItem(at: result.folder.appendingPathComponent("new.txt"))
            let backup = root.appendingPathComponent("preserved-original")
            try FileManager.default.moveItem(at: result.folder.appendingPathComponent("a"), to: backup)
            try write(result.folder.appendingPathComponent("a"), "replacement")
            XCTAssertThrowsError(try action.undo(result))
            XCTAssertEqual(try read(result.folder.appendingPathComponent("a")), "replacement")
            XCTAssertEqual(try read(backup), "original")
        }
    }
}

private final class FailingMoveManager: FileManager, @unchecked Sendable {
    var failures = Set<Int>()
    private var calls = 0
    override func moveItem(at srcURL: URL, to dstURL: URL) throws {
        calls += 1
        if failures.contains(calls) { throw NSError(domain: NSPOSIXErrorDomain, code: 13) }
        try super.moveItem(at: srcURL, to: dstURL)
    }
}
