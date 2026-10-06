import Foundation

public enum CutSoundChoice: String, CaseIterable, Identifiable {
    case crisp, metallic, paper, soft, doubleTick
    case cleanClick, tightDouble, mechanicalSnap, fastLightHeavy, spacedLightHeavy
    case tightMechanical, deepMechanical, closeMechanical, mediumMechanical
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
        case .cleanClick: return "清脆单击"
        case .tightDouble: return "紧凑双击"
        case .mechanicalSnap: return "机械咔嗒"
        case .fastLightHeavy: return "利落轻重双击"
        case .spacedLightHeavy: return "分明轻重双击"
        case .tightMechanical: return "紧凑机械双击（27 ms）"
        case .deepMechanical: return "厚实机械双击（46 ms）"
        case .closeMechanical: return "贴合机械双击（13 ms）"
        case .mediumMechanical: return "机械双击（20 ms）"
        }
    }

    public var filename: String {
        switch self {
        case .crisp: return "E-original-snip.wav"
        case .metallic: return "A-metallic-snip.wav"
        case .paper: return "B-paper-cut.wav"
        case .soft: return "C-soft-swipe.wav"
        case .doubleTick: return "D-double-tick.wav"
        case .cleanClick: return "F-clean-click.wav"
        case .tightDouble: return "G-tight-double.wav"
        case .mechanicalSnap: return "H-mechanical-snap.wav"
        case .fastLightHeavy: return "I-fast-light-heavy.wav"
        case .spacedLightHeavy: return "J-spaced-light-heavy.wav"
        case .tightMechanical: return "K-tight-mechanical-pair.wav"
        case .deepMechanical: return "L-deep-mechanical-pair.wav"
        case .closeMechanical: return "M-close-mechanical-pair.wav"
        case .mediumMechanical: return "N-20ms-mechanical-pair.wav"
        }
    }
}
