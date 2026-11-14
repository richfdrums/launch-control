import Foundation
import simd

/// Where a launch starts, found from the accelerometer.
struct Launch: Equatable {
    var start: Double  // when the car began to move
    var forward: SIMD3<Double>  // the car's forward direction, in the device's frame (unit)
    var bias: Double  // forward acceleration the phone read at rest, m/s²
}

/// Finds a launch in motion samples: horizontal acceleration that holds above a threshold,
/// traced back to where it rose off the resting level. Any mount works: the car's forward
/// direction is taken as the direction the launch pushes.
enum LaunchDetector {
    static let trigger = 0.12 * Units.g  // acceleration that counts as a launch...
    static let hold = 0.1  // ...held this long (s), so a bump doesn't
    static let floor = 0.03 * Units.g  // where the rise is traced back from
    static let still = 0.05 * Units.g  // the most a resting phone may read
    static let window = 5  // samples averaged (50 ms at 100 Hz)

    /// Each sample's horizontal acceleration, averaged over `window` samples centred on it.
    static func smoothed(_ samples: [MotionSample]) -> [SIMD3<Double>] {
        let h = samples.map(\.horizontal)
        let half = window / 2
        return h.indices.map { i in
            let lo = max(0, i - half), hi = min(h.count - 1, i + half)
            return h[lo...hi].reduce(.zero, +) / Double(hi - lo + 1)
        }
    }

    /// Whether the phone has been at rest for the last `seconds` of the samples.
    static func isStill(_ samples: [MotionSample], for seconds: Double) -> Bool {
        guard let first = samples.first, let last = samples.last, last.t - first.t >= seconds else { return false }
        return zip(samples, smoothed(samples)).allSatisfy { $0.t < last.t - seconds || length($1) < still }
    }

    static func find(in samples: [MotionSample]) -> Launch? {
        let s = smoothed(samples)
        let m = s.map { length($0) }
        var above: Int?
        for i in samples.indices {
            guard m[i] >= trigger else { above = nil; continue }
            let r = above ?? i
            above = r
            guard samples[i].t - samples[r].t >= hold else { continue }

            // Back to the last sample under the floor, then on to where the floor and trigger
            // crossings' line meets the resting level: where the car began to move.
            var j = r
            while j > 0 && m[j] > floor { j -= 1 }
            let restSamples = (0..<j).filter { samples[$0].t >= samples[j].t - 1 }
            let restLevel = restSamples.isEmpty ? 0 : restSamples.map { m[$0] }.reduce(0, +) / Double(restSamples.count)
            let tFloor = crossing(samples, m, from: j, floor) ?? samples[j].t
            let tTrigger = crossing(samples, m, from: j, trigger) ?? samples[r].t
            var start = tFloor
            if tTrigger > tFloor, restLevel < floor {
                let slope = (trigger - floor) / (tTrigger - tFloor)
                start = max(tFloor - (floor - restLevel) / slope, tFloor - 0.1)
            }

            let forward = normalize(s[r...i].reduce(.zero, +))
            let bias = restSamples.isEmpty
                ? 0 : restSamples.map { dot(samples[$0].horizontal, forward) }.reduce(0, +) / Double(restSamples.count)
            return Launch(start: start, forward: forward, bias: bias)
        }
        return nil
    }

    /// When m first reaches level at or after index `from`, linear between samples.
    private static func crossing(_ samples: [MotionSample], _ m: [Double], from: Int, _ level: Double) -> Double? {
        guard let i = m[from...].firstIndex(where: { $0 >= level }) else { return nil }
        guard i > from else { return samples[i].t }
        return samples[i - 1].t + (level - m[i - 1]) / (m[i] - m[i - 1]) * (samples[i].t - samples[i - 1].t)
    }
}
