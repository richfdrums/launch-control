import Foundation
import simd

struct RunResult: Codable, Equatable {
    var zeroToSixty: Double  // s, from the first movement
    var withRollout: Double  // s, from a foot of travel, as magazines time it
    var zeroToThirty: Double  // s
    var peakG: Double
}

/// The speed through a run, from the moment the car began to move.
struct SpeedCurve {
    var t: [Double] = [], a: [Double] = [], v: [Double] = [], d: [Double] = []
}

/// Times a run from its log: the accelerometer, integrated from the launch, gives the speed's
/// shape between the once-a-second GPS fixes; each fix pins it, the error spread linearly
/// between fixes. The crossings of 30 and 60 mph and a foot of travel are then found between
/// samples.
enum RunAnalyzer {
    static let sixty = 60 * Units.mph
    static let thirty = 30 * Units.mph
    /// How far a fix's speed trails its timestamp (s). Tune from logged runs.
    static let gpsLatency = 0.0

    static func analyze(_ log: RunLog) -> RunResult? {
        guard log.gps.contains(where: { $0.speed >= sixty }),
              let launch = LaunchDetector.find(in: log.motion) else { return nil }
        let c = curve(log, launch)
        guard let t60 = crossing(c.t, c.v, sixty), let t30 = crossing(c.t, c.v, thirty),
              let tFoot = crossing(c.t, c.d, Units.foot) else { return nil }
        let peak = zip(c.t, c.a).filter { $0.0 <= t60 }.map(\.1).max() ?? 0
        return RunResult(zeroToSixty: t60 - launch.start, withRollout: t60 - tFoot,
                         zeroToThirty: t30 - launch.start, peakG: peak / Units.g)
    }

    static func curve(_ log: RunLog, _ launch: Launch) -> SpeedCurve {
        var c = SpeedCurve(t: [launch.start], a: [0], v: [0])
        for s in log.motion where s.t > launch.start {
            let a = dot(s.horizontal, launch.forward) - launch.bias
            c.v.append(c.v.last! + (a + c.a.last!) / 2 * (s.t - c.t.last!))
            c.t.append(s.t)
            c.a.append(a)
        }

        var pins: [(t: Double, error: Double)] = [(launch.start, 0)]
        for f in log.gps where f.speed >= 0 {
            let t = f.t - gpsLatency
            guard t > launch.start, t <= c.t.last! else { continue }
            pins.append((t, f.speed - interpolate(c.t, c.v, at: t)))
        }
        let pinT = pins.map(\.t), pinError = pins.map(\.error)
        for i in c.v.indices { c.v[i] += interpolate(pinT, pinError, at: c.t[i]) }

        c.d = [0]
        for i in c.t.indices.dropFirst() {
            c.d.append(c.d.last! + (c.v[i] + c.v[i - 1]) / 2 * (c.t[i] - c.t[i - 1]))
        }
        return c
    }

    /// y at x, linear between points and held beyond the ends (xs ascending).
    static func interpolate(_ xs: [Double], _ ys: [Double], at x: Double) -> Double {
        guard let hi = xs.firstIndex(where: { $0 >= x }) else { return ys.last ?? 0 }
        guard hi > 0 else { return ys[0] }
        return ys[hi - 1] + (x - xs[hi - 1]) / (xs[hi] - xs[hi - 1]) * (ys[hi] - ys[hi - 1])
    }

    /// When y first reaches level, linear between samples.
    static func crossing(_ ts: [Double], _ ys: [Double], _ level: Double) -> Double? {
        guard let i = ys.firstIndex(where: { $0 >= level }) else { return nil }
        guard i > 0 else { return ts[0] }
        return ts[i - 1] + (level - ys[i - 1]) / (ys[i] - ys[i - 1]) * (ts[i] - ts[i - 1])
    }
}
