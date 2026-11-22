import SwiftUI

/// A big number (digits, "." and "-") in the theme's style, as large as fits the space it's
/// given.
struct Readout: View {
    var text: String
    @Environment(\.palette) private var p

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            FontText(text: text, size: min(h * 1.2, w / FontText.width(text, p.look)))
                .frame(width: w, height: h)
        }
    }
}

/// The readout in a font: Outrun's chrome italic, Crimson's and Midnight's silver, Night Drive's thin.
private struct FontText: View {
    var text: String
    var size: CGFloat
    @Environment(\.palette) private var p

    /// The text's width per point of font size.
    static func width(_ text: String, _ look: Look) -> CGFloat {
        let (digit, dot): (CGFloat, CGFloat) = switch look {
        case .neon: (0.5, 0.25)
        case .metal: (0.64, 0.3)
        case .plain: (0.58, 0.28)
        }
        return text.reduce(0) { $0 + ($1 == "." ? dot : digit) } + 0.1
    }

    private var font: Font {
        switch p.look {
        case .neon: .custom("Futura-CondensedExtraBold", size: size)
        case .metal: .system(size: size, weight: .black).italic()
        case .plain: .system(size: size, weight: .thin, design: .rounded)
        }
    }

    var body: some View {
        let text = Text(text).font(font).monospacedDigit().lineLimit(1).minimumScaleFactor(0.3)
        switch p.look {
        case .neon:
            let glow = p.glow ?? .clear
            text
                .foregroundStyle(LinearGradient(colors: [p.digit, p.digitEnd ?? p.digit], startPoint: .top, endPoint: .bottom))
                .transformEffect(CGAffineTransform(a: 1, b: 0, c: -0.2, d: 1, tx: size * 0.1, ty: 0))
                .shadow(color: glow.opacity(0.9), radius: size * 0.03)
                .shadow(color: glow.opacity(0.5), radius: size * 0.12)
        case .metal:
            text
                .foregroundStyle(LinearGradient(
                    colors: [.white, Color(hex: 0xC9CDD3), Color(hex: 0x6E747C), Color(hex: 0xE9ECEF)],
                    startPoint: .top, endPoint: .bottom))
                .shadow(color: .black.opacity(0.5), radius: size * 0.02, y: size * 0.02)
        case .plain:
            text
                .foregroundStyle(p.digit)
                .shadow(color: (p.glow ?? .clear).opacity(0.8), radius: size * 0.05)
        }
    }
}
