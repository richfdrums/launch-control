import SwiftUI

/// The timed runs, newest first, the best starred. Swipe to delete; press and hold to share a
/// run's raw data.
struct HistoryView: View {
    @Environment(History.self) private var history
    @Environment(\.palette) private var p
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if history.runs.isEmpty {
                    Text("No runs yet. Arm the timer on the 0–60 screen.")
                        .foregroundStyle(p.dim)
                        .listRowBackground(Color.clear)
                }
                ForEach(history.runs) { record in
                    row(record)
                        .listRowBackground(p.ghost.opacity(0.5))
                        .swipeActions {
                            Button(role: .destructive) { history.delete(record) } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .contextMenu {
                            ShareLink(item: RunLogs.url(record.id)) {
                                Label("Share run data", systemImage: "square.and.arrow.up")
                            }
                        }
                }
            }
            .scrollContentBackground(.hidden)
            .background(LinearGradient(colors: p.background, startPoint: .top, endPoint: .bottom).ignoresSafeArea())
            .navigationTitle("Runs")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() }.tint(p.accent) }
            }
        }
    }

    private func row(_ record: RunRecord) -> some View {
        let r = record.result
        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(seconds(r.zeroToSixty) + " s").font(p.font(30)).foregroundStyle(p.digit).monospacedDigit()
                Text("Rollout \(seconds(r.withRollout)) · 0–30 \(seconds(r.zeroToThirty)) · \(String(format: "%.2f", r.peakG)) g")
                    .font(.caption).foregroundStyle(p.dim).monospacedDigit()
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                if record.id == history.best?.id {
                    Image(systemName: "star.fill").foregroundStyle(p.accent)
                }
                Text(record.date, style: .date)
                Text(record.date, style: .time)
            }
            .font(.caption)
            .foregroundStyle(p.text)
        }
        .padding(.vertical, 4)
    }
}
