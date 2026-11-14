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
                Readout(text: speedText(location.mph, p.look == .dial ? .plain : p.look)).frame(maxHeight: 420)
                Text("MPH").font(p.font(40)).tracking(8).foregroundStyle(p.dim)
            }
            .padding()
            .scaleEffect(x: 1, y: -1)
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
}
