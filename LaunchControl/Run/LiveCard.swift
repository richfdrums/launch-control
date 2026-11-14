import ActivityKit
import Foundation

/// The app's Live Activity (LiveCardAttributes): on while the app is open, fed the speed.
/// A Live Activity can only be started from the foreground, so RootView starts it as the app
/// becomes active and ends it as the app goes away.
@MainActor
final class LiveCard {
    private var activity: Activity<LiveCardAttributes>?
    private var state = LiveCardAttributes.ContentState(mph: nil, updates: 0, sent: .now)

    func start() {
        print("LiveCard: start, enabled: \(ActivityAuthorizationInfo().areActivitiesEnabled)")  // spike diagnostics
        guard activity == nil, ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        // A card left over from a run that ended without cleaning up (a crash, a debugger stop).
        for old in Activity<LiveCardAttributes>.activities {
            Task { await old.end(nil, dismissalPolicy: .immediate) }
        }
        do {
            activity = try Activity.request(attributes: LiveCardAttributes(),
                                            content: ActivityContent(state: state, staleDate: nil))
            print("LiveCard: started \(activity?.id ?? "-"), state: \(String(describing: activity?.activityState))")  // spike diagnostics
        } catch {
            print("Couldn't start the Live Activity: \(error.localizedDescription)")
        }
    }

    /// Sends every GPS fix, even an unchanged speed, so the spike's count shows how often the
    /// card can be updated.
    func update(mph: Double?) {
        guard let activity else { return }
        state.mph = mph.map { Int($0.rounded()) }
        state.updates += 1
        state.sent = .now
        let content = ActivityContent(state: state, staleDate: nil)
        Task { await activity.update(content) }
    }

    func end() {
        guard let activity else { return }
        self.activity = nil
        let content = ActivityContent(state: state, staleDate: nil)
        Task { await activity.end(content, dismissalPolicy: .immediate) }
    }
}
