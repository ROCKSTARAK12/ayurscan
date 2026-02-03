// Hospital.swift
// Hospital model - equivalent to hospital data in nearby_hospitals_screen.dart
// Location: AyurScan/Models/Hospital.swift

import Foundation
import CoreLocation

// MARK: - Hospital Model
struct Hospital: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let latitude: Double
    let longitude: Double
    let distance: Double  // in meters
    let type: String      // "General", "Emergency", "Clinic", "Specialty"
    let phone: String
    let rating: Double
    let website: String?
    let address: String?
    let isOpen24Hours: Bool
    let amenities: [String]
    
    // Full initializer
    init(
        id: UUID = UUID(),
        name: String,
        latitude: Double,
        longitude: Double,
        distance: Double,
        type: String,
        phone: String,
        rating: Double,
        website: String? = nil,
        address: String? = nil,
        isOpen24Hours: Bool = false,
        amenities: [String] = []
    ) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.distance = distance
        self.type = type
        self.phone = phone
        self.rating = rating
        self.website = website
        self.address = address
        self.isOpen24Hours = isOpen24Hours
        self.amenities = amenities
    }
    
    // Simple initializer (for quick creation)
    init(
        name: String,
        latitude: Double,
        longitude: Double,
        distance: Double,
        type: String,
        phone: String,
        rating: Double
    ) {
        self.id = UUID()
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.distance = distance
        self.type = type
        self.phone = phone
        self.rating = rating
        self.website = nil
        self.address = nil
        self.isOpen24Hours = type == "Emergency"
        self.amenities = []
    }
    
    // MARK: - Computed Properties
    
    /// Returns formatted distance string
    var formattedDistance: String {
        if distance < 1000 {
            return "\(Int(distance))m"
        } else {
            return String(format: "%.1fkm", distance / 1000)
        }
    }
    
    /// Returns CLLocationCoordinate2D for MapKit
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    /// Returns formatted rating string
    var formattedRating: String {
        String(format: "%.1f", rating)
    }
    
    /// Returns phone number without formatting (for calling)
    var cleanPhoneNumber: String {
        phone.replacingOccurrences(of: "-", with: "")
             .replacingOccurrences(of: " ", with: "")
             .replacingOccurrences(of: "(", with: "")
             .replacingOccurrences(of: ")", with: "")
    }
    
    /// Returns Maps URL for directions
    var mapsURL: URL? {
        URL(string: "maps://?daddr=\(latitude),\(longitude)")
    }
    
    /// Returns tel URL for calling
    var phoneURL: URL? {
        URL(string: "tel://\(cleanPhoneNumber)")
    }
    
    // MARK: - Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Hospital, rhs: Hospital) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Hospital Type Enum (Optional - for type safety)
enum HospitalType: String, CaseIterable, Codable {
    case general = "General"
    case emergency = "Emergency"
    case clinic = "Clinic"
    case specialty = "Specialty"
    
    var icon: String {
        switch self {
        case .general: return "building.2.fill"
        case .emergency: return "staroflife.fill"
        case .clinic: return "cross.case.fill"
        case .specialty: return "heart.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .general: return "blue"
        case .emergency: return "red"
        case .clinic: return "orange"
        case .specialty: return "purple"
        }
    }
}

// MARK: - OSM Response Models (For parsing Overpass API)
struct OSMResponse: Codable {
    let elements: [OSMElement]
}

struct OSMElement: Codable {
    let id: Int
    let lat: Double?
    let lon: Double?
    let center: OSMCenter?
    let tags: OSMTags?
}

struct OSMCenter: Codable {
    let lat: Double
    let lon: Double
}

struct OSMTags: Codable {
    let name: String?
    let phone: String?
    let website: String?
    let emergency: String?
    let amenity: String?
    let healthcareSpeciality: String?
    let openingHours: String?
    let addressStreet: String?
    let addressCity: String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case phone
        case website
        case emergency
        case amenity
        case healthcareSpeciality = "healthcare:speciality"
        case openingHours = "opening_hours"
        case addressStreet = "addr:street"
        case addressCity = "addr:city"
    }
}

// MARK: - Sample Hospitals Data (For testing)
let sampleHospitals: [Hospital] = [
    Hospital(
        name: "Apollo Hospital",
        latitude: 28.5672,
        longitude: 77.2100,
        distance: 850,
        type: "General",
        phone: "+91-11-2692-5858",
        rating: 4.6
    ),
    Hospital(
        name: "Max Emergency Care",
        latitude: 28.5680,
        longitude: 77.2105,
        distance: 1200,
        type: "Emergency",
        phone: "+91-11-2651-5050",
        rating: 4.8
    ),
    Hospital(
        name: "Fortis Heart Institute",
        latitude: 28.5690,
        longitude: 77.2110,
        distance: 2100,
        type: "Specialty",
        phone: "+91-11-4277-6222",
        rating: 4.7
    ),
    Hospital(
        name: "City Clinic",
        latitude: 28.5700,
        longitude: 77.2115,
        distance: 650,
        type: "Clinic",
        phone: "+91-11-2345-6789",
        rating: 4.2
    ),
    Hospital(
        name: "AIIMS Emergency",
        latitude: 28.5710,
        longitude: 77.2120,
        distance: 3500,
        type: "Emergency",
        phone: "+91-11-2658-8500",
        rating: 4.9
    ),
    Hospital(
        name: "Medanta Hospital",
        latitude: 28.5720,
        longitude: 77.2125,
        distance: 4200,
        type: "General",
        phone: "+91-124-4141-414",
        rating: 4.5
    ),
    Hospital(
        name: "BLK Super Speciality",
        latitude: 28.5730,
        longitude: 77.2130,
        distance: 2800,
        type: "Specialty",
        phone: "+91-11-3040-3040",
        rating: 4.4
    )
]
