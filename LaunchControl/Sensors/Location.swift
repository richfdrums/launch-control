import CoreLocation
import Observation

/// How much the GPS can be trusted right now.
enum Signal {
    case none, poor, fair, good
}

/// The GPS: CLLocationManager tuned for driving, its latest fix, and a callback for each one.
@Observable @MainActor
final class Location: NSObject, CLLocationManagerDelegate {
    private(set) var fix: GPSFix?
    private(set) var denied = false
    @ObservationIgnored var onFix: ((GPSFix) -> Void)?
    @ObservationIgnored private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.activityType = .automotiveNavigation
        manager.distanceFilter = kCLDistanceFilterNone
        manager.pausesLocationUpdatesAutomatically = false
    }

    func start() {
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    func stop() { manager.stopUpdatingLocation() }

    /// The speed in mph, nil while the GPS doesn't know it. Under 1 mph reads as 0: a standing
    /// car's GPS wanders.
    var mph: Double? {
        guard let fix, fix.speed >= 0 else { return nil }
        let mph = fix.speed / Units.mph
        return mph < 1 ? 0 : mph
    }

    var signal: Signal {
        guard let fix, fix.horizontalAccuracy >= 0 else { return .none }
        if fix.speedAccuracy < 0 || fix.horizontalAccuracy > 30 { return .poor }
        return fix.horizontalAccuracy <= 10 ? .good : .fair
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let fixes = locations.map {
            GPSFix(t: $0.timestamp.timeIntervalSince1970, speed: $0.speed, speedAccuracy: $0.speedAccuracy,
                   horizontalAccuracy: $0.horizontalAccuracy)
        }
        MainActor.assumeIsolated {
            for f in fixes {
                fix = f
                onFix?(f)
            }
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        MainActor.assumeIsolated { denied = status == .denied || status == .restricted }
    }
}
