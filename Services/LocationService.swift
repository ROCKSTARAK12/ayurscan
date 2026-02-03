import Foundation
import CoreLocation
import Combine

class LocationService: NSObject, ObservableObject {
    static let shared = LocationService()
    
    private let locationManager = CLLocationManager()
    
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var locationError: LocationError?
    @Published var isLoading = false
    
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10
        authorizationStatus = locationManager.authorizationStatus
    }
    
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func requestAlwaysPermission() {
        locationManager.requestAlwaysAuthorization()
    }
    
    func startUpdatingLocation() {
        isLoading = true
        locationError = nil
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
        isLoading = false
    }
    
    func getCurrentLocation() {
        isLoading = true
        locationError = nil
        locationManager.requestLocation()
    }
    
    func getCurrentLocationAsync() async throws -> CLLocation {
        return try await withCheckedThrowingContinuation { continuation in
            self.locationContinuation = continuation
            
            DispatchQueue.main.async {
                self.isLoading = true
                self.locationError = nil
                
                switch self.authorizationStatus {
                case .notDetermined:
                    self.locationManager.requestWhenInUseAuthorization()
                case .restricted, .denied:
                    self.locationContinuation?.resume(throwing: LocationError.permissionDenied)
                    self.locationContinuation = nil
                case .authorizedWhenInUse, .authorizedAlways:
                    self.locationManager.requestLocation()
                @unknown default:
                    self.locationContinuation?.resume(throwing: LocationError.unknown)
                    self.locationContinuation = nil
                }
            }
        }
    }
    
    func calculateDistance(from location: CLLocation, to destination: CLLocationCoordinate2D) -> Double {
        let destinationLocation = CLLocation(latitude: destination.latitude, longitude: destination.longitude)
        return location.distance(from: destinationLocation)
    }
    
    func calculateDistance(to coordinate: CLLocationCoordinate2D) -> Double? {
        guard let currentLocation = currentLocation else { return nil }
        return calculateDistance(from: currentLocation, to: coordinate)
    }
    
    var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }
    
    var isLocationServicesEnabled: Bool {
        CLLocationManager.locationServicesEnabled()
    }
}

extension LocationService: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        DispatchQueue.main.async {
            self.currentLocation = location
            self.isLoading = false
            self.locationError = nil
            
            if let continuation = self.locationContinuation {
                continuation.resume(returning: location)
                self.locationContinuation = nil
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.isLoading = false
            
            if let clError = error as? CLError {
                switch clError.code {
                case .denied:
                    self.locationError = .permissionDenied
                case .locationUnknown:
                    self.locationError = .locationUnknown
                case .network:
                    self.locationError = .networkError
                default:
                    self.locationError = .unknown
                }
            } else {
                self.locationError = .unknown
            }
            
            if let continuation = self.locationContinuation {
                continuation.resume(throwing: self.locationError ?? LocationError.unknown)
                self.locationContinuation = nil
            }
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
            
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                if self.locationContinuation != nil {
                    self.locationManager.requestLocation()
                }
            case .denied, .restricted:
                self.locationError = .permissionDenied
                if let continuation = self.locationContinuation {
                    continuation.resume(throwing: LocationError.permissionDenied)
                    self.locationContinuation = nil
                }
            default:
                break
            }
        }
    }
}

enum LocationError: LocalizedError {
    case permissionDenied
    case locationUnknown
    case networkError
    case servicesDisabled
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Location permission denied. Please enable location access in Settings."
        case .locationUnknown:
            return "Unable to determine your location. Please try again."
        case .networkError:
            return "Network error. Please check your internet connection."
        case .servicesDisabled:
            return "Location services are disabled. Please enable them in Settings."
        case .unknown:
            return "An unknown error occurred. Please try again."
        }
    }
}
