import Foundation
import Testing

/// A made-up run: standing still, then a hard launch with two gear changes, past 65 mph. The
/// phone is mounted `tilt` radians back from upright and reads `scale` of the true acceleration
/// plus a bias and noise; GPS reports once a second, starting `gpsPhase` s into the log.
struct SyntheticRun {
    var tilt = 0.2
    var scale = 1.0
    var bias = 0.01  // g, along the car's forward axis
    var noise = 0.01  // g, per axis
    var gpsPhase = 0.3
    var gpsNoise = 0.1  // m/s
    var rest = 2.0  // s before the launch
    var bump = false  // knock the phone while standing
    var launches = true
    var seed: UInt64 = 1

    static let epoch = 1_800_000_000.0

    /// The log, and the true times from the launch to 30 and 60 mph and to a foot of travel.
    func make() -> (log: RunLog, t30: Double, t60: Double, tFoot: Double) {
        var rng = Rng(seed: seed)
        let down = SIMD3(0, -cos(tilt), -sin(tilt)), forward = SIMD3(0, sin(tilt), -cos(tilt))
        let peak = 0.55 * Units.g, dt = 0.0005
        var t = 0.0, v = 0.0, d = 0.0, shiftUntil = -1.0, shifts = [13.0, 22.0]
        var t30: Double?, t60: Double?, tFoot: Double?
        var motion: [MotionSample] = [], gps: [GPSFix] = []
        var nextMotion = 0.0, nextFix = gpsPhase
        let end = launches ? 65 * Units.mph : 0

        while launches ? v < end : t < rest + 3 {
            let tau = t - rest
            var a = 0.0
            if launches && tau >= 0 {
                if let s = shifts.first, v >= s { shifts.removeFirst(); shiftUntil = tau + 0.35 }
                a = tau < shiftUntil ? -0.05 * Units.g : min(peak * min(1, tau / 0.25), peak * (1 - v / 45))
            }
            if bump && tau > -1 && tau < -0.95 { a = 0.3 * Units.g }

            if t >= nextMotion {
                let u = (scale * a / Units.g + bias) * forward
                    + SIMD3(rng.gaussian(), rng.gaussian(), rng.gaussian()) * noise
                motion.append(MotionSample(t: Self.epoch + t, ax: u.x, ay: u.y, az: u.z,
                                           gx: down.x, gy: down.y, gz: down.z))
                nextMotion += 0.01
            }
            if t >= nextFix {
                gps.append(GPSFix(t: Self.epoch + t, speed: max(0, v + rng.gaussian() * gpsNoise),
                                  speedAccuracy: 0.3, horizontalAccuracy: 5))
                nextFix += 1
            }

            if bump && tau > -1 && tau < -0.95 { a = 0 }  // a knock moves the phone, not the car
            v += a * dt
            d += v * dt
            t += dt
            if tau >= 0 {
                if t30 == nil, v >= 30 * Units.mph { t30 = tau }
                if t60 == nil, v >= 60 * Units.mph { t60 = tau }
                if tFoot == nil, d >= Units.foot { tFoot = tau }
            }
        }
        let log = RunLog(id: UUID(), date: Date(timeIntervalSince1970: Self.epoch), motion: motion, gps: gps)
        return (log, t30 ?? 0, t60 ?? 0, tFoot ?? 0)
    }
}

/// SplitMix64, so the noise is the same every run.
struct Rng {
    var seed: UInt64
    mutating func next() -> Double {
        seed &+= 0x9E37_79B9_7F4A_7C15
        var z = seed
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return Double((z ^ (z >> 31)) >> 11) / Double(1 << 53)
    }
    mutating func gaussian() -> Double {
        (-2 * log(max(next(), 1e-12))).squareRoot() * cos(2 * .pi * next())
    }
}

struct RunAnalyzerTests {
    func check(_ run: SyntheticRun, within tolerance: Double) throws {
        let (log, t30, t60, tFoot) = run.make()
        let r = try #require(RunAnalyzer.analyze(log))
        #expect(abs(r.zeroToSixty - t60) < tolerance, "0-60 \(r.zeroToSixty) vs \(t60)")
        #expect(abs(r.withRollout - (t60 - tFoot)) < tolerance, "rollout \(r.withRollout) vs \(t60 - tFoot)")
        #expect(abs(r.zeroToThirty - t30) < tolerance, "0-30 \(r.zeroToThirty) vs \(t30)")
    }

    @Test(arguments: [0.0, 0.25, 0.5, 0.75])
    func timesARunWhateverTheGPSPhase(phase: Double) throws {
        try check(SyntheticRun(gpsPhase: phase), within: 0.05)
    }

    @Test(arguments: [0.0, 0.6, 1.3])
    func timesARunWhateverTheMount(tilt: Double) throws {
        try check(SyntheticRun(tilt: tilt), within: 0.05)
    }

    @Test(arguments: [0.85, 1.15])
    func theGPSCorrectsAnAccelerometerThatReadsWrong(scale: Double) throws {
        try check(SyntheticRun(scale: scale), within: 0.1)
    }

    @Test(arguments: [UInt64(2), 3, 4, 5])
    func timesARunWhateverTheNoise(seed: UInt64) throws {
        try check(SyntheticRun(seed: seed), within: 0.08)
    }

    @Test func aStandingCarIsStillAndHasNoLaunch() {
        let log = SyntheticRun(launches: false).make().log
        #expect(LaunchDetector.isStill(log.motion, for: 1))
        #expect(LaunchDetector.find(in: log.motion) == nil)
    }

    @Test func aKnockIsNotALaunch() {
        let log = SyntheticRun(bump: true, launches: false).make().log
        #expect(LaunchDetector.find(in: log.motion) == nil)
    }

    @Test func aRunThatNeverReachesSixtyHasNoTime() {
        var log = SyntheticRun().make().log
        log.gps.removeAll { $0.speed >= RunAnalyzer.sixty }
        #expect(RunAnalyzer.analyze(log) == nil)
    }
}
