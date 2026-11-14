import Foundation
import Observation
import simd

/// A 0–60 run, from arming to the result: waits for the car to stand still with a good GPS
/// fix, spots the launch on the accelerometer, follows the speed to 60, then times the run from
/// its log (RunAnalyzer) and keeps it (History).
@Observable @MainActor
final class RunController {
    enum State: Equatable {
        case idle
        case arming(String)  // why it isn't ready yet
        case ready
        case running(start: Double)  // seconds since 1970, the motion samples' clock
        case finished(RunRecord, best: Bool)
        case aborted(String)
    }

    private(set) var state = State.idle
    /// The speed during a run (m/s): the accelerometer's, pinned to the latest GPS fix.
    private(set) var liveSpeed = 0.0

    @ObservationIgnored private let location: Location
    @ObservationIgnored private let history: History
    @ObservationIgnored private let voice = Voice()
    @ObservationIgnored private let motion = Motion()
    @ObservationIgnored private var samples: [MotionSample] = []
    @ObservationIgnored private var fixes: [GPSFix] = []
    @ObservationIgnored private var launch: Launch?
    @ObservationIgnored private var integrated = 0.0  // the accelerometer's speed since the launch
    @ObservationIgnored private var lastA = 0.0
    @ObservationIgnored private var pin = 0.0  // the latest fix's correction to `integrated`
    @ObservationIgnored private var topSpeed = 0.0

    static let preroll = 3.0  // s of samples kept before a launch
    static let timeout = 20.0

    init(location: Location, history: History) {
        self.location = location
        self.history = history
        location.onFix = { [weak self] in self?.add($0) }
    }

    func arm() {
        samples = []
        fixes = []
        launch = nil
        state = .arming("Hold still")
        motion.start { [weak self] in self?.add($0) }
    }

    func cancel() {
        motion.stop()
        state = .idle
    }

    private func add(_ s: MotionSample) {
        samples.append(s)
        switch state {
        case .arming:
            trim(before: s.t - Self.preroll)
            if let why = notReady(at: s.t) {
                if state != .arming(why) { state = .arming(why) }
            } else {
                trim(before: s.t - 1)  // forget anything before the stillness
                state = .ready
                voice.say("Ready")
            }
        case .ready:
            trim(before: s.t - Self.preroll)
            if let l = LaunchDetector.find(in: samples) {
                begin(l)
            } else if let why = gpsNotReady(at: s.t) {
                state = .arming(why)
            }
        case .running(let start):
            guard let launch else { return }
            let a = dot(s.horizontal, launch.forward) - launch.bias
            integrated += (a + lastA) / 2 * (s.t - samples[samples.count - 2].t)
            lastA = a
            liveSpeed = max(0, integrated + pin)
            if s.t - start > Self.timeout {
                abort("Over 20 seconds, so no time")
            } else if s.t - start > 3, topSpeed < 3 * Units.mph {
                self.launch = nil  // a knock, not a launch: wait again
                state = .arming("Hold still")
            }
        default:
            break
        }
    }

    private func add(_ f: GPSFix) {
        fixes.append(f)
        guard case .running = state else {
            fixes.removeAll { $0.t < f.t - Self.preroll }
            return
        }
        guard f.speed >= 0 else { return }
        pin = f.speed - integrated
        topSpeed = max(topSpeed, f.speed)
        if f.speed >= RunAnalyzer.sixty {
            finish()
        } else if topSpeed - f.speed > 5 * Units.mph {
            abort("You slowed before 60")
        }
    }

    private func begin(_ l: Launch) {
        launch = l
        integrated = 0
        lastA = 0
        pin = 0
        topSpeed = 0
        var prev = l.start
        for s in samples where s.t > l.start {
            let a = dot(s.horizontal, l.forward) - l.bias
            integrated += (a + lastA) / 2 * (s.t - prev)
            lastA = a
            prev = s.t
        }
        liveSpeed = integrated
        state = .running(start: l.start)
    }

    private func finish() {
        motion.stop()
        let log = RunLog(id: UUID(), date: Date(), motion: samples, gps: fixes)
        guard let result = RunAnalyzer.analyze(log) else { abort("Couldn't time that run"); return }
        let (record, best) = history.add(log, result)
        state = .finished(record, best: best)
        voice.say(String(format: "%.2f seconds", result.zeroToSixty) + (best ? ". New best!" : ""))
    }

    private func abort(_ why: String) {
        motion.stop()
        state = .aborted(why)
    }

    private func trim(before t: Double) {
        if let i = samples.firstIndex(where: { $0.t >= t }), i > 0 { samples.removeFirst(i) }
    }

    private func gpsNotReady(at t: Double) -> String? {
        guard let fix = location.fix, fix.horizontalAccuracy >= 0, fix.horizontalAccuracy <= 20, t - fix.t < 3
        else { return "Waiting for GPS" }
        return fix.speed > 1 * Units.mph ? "Stop the car" : nil
    }

    private func notReady(at t: Double) -> String? {
        gpsNotReady(at: t) ?? (LaunchDetector.isStill(samples, for: 1) ? nil : "Hold still")
    }
}
