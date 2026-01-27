import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject {
    private let manager = CLLocationManager()
    
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isMonitoring = false
    
    private var monitoredRegions: [CLCircularRegion] = []
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = manager.authorizationStatus
    }
    
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }
    
    func requestAlwaysPermission() {
        manager.requestAlwaysAuthorization()
    }
    
    func startUpdatingLocation() {
        manager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        manager.stopUpdatingLocation()
    }
    
    func startMonitoring(location: SavedLocation, identifier: String) {
        let region = CLCircularRegion(
            center: location.coordinate,
            radius: location.radius,
            identifier: identifier
        )
        region.notifyOnEntry = true
        region.notifyOnExit = true
        
        manager.startMonitoring(for: region)
        monitoredRegions.append(region)
        isMonitoring = true
    }
    
    func stopMonitoring(identifier: String) {
        if let region = monitoredRegions.first(where: { $0.identifier == identifier }) {
            manager.stopMonitoring(for: region)
            monitoredRegions.removeAll { $0.identifier == identifier }
        }
        isMonitoring = !monitoredRegions.isEmpty
    }
    
    func stopAllMonitoring() {
        for region in monitoredRegions {
            manager.stopMonitoring(for: region)
        }
        monitoredRegions.removeAll()
        isMonitoring = false
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        NotificationCenter.default.post(
            name: .didEnterRegion,
            object: nil,
            userInfo: ["regionIdentifier": region.identifier]
        )
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        NotificationCenter.default.post(
            name: .didExitRegion,
            object: nil,
            userInfo: ["regionIdentifier": region.identifier]
        )
    }
}

extension Notification.Name {
    static let didEnterRegion = Notification.Name("didEnterRegion")
    static let didExitRegion = Notification.Name("didExitRegion")
}
