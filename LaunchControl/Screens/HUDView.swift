import SwiftUI
import UIKit

/// The speed flipped top to bottom, for a phone lying flat on the dash, its top edge toward
/// the windshield: the reflection turns it the right way up. Black around it, so only the
/// digits reflect, at full brightness while it's showing. Tap to leave.
struct HUDView: View {
    @Environment(Location.self) private var location
    @Environment(\.palette) private var p
    @Environment(\.dismiss) private var dismiss
    @State private var brightness: CGFloat?
    @State private var showHint = true

    private var screen: UIScreen? {
        UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.screen }.first
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                // A third of the full-screen size: a third of the width (less the padding) and
                // of the height, as the readout fits whichever runs out first.
                Readout(text: speedText(location.mph))
                    .containerRelativeFrame(.horizontal) { w, _ in (w - 32) / 3 }
                    .frame(maxHeight: 140)
                Text("MPH").font(p.font(14)).tracking(8).foregroundStyle(p.dim)
                Text(headingText(location.course)).font(p.font(20)).tracking(4).foregroundStyle(p.dim)
                    .monospacedDigit().padding(.top, 12)
            }
            .padding()
            .scaleEffect(x: 1, y: -1)
            // At the screen's top edge, the one by the windshield, so the reflection sits as low
            // as it can, just above the dash.
            .frame(maxHeight: .infinity, alignment: .top)
            if showHint {
                VStack {
                    Spacer()
                    Text("Lay the phone flat, top edge to the windshield. Tap to exit.")
                        .font(.footnote).foregroundStyle(.gray).multilineTextAlignment(.center).padding(32)
                }
                .transition(.opacity)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { dismiss() }
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .task {
            try? await Task.sleep(for: .seconds(4))
            withAnimation { showHint = false }
        }
        .onAppear {
            brightness = screen?.brightness
            screen?.brightness = 1
        }
        .onDisappear {
            if let brightness { screen?.brightness = brightness }
        }
    }

    /// The course as a compass point and degrees, "SW 225°", or "--" before the car has moved.
    private func headingText(_ course: Double?) -> String {
        guard let course else { return "--" }
        let points = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        let degrees = Int(course.rounded()) % 360
        return "\(points[Int((course / 45).rounded()) % 8]) \(degrees)°"
    }
}
