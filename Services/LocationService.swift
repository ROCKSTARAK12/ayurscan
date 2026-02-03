// LocationService.swift
// Location Service with Permission Handling
// Location: AyurScan/Services/LocationService.swift

import Foundation
import CoreLocation
import Combine

class LocationService: NSObject, ObservableObject {
    static let shared = LocationService()
    
    private let locationManager = CLLocationManager()
    
    @Published var currentLocation: CLLocation?
    @Published var currentCity: String = "Locating..."
    @Published var currentAddress: String = ""
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var locationError: LocationError?
    @Published var isLoading = false
    
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?
    private let geocoder = CLGeocoder()
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 50
        authorizationStatus = locationManager.authorizationStatus
    }
    
    // MARK: - Permission Methods
    
    func requestPermission() {
        DispatchQueue.main.async {
            switch self.authorizationStatus {
            case .notDetermined:
                self.locationManager.requestWhenInUseAuthorization()
            case .authorizedWhenInUse, .authorizedAlways:
                self.startUpdatingLocation()
            case .denied, .restricted:
                self.locationError = .permissionDenied
            @unknown default:
                break
            }
        }
    }
    
    func requestAlwaysPermission() {
        locationManager.requestAlwaysAuthorization()
    }
    
    // MARK: - Location Updates
    
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
        
        guard isAuthorized else {
            requestPermission()
            return
        }
        
        locationManager.requestLocation()
    }
    
    // MARK: - Async Location
    
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
    
    // MARK: - Reverse Geocoding
    
    func reverseGeocode(location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                if let placemark = placemarks?.first {
                    self?.currentCity = placemark.locality ?? placemark.subAdministrativeArea ?? "Unknown"
                    
                    var addressParts: [String] = []
                    if let subLocality = placemark.subLocality { addressParts.append(subLocality) }
                    if let locality = placemark.locality { addressParts.append(locality) }
                    if let state = placemark.administrativeArea { addressParts.append(state) }
                    
                    self?.currentAddress = addressParts.joined(separator: ", ")
                }
            }
        }
    }
    
    // MARK: - Distance Calculation
    
    func calculateDistance(from location: CLLocation, to destination: CLLocationCoordinate2D) -> Double {
        let destinationLocation = CLLocation(latitude: destination.latitude, longitude: destination.longitude)
        return location.distance(from: destinationLocation)
    }
    
    func calculateDistance(to coordinate: CLLocationCoordinate2D) -> Double? {
        guard let currentLocation = currentLocation else { return nil }
        return calculateDistance(from: currentLocation, to: coordinate)
    }
    
    // MARK: - Computed Properties
    
    var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }
    
    var isLocationServicesEnabled: Bool {
        CLLocationManager.locationServicesEnabled()
    }
    
    var statusMessage: String {
        switch authorizationStatus {
        case .notDetermined:
            return "Location permission required"
        case .restricted:
            return "Location restricted"
        case .denied:
            return "Location denied - Enable in Settings"
        case .authorizedWhenInUse, .authorizedAlways:
            return currentCity
        @unknown default:
            return "Unknown status"
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        DispatchQueue.main.async {
            self.currentLocation = location
            self.isLoading = false
            self.locationError = nil
            
            // Reverse geocode to get city name
            self.reverseGeocode(location: location)
            
            // Resume continuation if waiting
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
                // Auto-start location updates when authorized
                self.startUpdatingLocation()
                
                if self.locationContinuation != nil {
                    self.locationManager.requestLocation()
                }
            case .denied, .restricted:
                self.locationError = .permissionDenied
                self.currentCity = "Location Disabled"
                
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

// MARK: - Location Error
enum LocationError: LocalizedError {
    case permissionDenied
    case locationUnknown
    case networkError
    case servicesDisabled
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Location permission denied. Please enable location access in Settings to find nearby dermatologists."
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
    
    var icon: String {
        switch self {
        case .permissionDenied: return "location.slash.fill"
        case .locationUnknown: return "questionmark.circle.fill"
        case .networkError: return "wifi.slash"
        case .servicesDisabled: return "location.slash.fill"
        case .unknown: return "exclamationmark.triangle.fill"
        }
    }
}
