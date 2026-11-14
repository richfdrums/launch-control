import SwiftUI

/// A button in the theme: filled with the accent when prominent, outlined otherwise.
struct ThemedButtonStyle: ButtonStyle {
    var prominent = true
    @Environment(\.palette) private var p

    func makeBody(configuration: Configuration) -> some View {
        let shape = p.look == .segments ? AnyShape(RoundedRectangle(cornerRadius: 4)) : AnyShape(Capsule())
        configuration.label
            .font(p.font(prominent ? 26 : 16))
            .tracking(prominent ? 4 : 1.5)
            .padding(.horizontal, prominent ? 48 : 18)
            .padding(.vertical, prominent ? 18 : 10)
            .foregroundStyle(prominent ? p.onAccent : p.accent)
            .background {
                if prominent { shape.fill(p.accent) } else { shape.stroke(p.accent, lineWidth: 1.5) }
            }
            .shadow(color: (p.glow ?? .clear).opacity(prominent ? 0.7 : 0.35), radius: 12)
            .opacity(configuration.isPressed ? 0.7 : 1)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}

/// The GPS's signal: a location arrow and three bars.
struct SignalBadge: View {
    var signal: Signal
    @Environment(\.palette) private var p

    private var level: Int {
        switch signal {
        case .none: 0
        case .poor: 1
        case .fair: 2
        case .good: 3
        }
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 3) {
            Image(systemName: signal == .none ? "location.slash" : "location.fill")
                .font(.system(size: 13, weight: .semibold))
                .padding(.trailing, 2)
            ForEach(0..<3) { i in
                RoundedRectangle(cornerRadius: 1)
                    .fill(i < level ? p.accent : p.ghost)
                    .frame(width: 4, height: CGFloat(6 + 4 * i))
            }
        }
        .foregroundStyle(level == 0 ? p.dim : p.accent)
        .accessibilityLabel("GPS signal")
    }
}
