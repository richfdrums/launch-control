import SwiftUI

// The themes, after stem-studio's (appleshared/Theme.swift): an id, a palette of colour tokens,
// and a Look for how each draws its numbers, backdrop and speedometer. The palette reaches
// views through the environment (\.palette); ThemeStore remembers the choice.

enum ThemeID: String, CaseIterable, Identifiable {
    case outrun, nightDrive, crimson, midnight
    var id: String { rawValue }

    var name: String {
        switch self {
        case .outrun: "Outrun"
        case .nightDrive: "Night Drive"
        case .crimson: "Crimson"
        case .midnight: "Midnight"
        }
    }
}

/// How a theme draws its numbers (Readout), its backdrop and its speedometer.
enum Look {
    case neon  // chrome-gradient italic digits, glowing, over a sunset and a scrolling grid
    case plain  // thin digits and nothing else
    case metal  // brushed-silver digits
}

struct Palette {
    var background: [Color]  // top to bottom (centre outwards for .metal)
    var digit: Color  // a readout's lit colour, the top of its gradient for .neon
    var digitEnd: Color? = nil  // the bottom of .neon's gradient
    var glow: Color? = nil
    var ghost: Color  // the GPS badge's unlit bars
    var text: Color
    var dim: Color
    var accent: Color
    var onAccent: Color
    var look: Look

    /// Labels and buttons in the theme's type.
    func font(_ size: CGFloat) -> Font {
        switch look {
        case .neon: .custom("Futura-CondensedExtraBold", size: size)
        case .plain: .system(size: size, weight: .light, design: .rounded)
        case .metal: .system(size: size, weight: .heavy).width(.expanded)
        }
    }
}

extension Palette {
    static func of(_ id: ThemeID) -> Palette {
        switch id {
        case .outrun: outrun
        case .nightDrive: nightDrive
        case .crimson: crimson
        case .midnight: midnight
        }
    }

    static let outrun = Palette(
        background: [Color(hex: 0x0B0221), Color(hex: 0x2B0B4F), Color(hex: 0x6B1460)],
        digit: Color(hex: 0xFFF3A3), digitEnd: Color(hex: 0xFF2E97), glow: Color(hex: 0xFF2E97),
        ghost: Color(hex: 0x2B0B4F), text: Color(hex: 0xF7E8FF), dim: Color(hex: 0xB48BD8),
        accent: Color(hex: 0xFF2E97), onAccent: Color(hex: 0x1A0420), look: .neon)

    // Dim and red, to keep night vision.
    static let nightDrive = Palette(
        background: [.black, .black],
        digit: Color(hex: 0xC21A1A), glow: Color(hex: 0x5A0000),
        ghost: Color(hex: 0x1E0505), text: Color(hex: 0xA01616), dim: Color(hex: 0x5E0B0B),
        accent: Color(hex: 0x8E1212), onAccent: .black, look: .plain)

    static let crimson = Palette(
        background: [Color(hex: 0x8E0E1C), Color(hex: 0x2A0207)],
        digit: .white,
        ghost: Color(hex: 0x4A0610), text: Color(hex: 0xF4E9EA), dim: Color(hex: 0xC9A3A8),
        accent: Color(hex: 0xE6E9ED), onAccent: Color(hex: 0x4A0610), look: .metal)

    // Crimson in dark purple and black.
    static let midnight = Palette(
        background: [Color(hex: 0x3A1460), Color(hex: 0x07020D)],
        digit: .white,
        ghost: Color(hex: 0x2A0E45), text: Color(hex: 0xEEE9F4), dim: Color(hex: 0xB2A3C9),
        accent: Color(hex: 0xE6E9ED), onAccent: Color(hex: 0x2A0E45), look: .metal)
}

extension EnvironmentValues {
    @Entry var palette = Palette.outrun
}

/// The theme in use, remembered on the phone.
@Observable @MainActor
final class ThemeStore {
    private(set) var id: ThemeID
    private static let key = "theme"

    init() {
        id = ThemeID(rawValue: UserDefaults.standard.string(forKey: Self.key) ?? "") ?? .outrun
    }

    var palette: Palette { .of(id) }

    func set(_ id: ThemeID) {
        self.id = id
        UserDefaults.standard.set(id.rawValue, forKey: Self.key)
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}
