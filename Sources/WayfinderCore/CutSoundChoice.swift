import Foundation

public enum CutSoundChoice: String, CaseIterable, Identifiable {
    case crisp, metallic, paper, soft, doubleTick
    public var id: String { rawValue }

    public init(savedValue: String?) {
        self = savedValue.flatMap(Self.init(rawValue:)) ?? .crisp
    }

    public var name: String {
        switch self {
        case .crisp: return "轻快剪切"
        case .metallic: return "金属咔嚓"
        case .paper: return "剪纸摩擦"
        case .soft: return "柔和短划"
        case .doubleTick: return "干脆双击"
        }
    }

    public var filename: String {
        switch self {
        case .crisp: return "E-original-snip.wav"
        case .metallic: return "A-metallic-snip.wav"
        case .paper: return "B-paper-cut.wav"
        case .soft: return "C-soft-swipe.wav"
        case .doubleTick: return "D-double-tick.wav"
        }
    }
}
