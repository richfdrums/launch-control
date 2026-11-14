import CoreMotion
import Foundation

/// The accelerometer: device motion at 100 Hz, as MotionSamples on the GPS's clock.
@MainActor
final class Motion {
    private let manager = CMMotionManager()

    func start(_ handle: @escaping (MotionSample) -> Void) {
        guard manager.isDeviceMotionAvailable, !manager.isDeviceMotionActive else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 100
        // CoreMotion times its readings from boot, the GPS from 1970.
        let offset = Date().timeIntervalSince1970 - ProcessInfo.processInfo.systemUptime
        manager.startDeviceMotionUpdates(to: .main) { motion, _ in
            guard let motion else { return }
            let u = motion.userAcceleration, g = motion.gravity
            let sample = MotionSample(t: motion.timestamp + offset, ax: u.x, ay: u.y, az: u.z,
                                      gx: g.x, gy: g.y, gz: g.z)
            MainActor.assumeIsolated { handle(sample) }
        }
    }

    func stop() { manager.stopDeviceMotionUpdates() }
}
