import Foundation
import Darwin

public final class FolderCreation {
    struct Identity: Equatable {
        let volume: UInt64
        let file: UInt64
        init(_ attributes: [FileAttributeKey: Any]) {
            volume = (attributes[.systemNumber] as? NSNumber)?.uint64Value ?? 0
            file = (attributes[.systemFileNumber] as? NSNumber)?.uint64Value ?? 0
        }
    }
    struct Move { let source: URL; let destination: URL; let identity: Identity }
    public struct Result {
        public let folder: URL
        public var originalItems: [URL] { moves.map(\.source) }
        let folderIdentity: Identity
        let moves: [Move]
    }
    private let files: FileManager
    public init(files: FileManager = .default) { self.files = files }

    public static func validateName(_ name: String) throws {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              name != ".", name != "..", !name.contains("/"), !name.contains(":"), !name.contains("\0") else {
            throw FolderError.invalidName
        }
    }
    public func suggestedName(in directory: String) -> String {
        let parent = URL(fileURLWithPath: directory)
        var candidate = "未命名文件夹", suffix = 2
        while exists(parent.appendingPathComponent(candidate)) {
            candidate = "未命名文件夹 \(suffix)"; suffix += 1
        }
        return candidate
    }
    public func create(_ request: FolderRequest, name: String) throws -> Result {
        try request.validate()
        try Self.validateName(name)
        let parent = try PathResolver.actualURL(request.directory)
        guard (try? files.attributesOfItem(atPath: parent.path)[.type] as? FileAttributeType) == .typeDirectory else {
            throw FolderError.invalidDirectory
        }
        let folder = parent.appendingPathComponent(name, isDirectory: true)
        var paths = Set<String>()
        let moves: [Move] = try request.items.map { path in
            let original = URL(fileURLWithPath: path)
            let sourceParent = try PathResolver.actualURL(original.deletingLastPathComponent().path)
            // Resolve the parent, never the selected leaf: moving a symbolic link
            // must move the link itself, including a broken link.
            let source = sourceParent.appendingPathComponent(original.lastPathComponent)
            guard sourceParent.path == parent.path, source.path != parent.path, paths.insert(source.path).inserted,
                  let attributes = try? files.attributesOfItem(atPath: source.path) else { throw FolderError.invalidSelection }
            return Move(source: source, destination: folder.appendingPathComponent(source.lastPathComponent), identity: Identity(attributes))
        }
        // mkdir is exclusive; createDirectory may silently accept an existing folder.
        guard mkdir(folder.path, 0o777) == 0 else {
            if errno == EEXIST { throw FolderError.nameExists }
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno))
        }
        let folderIdentity = try identity(folder)
        do { try perform(moves, recoveryLocation: folder) }
        catch {
            // Never recursively remove the folder: another process may have added a file.
            if (try? identity(folder)) == folderIdentity { _ = rmdir(folder.path) }
            throw error
        }
        return Result(folder: folder, folderIdentity: folderIdentity, moves: moves)
    }
    public func undo(_ result: Result) throws {
        guard (try? identity(result.folder)) == result.folderIdentity else { throw FolderError.changedItem }
        let children = try files.contentsOfDirectory(atPath: result.folder.path)
        guard Set(children) == Set(result.moves.map { $0.destination.lastPathComponent }) else { throw FolderError.changedItem }
        let reversed = result.moves.reversed().map { Move(source: $0.destination, destination: $0.source, identity: $0.identity) }
        try perform(reversed, recoveryLocation: result.folder)
        guard rmdir(result.folder.path) == 0 else {
            // Restoring items succeeded. If a concurrent writer added content, preserve it.
            throw FolderError.recoveryRequired(result.folder.path)
        }
    }
    private func identity(_ url: URL) throws -> Identity { Identity(try files.attributesOfItem(atPath: url.path)) }
    private func exists(_ url: URL) -> Bool { (try? files.attributesOfItem(atPath: url.path)) != nil }
    private func verify(_ move: Move) throws {
        guard (try? identity(move.source)) == move.identity, !exists(move.destination) else { throw FolderError.changedItem }
    }
    private func perform(_ moves: [Move], recoveryLocation: URL) throws {
        // Preflight all sources before touching any; recheck immediately before each rename.
        for move in moves { try verify(move) }
        var completed: [Move] = []
        do {
            for move in moves {
                try verify(move)
                try files.moveItem(at: move.source, to: move.destination)
                completed.append(move)
            }
        } catch {
            var recovered = true
            for move in completed.reversed() {
                do {
                    let reverse = Move(source: move.destination, destination: move.source, identity: move.identity)
                    try verify(reverse)
                    try files.moveItem(at: reverse.source, to: reverse.destination)
                } catch { recovered = false }
            }
            if !recovered { throw FolderError.recoveryRequired(recoveryLocation.path) }
            throw error
        }
    }
}
