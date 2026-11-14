import SwiftUI

@main
struct LaunchModeApp: App {
    @State private var location: Location
    @State private var history: History
    @State private var run: RunController
    @State private var themes = ThemeStore()

    init() {
        UserDefaults.standard.register(defaults: ["voice": true])
        let location = Location(), history = History()
        _location = State(initialValue: location)
        _history = State(initialValue: history)
        _run = State(initialValue: RunController(location: location, history: history))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(location)
                .environment(history)
                .environment(run)
                .environment(themes)
        }
    }
}

enum Mode {
    case speed, launch
}

struct RootView: View {
    @Environment(ThemeStore.self) private var themes
    @Environment(Location.self) private var location
    @Environment(RunController.self) private var run
    @Environment(\.scenePhase) private var scenePhase
    @State private var mode = Mode.speed
    @State private var showSettings = false
    @State private var showHUD = false

    var body: some View {
        ZStack {
            Backdrop(mph: location.mph ?? 0)
            VStack(spacing: 0) {
                TopBar(mode: $mode) { showSettings = true }
                TabView(selection: $mode) {
                    SpeedometerView { showHUD = true }.tag(Mode.speed)
                    LaunchView().tag(Mode.launch)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
        .sheet(isPresented: $showSettings) { SettingsView().environment(\.palette, themes.palette) }
        .fullScreenCover(isPresented: $showHUD) { HUDView().environment(\.palette, themes.palette) }
        .environment(\.palette, themes.palette)
        .statusBarHidden()
        .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
        .onChange(of: scenePhase, initial: true) { _, phase in
            switch phase {
            case .active: location.start()
            case .background:
                location.stop()
                run.cancel()
            default: break
            }
        }
    }
}

/// The GPS signal, the switch between the speedometer and the timer, and settings.
private struct TopBar: View {
    @Binding var mode: Mode
    var showSettings: () -> Void
    @Environment(Location.self) private var location
    @Environment(\.palette) private var p

    var body: some View {
        HStack {
            SignalBadge(signal: location.signal).frame(width: 60, alignment: .leading)
            Spacer()
            HStack(spacing: 4) {
                tab("SPEED", .speed)
                tab("0–60", .launch)
            }
            Spacer()
            Button(action: showSettings) {
                Image(systemName: "gearshape.fill").font(.system(size: 20))
            }
            .foregroundStyle(p.accent)
            .frame(width: 60, alignment: .trailing)
            .accessibilityLabel("Settings")
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private func tab(_ title: String, _ m: Mode) -> some View {
        Button { withAnimation { mode = m } } label: {
            Text(title)
                .font(p.font(15))
                .tracking(2)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .foregroundStyle(mode == m ? p.onAccent : p.dim)
                .background(Capsule().fill(mode == m ? p.accent : .clear))
        }
    }
}
