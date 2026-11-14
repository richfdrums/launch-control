import SwiftUI

@main
struct LaunchModeApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

/// A placeholder until the speedometer (PLAN.md, step 4).
struct RootView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                Text("0")
                    .font(.system(size: 220, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                Text("MPH")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .foregroundStyle(.white)
        }
    }
}

#Preview {
    RootView()
}
