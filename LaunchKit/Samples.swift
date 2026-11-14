import Foundation
import simd

// LaunchKit: the timing maths, free of the UI and the sensors' frameworks so the unit tests can
// compile it on its own. The app and LaunchControlTests both build this folder.

enum Units {
    static let mph = 0.44704  // m/s in 1 mph
    static let g = 9.80665  // m/s² in 1 g
    static let foot = 0.3048  // m
}

/// One CoreMotion device-motion reading, in the device's frame and in g, timed on the GPS's
/// clock (seconds since 1970).
struct MotionSample: Codable, Equatable {
    var t: Double
    var ax, ay, az: Double  // user acceleration (gravity removed)
    var gx, gy, gz: Double  // gravity

    /// The acceleration in the horizontal plane, in m/s² (still in the device's frame).
    var horizontal: SIMD3<Double> {
        let u = SIMD3(ax, ay, az), g = SIMD3(gx, gy, gz)
        guard length(g) > 0 else { return u * Units.g }
        let down = normalize(g)
        return (u - dot(u, down) * down) * Units.g
    }
}

/// One GPS fix, as CLLocation reports it.
struct GPSFix: Codable, Equatable {
    var t: Double  // seconds since 1970
    var speed: Double  // m/s; negative when invalid
    var speedAccuracy: Double  // m/s; negative when invalid
    var horizontalAccuracy: Double  // m; negative when invalid
}

/// Everything recorded during a run, kept so the run can be analysed again.
struct RunLog: Codable {
    var id: UUID
    var date: Date
    var motion: [MotionSample]
    var gps: [GPSFix]
}
