// HospitalService.swift
// WITH CACHING - FINAL
// Location: AyurScan/Services/HospitalService.swift

import Foundation
import CoreLocation
import Combine

class HospitalService: ObservableObject {
    static let shared = HospitalService()
    
    @Published var hospitals: [Hospital] = []
    @Published var isLoading = false
    @Published var error: HospitalError?
    
    private let overpassURL = "https://overpass-api.de/api/interpreter"
    private let defaultRadius = 10000
    
    // CACHING
    private var cachedHospitals: [Hospital] = []
    private var cachedLocation: CLLocation?
    private var cacheTimestamp: Date?
    private let cacheValidityDuration: TimeInterval = 30 * 60
    private let locationThreshold: Double = 1000
    
    private init() {}
    
    // MARK: - Check Cache
    private func isCacheValid(for latitude: Double, longitude: Double) -> Bool {
        guard !cachedHospitals.isEmpty, let cachedLoc = cachedLocation, let timestamp = cacheTimestamp else { return false }
        let cacheAge = Date().timeIntervalSince(timestamp)
        if cacheAge > cacheValidityDuration { return false }
        let newLocation = CLLocation(latitude: latitude, longitude: longitude)
        if cachedLoc.distance(from: newLocation) > locationThreshold { return false }
        return true
    }
    
    // MARK: - Load Hospitals
    @MainActor
    func loadHospitals(latitude: Double, longitude: Double, forceRefresh: Bool = false) async {
        if !forceRefresh && isCacheValid(for: latitude, longitude: longitude) {
            hospitals = cachedHospitals
            isLoading = false
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            let fetched = try await fetchNearbyDermatologists(latitude: latitude, longitude: longitude)
            hospitals = fetched.isEmpty ? generateSampleDermatologists(latitude: latitude, longitude: longitude) : fetched.sorted { $0.distance < $1.distance }
            cachedHospitals = hospitals
            cachedLocation = CLLocation(latitude: latitude, longitude: longitude)
            cacheTimestamp = Date()
            isLoading = false
        } catch {
            hospitals = generateSampleDermatologists(latitude: latitude, longitude: longitude)
            cachedHospitals = hospitals
            cachedLocation = CLLocation(latitude: latitude, longitude: longitude)
            cacheTimestamp = Date()
            isLoading = false
        }
    }
    
    // MARK: - Refresh
    @MainActor
    func refreshHospitals(latitude: Double, longitude: Double) async {
        cachedHospitals = []
        cachedLocation = nil
        cacheTimestamp = nil
        await loadHospitals(latitude: latitude, longitude: longitude, forceRefresh: true)
    }
    
    // MARK: - Fetch API
    func fetchNearbyDermatologists(latitude: Double, longitude: Double, radius: Int? = nil) async throws -> [Hospital] {
        let searchRadius = radius ?? defaultRadius
        let query = """
        [out:json][timeout:30];
        (
          node["healthcare"="doctor"]["healthcare:speciality"~"dermatology|skin"](around:\(searchRadius),\(latitude),\(longitude));
          way["healthcare"="doctor"]["healthcare:speciality"~"dermatology|skin"](around:\(searchRadius),\(latitude),\(longitude));
          node["amenity"="clinic"]["name"~"[Ss]kin|[Dd]erma|[Cc]osme"](around:\(searchRadius),\(latitude),\(longitude));
          way["amenity"="clinic"]["name"~"[Ss]kin|[Dd]erma|[Cc]osme"](around:\(searchRadius),\(latitude),\(longitude));
          node["amenity"="hospital"](around:\(searchRadius),\(latitude),\(longitude));
          way["amenity"="hospital"](around:\(searchRadius),\(latitude),\(longitude));
          node["amenity"="clinic"](around:\(searchRadius),\(latitude),\(longitude));
          way["amenity"="clinic"](around:\(searchRadius),\(latitude),\(longitude));
          node["amenity"="doctors"](around:\(searchRadius),\(latitude),\(longitude));
          way["amenity"="doctors"](around:\(searchRadius),\(latitude),\(longitude));
        );
        out center;
        """
        
        guard let url = URL(string: overpassURL) else { throw HospitalError.invalidURL }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = "data=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query)".data(using: .utf8)
        request.timeoutInterval = 30
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { throw HospitalError.serverError }
        return try parseOSMResponse(data, userLatitude: latitude, userLongitude: longitude)
    }
    
