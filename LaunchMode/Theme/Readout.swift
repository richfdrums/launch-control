import SwiftUI

/// A big number (digits, "." and "-"; spaces are unlit places) in the theme's style, as large
/// as fits the space it's given.
struct Readout: View {
    var text: String
    @Environment(\.palette) private var p

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            Group {
                switch p.look {
                case .segments: SegmentText(text: text, height: min(h, w / SegmentText.width(text)))
                case .nixie: NixieText(text: text, height: min(h, w / NixieText.width(text)))
                default: FontText(text: text, size: min(h * 1.2, w / FontText.width(text, p.look)))
                }
            }
            .frame(width: w, height: h)
        }
    }
}

/// The readout in a font: Outrun's chrome italic, Crimson's silver, the others plain.
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
        default: (0.6, 0.28)
        }
        return text.reduce(0) { $0 + ($1 == "." ? dot : digit) } + 0.1
    }

    private var font: Font {
        switch p.look {
        case .neon: .custom("Futura-CondensedExtraBold", size: size)
        case .metal: .system(size: size, weight: .black).italic()
        case .plain: .system(size: size, weight: .thin, design: .rounded)
        default: .system(size: size, weight: .bold)
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
        default:
            text
                .foregroundStyle(p.digit)
                .shadow(color: (p.glow ?? .clear).opacity(0.8), radius: size * 0.05)
        }
    }
}

/// A seven-segment display, slanted, every segment's outline showing unlit.
struct SegmentText: View {
    var text: String
    var height: CGFloat
    @Environment(\.palette) private var p

    private static let advance: CGFloat = 0.68, dotAdvance: CGFloat = 0.22, slant: CGFloat = 0.08
    private static let segments: [Character: String] = [
        "0": "abcdef", "1": "bc", "2": "abged", "3": "abgcd", "4": "fgbc", "5": "afgcd",
        "6": "afgedc", "7": "abc", "8": "abcdefg", "9": "abcdfg", "-": "g", " ": "",
    ]

    /// The text's width per point of height.
    static func width(_ text: String) -> CGFloat {
        text.reduce(slant) { $0 + ($1 == "." ? dotAdvance : advance) }
    }

    var body: some View {
        ZStack {
            Canvas { ctx, _ in ctx.fill(path(lit: false), with: .color(p.ghost)) }
            Canvas { ctx, _ in ctx.fill(path(lit: true), with: .color(p.digit)) }
                .shadow(color: (p.glow ?? .clear).opacity(0.8), radius: height * 0.04)
        }
        .frame(width: Self.width(text) * height, height: height)
    }

    private func path(lit: Bool) -> Path {
        let h = height, t = h * 0.11
        var path = Path(), x: CGFloat = 0
        for c in text {
            if c == "." {
                if lit { path.addRect(CGRect(x: x + (Self.dotAdvance * h - t) / 2, y: h - t, width: t, height: t)) }
                x += Self.dotAdvance * h
                continue
            }
            for s in lit ? Self.segments[c] ?? "" : "abcdefg" { path.addPath(segment(s, x: x)) }
            x += Self.advance * h
        }
        // Lean it like a dashboard's digits: the top shifts right.
        return path.applying(CGAffineTransform(a: 1, b: 0, c: -Self.slant, d: 1, tx: Self.slant * h, ty: 0))
    }

    private func segment(_ s: Character, x: CGFloat) -> Path {
        let h = height, w = h * 0.56, t = h * 0.11, gap = h * 0.012
        let l = x + t / 2, r = x + w - t / 2, top = t / 2, mid = h / 2, bottom = h - t / 2

        func horizontal(_ y: CGFloat) -> Path {
            let x0 = l + gap, x1 = r - gap
            return Path { $0.addLines([CGPoint(x: x0, y: y), CGPoint(x: x0 + t / 2, y: y - t / 2),
                                      CGPoint(x: x1 - t / 2, y: y - t / 2), CGPoint(x: x1, y: y),
                                      CGPoint(x: x1 - t / 2, y: y + t / 2), CGPoint(x: x0 + t / 2, y: y + t / 2)])
                          $0.closeSubpath() }
        }
        func vertical(_ x: CGFloat, _ y0: CGFloat, _ y1: CGFloat) -> Path {
            Path { $0.addLines([CGPoint(x: x, y: y0), CGPoint(x: x + t / 2, y: y0 + t / 2),
                                CGPoint(x: x + t / 2, y: y1 - t / 2), CGPoint(x: x, y: y1),
                                CGPoint(x: x - t / 2, y: y1 - t / 2), CGPoint(x: x - t / 2, y: y0 + t / 2)])
                   $0.closeSubpath() }
        }

        switch s {
        case "a": return horizontal(top)
        case "g": return horizontal(mid)
        case "d": return horizontal(bottom)
        case "f": return vertical(l, top + gap, mid - gap)
        case "b": return vertical(r, top + gap, mid - gap)
        case "e": return vertical(l, mid + gap, bottom - gap)
        default: return vertical(r, mid + gap, bottom - gap)  // c
        }
    }
}

/// Nixie tubes: a glass tube per digit, the lit one glowing in front of the other nine.
struct NixieText: View {
    var text: String
    var height: CGFloat
    @Environment(\.palette) private var p

    private static let advance: CGFloat = 0.66, dotAdvance: CGFloat = 0.16

    static func width(_ text: String) -> CGFloat {
        text.reduce(0) { $0 + ($1 == "." ? dotAdvance : advance) }
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(text.enumerated()), id: \.offset) { _, c in
                if c == "." { dot } else { tube(c) }
            }
        }
    }

    private var glow: Color { p.glow ?? p.digit }

    private func tube(_ c: Character) -> some View {
        let font = Font.system(size: height * 0.72, weight: .thin, design: .rounded)
        let shape = RoundedRectangle(cornerRadius: height * 0.24, style: .continuous)
        return ZStack {
            shape.fill(LinearGradient(colors: [.white.opacity(0.10), .white.opacity(0.02), .white.opacity(0.07)],
                                      startPoint: .leading, endPoint: .trailing))
            shape.stroke(.white.opacity(0.14), lineWidth: 1)
            ForEach(0..<10, id: \.self) { Text("\($0)").font(font).foregroundStyle(p.ghost.opacity(0.3)) }
            if c.isNumber {
                Text(String(c)).font(font).foregroundStyle(p.digit)
                    .shadow(color: glow, radius: height * 0.02)
                    .shadow(color: glow.opacity(0.7), radius: height * 0.08)
            }
        }
        .frame(width: height * 0.6, height: height)
        .padding(.horizontal, height * 0.03)
    }

    private var dot: some View {
        Circle().fill(p.digit)
            .frame(width: height * 0.07, height: height * 0.07)
            .shadow(color: glow, radius: height * 0.03)
            .padding(.bottom, height * 0.14)
            .frame(width: Self.dotAdvance * height, height: height, alignment: .bottom)
    }
}
