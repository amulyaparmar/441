
import MapKit
import Observation

@Observable
final class LocManager: NSObject, CLLocationManagerDelegate {
    static let shared = LocManager()
    private let locManager = CLLocationManager()
    var speed: String {
        switch location.speed {
        case 0.5..<5: "walking"
            case 5..<7: "running"
            case 7..<13: "cycling"
            case 13..<90: "driving"
            case 90..<139: "in train"
            case 139..<225: "flying"
            default: "resting"
        }
    }
    private var heading: CLHeading? = nil
    private let compass = ["North", "NE", "East", "SE", "South", "SW", "West", "NW", "North"]
    var compassHeading: String {
        return if let heading {
            compass[Int(round(heading.magneticHeading.truncatingRemainder(dividingBy: 360) / 45))]
        } else {
            "unknown"
        }
    }
    
    override private init() {
        super.init()

        // configure the location manager
        locManager.desiredAccuracy = kCLLocationAccuracyBest
        locManager.delegate = self
    }
    
    private(set) var location = CLLocation()

    func startUpdates() {
        if locManager.authorizationStatus == .notDetermined {
            // ask for user permission if undetermined
            // Be sure to add 'Privacy - Location When In Use Usage Description' to
            // Info.plist, otherwise location read will fail silently,
            // with (lat/lon = 0)
            locManager.requestWhenInUseAuthorization()
        }
    
        Task {
            do {
                for try await update in CLLocationUpdate.liveUpdates() {
                    location = update.location ?? location
                }
            } catch {
                print(error.localizedDescription)
            }
        }
        Task {
            for await newHeading in headings {
                heading = newHeading
            }
        }
    }
    
    @ObservationIgnored var headingStream: ((CLHeading) -> Void)?

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        headingStream?(newHeading)
    }

    var headings: AsyncStream<CLHeading> {
        AsyncStream(bufferingPolicy: .bufferingNewest(1)) { cont in
            headingStream = { cont.yield($0) }
            cont.onTermination = { @Sendable _ in
                self.locManager.stopUpdatingHeading()
            }
            locManager.startUpdatingHeading()
        }
    }
    
    
}
