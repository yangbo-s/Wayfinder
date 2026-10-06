import AppKit
import AudioToolbox
import Foundation
import WayfinderCore

private final class RecordingPlayer: CutSoundPlaying {
    var played: [CutSoundChoice] = []
    var fails = false
    func play(_ choice: CutSoundChoice) throws {
        if fails { throw NSError(domain: "SoundTest", code: 1) }
        played.append(choice)
    }
}

@main enum CutSoundTests {
    static func main() throws {
        let directory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
        let player = CutSoundPlayer(directory: directory)
        let choices = CutSoundChoice.allCases
        precondition(choices.count == 5)
        var ids = Set<SystemSoundID>()
        var files = Set<Data>()
        for choice in choices {
            let id = try player.load(choice)
            let cached = try player.load(choice)
            precondition(cached == id, "Sound should reuse its loaded resource")
            ids.insert(id)
            files.insert(try Data(contentsOf: directory.appendingPathComponent(choice.filename)))
            var sound = id, ui: UInt32 = 0, size = UInt32(MemoryLayout<UInt32>.size)
            precondition(AudioServicesGetProperty(kAudioServicesPropertyIsUISound,
                UInt32(MemoryLayout<SystemSoundID>.size), &sound, &size, &ui) == noErr && ui == 1)
        }
        precondition(ids.count == 5 && files.count == 5)
        print("PASS five distinct bundled sounds load, cache and honor system UI audio")

        let missing = CutSoundPlayer(directory: nil)
        do { _ = try missing.load(.crisp); fatalError("Missing resource must fail") }
        catch { precondition(!error.localizedDescription.isEmpty) }
        let badDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: badDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: badDirectory) }
        try Data("invalid wav".utf8).write(to: badDirectory.appendingPathComponent(choices[0].filename))
        do { _ = try CutSoundPlayer(directory: badDirectory).load(choices[0]); fatalError("Corrupt resource must fail") }
        catch { precondition(!error.localizedDescription.isEmpty) }
        print("PASS missing and corrupt resources report errors")

        let suite = "Wayfinder.SoundTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let recorder = RecordingPlayer()
        var model = AppModel(defaults: defaults, soundPlayer: recorder)
        precondition(model.cutSound == .crisp && model.playCutSound)
        defaults.set(false, forKey: "playCutSound")
        defaults.set("removed-or-unknown-sound", forKey: "cutSound")
        model = AppModel(defaults: defaults, soundPlayer: recorder)
        precondition(model.cutSound == .crisp && !model.playCutSound)
        print("PASS upgrade preserves mute and unknown selection uses the default")

        for choice in choices {
            model.cutSound = choice
            let reopened = AppModel(defaults: defaults, soundPlayer: recorder)
            precondition(reopened.cutSound == choice && !reopened.playCutSound)
        }
        print("PASS every sound selection persists across model recreation")

        model.cutSound = .paper
        model.cut.didPrepareCut?()
        precondition(recorder.played.isEmpty)
        model.previewCutSound()
        precondition(recorder.played == [.paper] && !model.playCutSound)
        print("PASS muted cuts stay silent while explicit preview remains available")

        model.playCutSound = true
        model.cutSound = .soft
        model.cut.didPrepareCut?()
        precondition(recorder.played == [.paper, .soft])
        precondition(AppModel(defaults: defaults, soundPlayer: recorder).playCutSound)
        print("PASS prepared cut plays selected sound once and toggle persists")

        recorder.fails = true
        var openedSettings = false
        model.showSettings = { openedSettings = true }
        model.cut.didPrepareCut?()
        precondition(model.noticeIsError && model.notice != nil && !openedSettings)
        print("PASS audio failure reports status without stealing Finder focus")
        print("7 sound integration tests, 0 failures")
    }
}
