import SwiftUI

struct SpeedometerView: View {
    var showHUD: () -> Void
    @Environment(Location.self) private var location
    @Environment(\.palette) private var p

    var body: some View {
        VStack(spacing: 12) {
            Spacer(minLength: 0)
            SpeedReadout(text: speedText(location.mph))
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

/// The speed and "MPH" under it, as the speedometer (and a theme's preview) shows it.
struct SpeedReadout: View {
    var text: String
    @Environment(\.palette) private var p

    var body: some View {
        Readout(text: text)
            .frame(maxHeight: 300)
            .padding(.horizontal)
        Text("MPH").font(p.font(28)).tracking(8).foregroundStyle(p.dim)
            .shadow(color: .black.opacity(0.8), radius: 4)  // legible over Outrun's sun
    }
}

/// The speed as a readout shows it: "--" without GPS.
func speedText(_ mph: Double?) -> String {
    mph.map { String(Int($0.rounded())) } ?? "--"
}