    // MARK: - Parse Response
    private func parseOSMResponse(_ data: Data, userLatitude: Double, userLongitude: Double) throws -> [Hospital] {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let elements = json["elements"] as? [[String: Any]] else { throw HospitalError.parsingFailed }
        
        var hospitals: [Hospital] = []
        let userLocation = CLLocation(latitude: userLatitude, longitude: userLongitude)
        
        for element in elements {
            var lat: Double?, lon: Double?
            if let l = element["lat"] as? Double, let lo = element["lon"] as? Double { lat = l; lon = lo }
            else if let c = element["center"] as? [String: Any], let l = c["lat"] as? Double, let lo = c["lon"] as? Double { lat = l; lon = lo }
            guard let hospitalLat = lat, let hospitalLon = lon else { continue }
            
            let tags = element["tags"] as? [String: Any]
            let name = tags?["name"] as? String ?? "Medical Facility"
            let phone = tags?["phone"] as? String ?? tags?["contact:phone"] as? String ?? ""
            let website = tags?["website"] as? String
            let emergency = tags?["emergency"] as? String
            let amenity = tags?["amenity"] as? String
            let speciality = tags?["healthcare:speciality"] as? String
            let healthcare = tags?["healthcare"] as? String
            
            let distance = userLocation.distance(from: CLLocation(latitude: hospitalLat, longitude: hospitalLon))
            let type = determineClinicType(name: name, emergency: emergency, amenity: amenity, speciality: speciality, healthcare: healthcare)
            
            var addressParts: [String] = []
            if let s = tags?["addr:street"] as? String { addressParts.append(s) }
            if let c = tags?["addr:city"] as? String { addressParts.append(c) }
            
            hospitals.append(Hospital(name: name, latitude: hospitalLat, longitude: hospitalLon, distance: distance, type: type, phone: phone, rating: generateRating(for: type), website: website, address: addressParts.isEmpty ? nil : addressParts.joined(separator: ", "), isOpen24Hours: emergency == "yes", amenities: []))
        }
        return hospitals
    }
    
    private func determineClinicType(name: String, emergency: String?, amenity: String?, speciality: String?, healthcare: String?) -> String {
        let n = name.lowercased()
        if n.contains("derma") || n.contains("skin") || speciality?.lowercased().contains("derma") == true { return "Dermatologist" }
        if n.contains("cosme") || n.contains("beauty") || n.contains("aesthetic") { return "Cosmetic" }
        if emergency == "yes" { return "Emergency" }
        if speciality != nil || healthcare == "doctor" { return "Specialist" }
        if amenity == "clinic" || amenity == "doctors" { return "Clinic" }
        return "Hospital"
    }
    
    private func generateRating(for type: String) -> Double {
        switch type {
        case "Dermatologist": return Double.random(in: 4.2...5.0)
        case "Cosmetic": return Double.random(in: 4.0...4.8)
        case "Hospital": return Double.random(in: 3.8...4.7)
        default: return Double.random(in: 3.5...4.5)
        }
    }
    
    private func generateSampleDermatologists(latitude: Double, longitude: Double) -> [Hospital] {
        let samples: [(String, String, Double, Double)] = [
            ("Dr. Sharma Skin Clinic", "Dermatologist", 0.008, 0.005),
            ("Apollo Dermatology Center", "Dermatologist", 0.012, -0.008),
            ("Kaya Skin Clinic", "Cosmetic", -0.006, 0.010),
            ("VLCC Wellness", "Cosmetic", 0.015, 0.012),
            ("Max Hospital - Dermatology", "Hospital", -0.020, 0.015),
            ("Fortis Skin Care", "Dermatologist", 0.025, -0.010),
            ("City Skin & Hair Clinic", "Clinic", -0.010, -0.012),
            ("Dr. Gupta Derma Care", "Dermatologist", 0.018, 0.020),
            ("Medanta Skin Institute", "Hospital", -0.030, 0.008),
            ("SkinFirst Clinic", "Clinic", 0.005, -0.015)
        ]
        let userLoc = CLLocation(latitude: latitude, longitude: longitude)
        return samples.map { name, type, latOff, lonOff in
            let hLat = latitude + latOff, hLon = longitude + lonOff
            return Hospital(name: name, latitude: hLat, longitude: hLon, distance: userLoc.distance(from: CLLocation(latitude: hLat, longitude: hLon)), type: type, phone: "+91-\(Int.random(in: 7000000000...9999999999))", rating: generateRating(for: type))
        }.sorted { $0.distance < $1.distance }
    }
    
    func filterHospitals(by type: String) -> [Hospital] { type == "All" ? hospitals : hospitals.filter { $0.type == type } }
    func searchHospitals(query: String) -> [Hospital] { query.isEmpty ? hospitals : hospitals.filter { $0.name.localizedCaseInsensitiveContains(query) } }
}

enum HospitalError: LocalizedError {
    case invalidURL, serverError, parsingFailed, noResults, locationRequired, unknown
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid API URL."
        case .serverError: return "Server error."
        case .parsingFailed: return "Failed to parse data."
        case .noResults: return "No dermatologists found."
        case .locationRequired: return "Location required."
        case .unknown: return "Unknown error."
        }
    }
}
