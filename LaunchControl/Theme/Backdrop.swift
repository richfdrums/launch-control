import SwiftUI

/// The screen's background in the theme: Outrun's sunset and grid, LCD Dash's scanlines,
/// the others' gradients.
struct Backdrop: View {
    var mph: Double = 0  // Outrun's grid scrolls with it
    @Environment(\.palette) private var p

    var body: some View {
        ZStack {
            if p.look == .metal {
                RadialGradient(colors: p.background, center: UnitPoint(x: 0.5, y: 0.35), startRadius: 0, endRadius: 700)
            } else {
                LinearGradient(colors: p.background, startPoint: .top, endPoint: .bottom)
            }
            switch p.look {
            case .neon: OutrunScene(mph: mph)
            case .segments: Scanlines()
            case .dial, .nixie:
                RadialGradient(colors: [.clear, .black.opacity(0.55)], center: .center, startRadius: 120, endRadius: 600)
            case .plain, .metal: EmptyView()
            }
        }
        .ignoresSafeArea()
    }
}

/// A striped sun setting behind a neon grid that rolls toward you, faster the faster you go.
private struct OutrunScene: View {
    var mph: Double
    @State private var scroll = Scroll()

    /// The grid's position, advanced each frame at the speed of the moment, so a change of
    /// speed changes its pace without a jump.
    final class Scroll {
        var phase = 0.0
        var last: Date?
        func advance(to date: Date, rate: Double) -> Double {
            if let last { phase += date.timeIntervalSince(last) * rate }
            last = date
            return phase
        }
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            let phase = scroll.advance(to: timeline.date, rate: 0.5 + mph / 12)
            Canvas { ctx, size in
                let w = size.width, h = size.height, horizon = h * 0.7

                // The sun: a gradient disc, cut into thinning stripes toward the horizon.
                let r = w * 0.36, sun = CGRect(x: w / 2 - r, y: horizon - r * 1.35, width: 2 * r, height: 2 * r)
                ctx.drawLayer { l in
                    l.addFilter(.shadow(color: Color(hex: 0xFF2E97).opacity(0.8), radius: 30))
                    l.clip(to: Path(CGRect(x: 0, y: 0, width: w, height: horizon)))
                    l.fill(Path(ellipseIn: sun), with: .linearGradient(
                        Gradient(colors: [Color(hex: 0xFFD319), Color(hex: 0xFF8C2A), Color(hex: 0xFF2E97)]),
                        startPoint: CGPoint(x: w / 2, y: sun.minY), endPoint: CGPoint(x: w / 2, y: sun.maxY)))
                    l.blendMode = .destinationOut
                    var y = sun.midY - r * 0.1, gap = r * 0.02
                    while y < horizon {
                        l.fill(Path(CGRect(x: 0, y: y, width: w, height: gap)), with: .color(.black))
                        y += r * 0.13
                        gap += r * 0.012
                    }
                }

                // The ground, and the grid on it.
                ctx.fill(Path(CGRect(x: 0, y: horizon, width: w, height: h - horizon)),
                         with: .linearGradient(Gradient(colors: [Color(hex: 0x1A0533), .black]),
                                               startPoint: CGPoint(x: 0, y: horizon), endPoint: CGPoint(x: 0, y: h)))
                ctx.drawLayer { l in
                    l.addFilter(.shadow(color: Color(hex: 0xFF2E97), radius: 6))
                    var grid = Path()
                    for i in -14...14 {
                        let x = CGFloat(i)
                        grid.move(to: CGPoint(x: w / 2 + x * w * 0.03, y: horizon))
                        grid.addLine(to: CGPoint(x: w / 2 + x * w * 0.3, y: h))
                    }
                    let f = phase.truncatingRemainder(dividingBy: 1)
                    for k in 0..<24 {
                        let depth = Double(k) + 1 - f
                        guard depth >= 1 else { continue }
                        let y = horizon + (h - horizon) / depth
                        grid.move(to: CGPoint(x: 0, y: y))
                        grid.addLine(to: CGPoint(x: w, y: y))
                    }
                    l.stroke(grid, with: .color(Color(hex: 0xFF2E97).opacity(0.85)), lineWidth: 1.5)
                }
                ctx.stroke(Path { $0.move(to: CGPoint(x: 0, y: horizon)); $0.addLine(to: CGPoint(x: w, y: horizon)) },
                           with: .color(Color(hex: 0x2DE2E6)), lineWidth: 2)
            }
        }
    }
}

/// An LCD panel's fine horizontal lines.
private struct Scanlines: View {
    var body: some View {
        Canvas { ctx, size in
            var lines = Path(), y: CGFloat = 0
            while y < size.height {
                lines.addRect(CGRect(x: 0, y: y, width: size.width, height: 1))
                y += 3
            }
            ctx.fill(lines, with: .color(.black.opacity(0.35)))
        }
        .overlay(RadialGradient(colors: [Color(hex: 0x4DFFC3).opacity(0.06), .clear], center: .center,
                                startRadius: 0, endRadius: 500))
    }
}
