import SwiftUI

struct SpeedometerView: View {
    var showHUD: () -> Void
    @Environment(Location.self) private var location
    @Environment(\.palette) private var p

    var body: some View {
        VStack(spacing: 12) {
            Spacer(minLength: 0)
            if p.look == .dial {
                Dial(mph: location.mph).padding(.horizontal, 12)
            } else {
                Readout(text: speedText(location.mph, p.look))
                    .frame(maxHeight: 300)
                    .padding(.horizontal)
                Text("MPH").font(p.font(28)).tracking(8).foregroundStyle(p.dim)
                    .shadow(color: .black.opacity(0.8), radius: 4)  // legible over Outrun's sun
            }
            Spacer(minLength: 0)
            if location.denied {
                Text("Location is off for Launch Control. Turn it on in Settings → Privacy & Security → Location Services.")
                    .font(.footnote).foregroundStyle(p.text).multilineTextAlignment(.center).padding(.horizontal, 32)
            }
            Button(action: showHUD) {
                Label("HUD", systemImage: "arrow.up.and.down.righttriangle.up.righttriangle.down")
            }
            .buttonStyle(ThemedButtonStyle(prominent: false))
            .padding(.bottom, 24)
        }
    }
}

/// The speed as a readout shows it: "--" without GPS; three places for the displays that show
/// their unlit ones.
func speedText(_ mph: Double?, _ look: Look) -> String {
    let text = mph.map { String(Int($0.rounded())) } ?? "--"
    guard look == .segments || look == .nixie else { return text }
    return String(repeating: " ", count: max(0, 3 - text.count)) + text
}
