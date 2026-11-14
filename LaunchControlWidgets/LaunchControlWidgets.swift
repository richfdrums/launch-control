import ActivityKit
import SwiftUI
import WidgetKit

@main
struct LaunchControlWidgets: WidgetBundle {
    var body: some Widget {
        LiveCardWidget()
    }
}

/// The Live Activity's views. `.small` is the one CarPlay shows (and the Apple Watch's Smart
/// Stack); the Lock Screen gets the same card larger.
struct LiveCardWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LiveCardAttributes.self) { context in
            CardView(state: context.state)
                .activityBackgroundTint(.black)
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    CardView(state: context.state)
                }
            } compactLeading: {
                Text("MPH").font(.caption2.bold()).foregroundStyle(.secondary)
            } compactTrailing: {
                Text(context.state.mphText).monospacedDigit().bold()
            } minimal: {
                Text(context.state.mphText).monospacedDigit().bold()
            }
        }
        .supplementalActivityFamilies([.small])
    }
}

/// The speed, with the spike's count of updates and when the last one was sent.
private struct CardView: View {
    var state: LiveCardAttributes.ContentState
    @Environment(\.activityFamily) private var family

    var body: some View {
        let small = family == .small
        VStack(spacing: small ? 0 : 4) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(state.mphText)
                    .font(.system(size: small ? 44 : 64, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text("MPH").font(.caption.bold()).foregroundStyle(.secondary)
            }
            Text("#\(state.updates) · \(state.sent.formatted(.dateTime.hour().minute().second()))")
                .font(.caption2)
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
        .foregroundStyle(.white)
        .padding(small ? 4 : 16)
    }
}

private extension LiveCardAttributes.ContentState {
    var mphText: String { mph.map(String.init) ?? "--" }
}
