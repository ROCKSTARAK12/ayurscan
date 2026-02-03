// Hospital.swift
// Hospital/Clinic Model for Dermatologists & Skin Clinics
// Location: AyurScan/Models/Hospital.swift

import Foundation
import CoreLocation
import SwiftUI

// MARK: - Hospital Model
struct Hospital: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let latitude: Double
    let longitude: Double
    let distance: Double
    let type: String  // "Dermatologist", "Cosmetic", "Hospital", "Clinic", "Specialist"
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
    
    // Simple initializer
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
        self.isOpen24Hours = false
        self.amenities = []
    }
    
    // MARK: - Computed Properties
    
    var formattedDistance: String {
        if distance < 1000 {
            return "\(Int(distance))m"
        } else {
            return String(format: "%.1fkm", distance / 1000)
        }
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var formattedRating: String {
        String(format: "%.1f", rating)
    }
    
    var cleanPhoneNumber: String {
        phone.replacingOccurrences(of: "-", with: "")
             .replacingOccurrences(of: " ", with: "")
             .replacingOccurrences(of: "(", with: "")
             .replacingOccurrences(of: ")", with: "")
    }
    
    var mapsURL: URL? {
        URL(string: "maps://?daddr=\(latitude),\(longitude)")
    }
    
    var phoneURL: URL? {
        URL(string: "tel://\(cleanPhoneNumber)")
    }
    
    // MARK: - Type Properties
    
    var typeIcon: String {
        switch type {
        case "Dermatologist": return "stethoscope"
        case "Cosmetic": return "sparkles"
        case "Hospital": return "building.2.fill"
        case "Clinic": return "cross.case.fill"
        case "Specialist": return "person.badge.shield.checkmark.fill"
        case "Emergency": return "staroflife.fill"
        default: return "cross.circle.fill"
        }
    }
    
    var typeColor: Color {
        switch type {
        case "Dermatologist": return .teal
        case "Cosmetic": return .pink
        case "Hospital": return .blue
        case "Clinic": return .orange
        case "Specialist": return .purple
        case "Emergency": return .red
        default: return .gray
        }
    }
    
    // MARK: - Hashable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Hospital, rhs: Hospital) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Clinic Type Enum
enum ClinicType: String, CaseIterable, Codable {
    case all = "All"
    case dermatologist = "Dermatologist"
    case cosmetic = "Cosmetic"
    case hospital = "Hospital"
    case clinic = "Clinic"
    
    var icon: String {
        switch self {
        case .all: return "square.grid.2x2.fill"
        case .dermatologist: return "stethoscope"
        case .cosmetic: return "sparkles"
        case .hospital: return "building.2.fill"
        case .clinic: return "cross.case.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .all: return .gray
        case .dermatologist: return .teal
        case .cosmetic: return .pink
        case .hospital: return .blue
        case .clinic: return .orange
        }
    }
}
