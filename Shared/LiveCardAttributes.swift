import ActivityKit
import Foundation

// Shared: what the app and its widget extension (LaunchControlWidgets) both build.

/// The Live Activity that puts the app on the CarPlay Dashboard, the Lock Screen and the
/// Dynamic Island. The app sends it a new ContentState for each change (LiveCard).
struct LiveCardAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var mph: Int?  // nil while the GPS doesn't know the speed
        // The spike: how many updates the app has sent, and when it sent this one, to see how
        // closely the card keeps up.
        var updates: Int
        var sent: Date
    }
}
