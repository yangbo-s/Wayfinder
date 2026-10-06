import AppKit
import WayfinderCore

enum FolderActions {
    static func receive(_ url: URL) throws -> FolderRequest {
        let token = try FolderRequest.token(from: url)
        let board = NSPasteboard(name: .init(FolderRequest.pasteboardName(token)))
        defer { board.releaseGlobally() }
        guard let data = board.data(forType: .init(FolderRequest.pasteboardType)) else { throw FolderError.invalidRequest }
        let request = try JSONDecoder().decode(FolderRequest.self, from: data)
        try request.validate()
        return request
    }
}
