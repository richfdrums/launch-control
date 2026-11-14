import SwiftUI

/// Gauge's analog speedometer: 0–160 mph over 240°, 60 marked in the accent, the speed also
/// in digits below the hub.
struct Dial: View {
    var mph: Double?
    @Environment(\.palette) private var p

    static let top = 160.0

    /// The math angle (degrees, anticlockwise from 3 o'clock) of a speed.
    private static func angle(_ mph: Double) -> Double { 210 - 240 * mph / top }

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height), r = s * 0.46
            ZStack {
                Canvas { ctx, size in face(ctx, center: CGPoint(x: size.width / 2, y: size.height / 2), r: r) }
                VStack(spacing: 0) {
                    Readout(text: mph.map { String(Int($0.rounded())) } ?? "--").frame(height: s * 0.2)
                    Text("MPH").font(p.font(s * 0.045)).tracking(4).foregroundStyle(p.dim)
                }
                .frame(width: s * 0.5)
                .offset(y: s * 0.24)
                Capsule().fill(p.accent)
                    .frame(width: s * 0.016, height: r * 0.9)
                    .shadow(color: p.accent.opacity(0.6), radius: 6)
                    .offset(y: -r * 0.45)
                    .frame(width: s, height: s)
                    .rotationEffect(.degrees(90 - Self.angle(min(mph ?? 0, Self.top))))
                    .animation(.linear(duration: 1), value: mph ?? 0)
                Circle().fill(p.ghost).overlay(Circle().stroke(p.dim, lineWidth: 2)).frame(width: s * 0.07)
            }
            .frame(width: s, height: s)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func face(_ ctx: GraphicsContext, center c: CGPoint, r: CGFloat) {
        func point(_ mph: Double, _ radius: CGFloat) -> CGPoint {
            let a = Self.angle(mph) * .pi / 180
            return CGPoint(x: c.x + radius * cos(a), y: c.y - radius * sin(a))
        }
        var track = Path()
        track.move(to: point(0, r))
        for v in stride(from: 1.0, through: Self.top, by: 1) { track.addLine(to: point(v, r)) }
        ctx.stroke(track, with: .color(p.ghost), lineWidth: 3)

        for v in stride(from: 0, through: Int(Self.top), by: 5) {
            let major = v % 20 == 0, length = r * (major ? 0.12 : v % 10 == 0 ? 0.08 : 0.045)
            let color = v == 60 ? p.accent : major ? p.text : p.dim
            ctx.stroke(Path { $0.move(to: point(Double(v), r)); $0.addLine(to: point(Double(v), r - length)) },
                       with: .color(color), lineWidth: major ? 3.5 : 1.5)
            if major || v == 60 {
                ctx.draw(Text("\(v)").font(p.font(r * 0.11)).foregroundColor(color),
                         at: point(Double(v), r * 0.74))
            }
        }
    }
}
