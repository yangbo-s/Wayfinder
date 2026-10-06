import AudioToolbox
import Foundation
import WayfinderCore

protocol CutSoundPlaying {
    func play(_ choice: CutSoundChoice) throws
}

final class CutSoundPlayer: CutSoundPlaying {
    private let directory: URL?
    private var sounds: [CutSoundChoice: SystemSoundID] = [:]

    init(directory: URL? = Bundle.main.resourceURL?.appendingPathComponent("CutSounds", isDirectory: true)) {
        self.directory = directory
    }

    deinit {
        for sound in sounds.values { AudioServicesDisposeSystemSoundID(sound) }
    }

    func play(_ choice: CutSoundChoice) throws {
        AudioServicesPlaySystemSoundWithCompletion(try load(choice), nil)
    }

    @discardableResult
    func load(_ choice: CutSoundChoice) throws -> SystemSoundID {
        if let sound = sounds[choice] { return sound }
        guard let url = directory?.appendingPathComponent(choice.filename),
              FileManager.default.isReadableFile(atPath: url.path) else {
            throw SoundError.missing(choice.name)
        }
        var sound: SystemSoundID = 0
        let status = AudioServicesCreateSystemSoundID(url as CFURL, &sound)
        guard status == noErr else { throw SoundError.unreadable(choice.name, status) }
        // IsUISound defaults to 1: respect the system effects volume and UI sounds switch.
        sounds[choice] = sound
        return sound
    }

    private enum SoundError: LocalizedError {
        case missing(String), unreadable(String, OSStatus)
        var errorDescription: String? {
            switch self {
            case .missing(let name): return "找不到“\(name)”音效，请重新安装完整的 Wayfinder App。"
            case .unreadable(let name, let status): return "无法读取“\(name)”音效（\(status)），请重新安装 Wayfinder。"
            }
        }
    }
}
