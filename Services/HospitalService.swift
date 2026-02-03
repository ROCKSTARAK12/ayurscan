import Foundation
import CoreLocation
import Combine

class HospitalService: ObservableObject {
    static let shared = HospitalService()
    
    @Published var hospitals: [Hospital] = []
    @Published var isLoading = false
    @Published var error: HospitalError?
    
    private let overpassURL = "https://overpass-api.de/api/interpreter"
    private let defaultRadius = 5000
    
    private init() {}
    
    func fetchNearbyHospitals(latitude: Double, longitude: Double, radius: Int? = nil) async throws -> [Hospital] {
        let searchRadius = radius ?? defaultRadius
        
        let query = """
        [out:json][timeout:25];
        (
          node["amenity"="hospital"](around:\(searchRadius),\(latitude),\(longitude));
          way["amenity"="hospital"](around:\(searchRadius),\(latitude),\(longitude));
          relation["amenity"="hospital"](around:\(searchRadius),\(latitude),\(longitude));
          node["amenity"="clinic"](around:\(searchRadius),\(latitude),\(longitude));
          way["amenity"="clinic"](around:\(searchRadius),\(latitude),\(longitude));
        );
        out center;
        """
        
        guard let url = URL(string: overpassURL) else {
            throw HospitalError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = "data=\(query)".data(using: .utf8)
        request.timeoutInterval = 30
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw HospitalError.serverError
        }
        
        return try parseOSMResponse(data, userLatitude: latitude, userLongitude: longitude)
    }
    
    func fetchHospitals(for location: CLLocation, radius: Int? = nil) async throws -> [Hospital] {
        return try await fetchNearbyHospitals(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            radius: radius
        )
    }
    
    @MainActor
    func loadHospitals(latitude: Double, longitude: Double) async {
        isLoading = true
        error = nil
        
        do {
            let fetchedHospitals = try await fetchNearbyHospitals(latitude: latitude, longitude: longitude)
            hospitals = fetchedHospitals.sorted { $0.distance < $1.distance }
            isLoading = false
        } catch let hospitalError as HospitalError {
            error = hospitalError
            isLoading = false
        } catch {
            self.error = .unknown
            isLoading = false
        }
    }
    
    private func parseOSMResponse(_ data: Data, userLatitude: Double, userLongitude: Double) throws -> [Hospital] {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let elements = json["elements"] as? [[String: Any]] else {
            throw HospitalError.parsingFailed
        }
        
        var hospitals: [Hospital] = []
        let userLocation = CLLocation(latitude: userLatitude, longitude: userLongitude)
        
        for element in elements {
            var hospitalLat: Double?
            var hospitalLon: Double?
            
            if let lat = element["lat"] as? Double, let lon = element["lon"] as? Double {
                hospitalLat = lat
                hospitalLon = lon
            } else if let center = element["center"] as? [String: Any],
                      let lat = center["lat"] as? Double,
                      let lon = center["lon"] as? Double {
                hospitalLat = lat
                hospitalLon = lon
            }
            
            guard let lat = hospitalLat, let lon = hospitalLon else { continue }
            
            let tags = element["tags"] as? [String: Any]
            let name = tags?["name"] as? String ?? "Unnamed Medical Facility"
            let phone = tags?["phone"] as? String ?? ""
            let website = tags?["website"] as? String
            let emergency = tags?["emergency"] as? String
            let amenity = tags?["amenity"] as? String
            let speciality = tags?["healthcare:speciality"] as? String
            
            let hospitalLocation = CLLocation(latitude: lat, longitude: lon)
            let distance = userLocation.distance(from: hospitalLocation)
            
            let type = determineHospitalType(emergency: emergency, amenity: amenity, speciality: speciality)
            let rating = generateRating()
            
            let hospital = Hospital(
                name: name,
                latitude: lat,
                longitude: lon,
                distance: distance,
                type: type,
                phone: phone,
                rating: rating
            )
            
            hospitals.append(hospital)
        }
        
        return hospitals
    }
    
    private func determineHospitalType(emergency: String?, amenity: String?, speciality: String?) -> String {
        if emergency == "yes" {
            return "Emergency"
        }
        if speciality != nil {
            return "Specialty"
        }
        if amenity == "clinic" {
            return "Clinic"
        }
        return "General"
    }
    
    private func generateRating() -> Double {
        return Double.random(in: 3.5...5.0)
    }
    
    func filterHospitals(by type: String) -> [Hospital] {
        guard type != "All" else { return hospitals }
        return hospitals.filter { $0.type == type }
    }
    
    func searchHospitals(query: String) -> [Hospital] {
        guard !query.isEmpty else { return hospitals }
        return hospitals.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }
    
    func filterAndSearch(type: String, query: String) -> [Hospital] {
        var result = hospitals
        
        if type != "All" {
            result = result.filter { $0.type == type }
        }
        
        if !query.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(query) }
        }
        
        return result.sorted { $0.distance < $1.distance }
    }
    
    func getNearestHospital() -> Hospital? {
        return hospitals.min { $0.distance < $1.distance }
    }
    
    func getNearestEmergency() -> Hospital? {
        return hospitals.filter { $0.type == "Emergency" }.min { $0.distance < $1.distance }
    }
    
    func getHospitalsWithinRadius(_ radius: Double) -> [Hospital] {
        return hospitals.filter { $0.distance <= radius }
    }
}

enum HospitalError: LocalizedError {
    case invalidURL
    case serverError
    case parsingFailed
    case noResults
    case locationRequired
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL."
        case .serverError:
            return "Server error. Please try again later."
        case .parsingFailed:
            return "Failed to parse hospital data."
        case .noResults:
            return "No hospitals found nearby."
        case .locationRequired:
            return "Location is required to find nearby hospitals."
        case .unknown:
            return "An unknown error occurred."
        }
    }
}
