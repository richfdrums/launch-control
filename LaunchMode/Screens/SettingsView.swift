import SwiftUI

struct SettingsView: View {
    @Environment(ThemeStore.self) private var themes
    @Environment(\.dismiss) private var dismiss
    @AppStorage("voice") private var voice = true

    var body: some View {
        NavigationStack {
            List {
                Section("Theme") {
                    ForEach(ThemeID.allCases) { id in
                        Button { themes.set(id) } label: { themeRow(id) }
                    }
                }
                Section {
                    Toggle("Speak the time", isOn: $voice)
                } footer: {
                    Text("Says “Ready” when the timer is armed, and reads out your 0–60 time.")
                }
                Section("Timing a run") {
                    Text("Mount the phone firmly, upright and facing you. Stop, tap Arm, and hold still until it says Ready. Then launch: the timer starts and stops itself, so leave the phone alone.")
                    Text("The time runs from the first movement. Magazines start the clock after a foot of travel, so compare theirs with the rollout time.")
                    Text("Only do this on a track or a closed road.").bold()
                }
                .font(.subheadline)
                Section("Run data") {
                    Text("Each run's raw GPS and motion data is in the Files app: On My iPhone → Launch Mode → Runs.")
                        .font(.subheadline)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }

    private func themeRow(_ id: ThemeID) -> some View {
        let palette = Palette.of(id)
        return HStack(spacing: 16) {
            ZStack {
                LinearGradient(colors: palette.background, startPoint: .top, endPoint: .bottom)
                Readout(text: "60").padding(8)
            }
            .environment(\.palette, palette)
            .frame(width: 96, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            Text(id.name).foregroundStyle(.primary)
            Spacer()
            if themes.id == id { Image(systemName: "checkmark").foregroundStyle(.tint) }
        }
    }
}
