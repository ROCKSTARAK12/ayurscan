// AnalysisHistory.swift
// Analysis history model - for storing skin analysis results
// Location: AyurScan/Models/AnalysisHistory.swift

import Foundation
import UIKit

// MARK: - Analysis History Model
struct AnalysisHistory: Identifiable, Codable, Hashable {
    let id: UUID
    let imageData: Data
    let diagnosis: String
    let timestamp: Date
    let conditionDetected: String?
    let confidenceScore: Double?
    let recommendations: [String]?
    
    // MARK: - Full Initializer
    init(
        id: UUID = UUID(),
        imageData: Data,
        diagnosis: String,
        timestamp: Date = Date(),
        conditionDetected: String? = nil,
        confidenceScore: Double? = nil,
        recommendations: [String]? = nil
    ) {
        self.id = id
        self.imageData = imageData
        self.diagnosis = diagnosis
        self.timestamp = timestamp
        self.conditionDetected = conditionDetected
        self.confidenceScore = confidenceScore
        self.recommendations = recommendations
    }
    
    // MARK: - Simple Initializer
    init(imageData: Data, diagnosis: String) {
        self.id = UUID()
        self.imageData = imageData
        self.diagnosis = diagnosis
        self.timestamp = Date()
        self.conditionDetected = nil
        self.confidenceScore = nil
        self.recommendations = nil
    }
    
    // MARK: - Computed Properties
    
    /// Returns UIImage from imageData
    var image: UIImage? {
        UIImage(data: imageData)
    }
    
    /// Returns formatted date string
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
    
    /// Returns relative date string (Today, Yesterday, etc.)
    var relativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
    
    /// Returns smart formatted date
    var smartFormattedDate: String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        
        if calendar.isDateInToday(timestamp) {
            formatter.dateFormat = "'Today at' h:mm a"
        } else if calendar.isDateInYesterday(timestamp) {
            formatter.dateFormat = "'Yesterday at' h:mm a"
        } else if calendar.isDate(timestamp, equalTo: Date(), toGranularity: .weekOfYear) {
            formatter.dateFormat = "EEEE 'at' h:mm a"  // Day name
        } else if calendar.isDate(timestamp, equalTo: Date(), toGranularity: .year) {
            formatter.dateFormat = "MMM d 'at' h:mm a"  // Month day
        } else {
            formatter.dateFormat = "MMM d, yyyy"  // Full date
        }
        
        return formatter.string(from: timestamp)
    }
    
    /// Returns first line of diagnosis as title
    var title: String {
        let lines = diagnosis.components(separatedBy: "\n")
        if let firstLine = lines.first, !firstLine.isEmpty {
            // Clean up emojis and markdown
            return firstLine
                .replacingOccurrences(of: "🩺", with: "")
                .replacingOccurrences(of: "**", with: "")
                .replacingOccurrences(of: "*", with: "")
                .trimmingCharacters(in: .whitespaces)
        }
        return "Skin Analysis"
    }
    
    /// Returns preview text (first 100 characters)
    var preview: String {
        let cleaned = diagnosis
            .replacingOccurrences(of: "🩺", with: "")
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "\n\n", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespaces)
        
        if cleaned.count > 100 {
            return String(cleaned.prefix(100)) + "..."
        }
        return cleaned
    }
    
    /// Returns confidence as percentage string
    var confidencePercentage: String? {
        guard let score = confidenceScore else { return nil }
        return String(format: "%.0f%%", score * 100)
    }
    
    /// Checks if diagnosis is valid/complete
    var isValidDiagnosis: Bool {
        diagnosis.contains("Professional Dermatological Assessment") ||
        diagnosis.contains("Analysis") ||
        diagnosis.count > 100
    }
    
    // MARK: - Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: AnalysisHistory, rhs: AnalysisHistory) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Analysis Status Enum
enum AnalysisStatus: String, Codable {
    case pending = "pending"
    case analyzing = "analyzing"
    case completed = "completed"
    case failed = "failed"
    
    var icon: String {
        switch self {
        case .pending: return "clock"
        case .analyzing: return "brain.head.profile"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .pending: return "orange"
        case .analyzing: return "blue"
        case .completed: return "green"
        case .failed: return "red"
        }
    }
}

// MARK: - Sample Analysis History (For testing/preview)
let sampleAnalysisHistory: [AnalysisHistory] = [
    AnalysisHistory(
        imageData: Data(),  // Empty data for sample
        diagnosis: """
        🩺 **Professional Dermatological Assessment**
        
        **Clinical Skin Assessment:**
        The image shows signs of mild acne with some inflammatory papules and comedones primarily in the T-zone area.
        
        **Recommendations:**
        - Use a gentle, non-comedogenic cleanser twice daily
        - Apply benzoyl peroxide 2.5% to affected areas
        - Consider salicylic acid treatment for blackheads
        - Use oil-free moisturizer and sunscreen
        
        **Follow-up:**
        If no improvement in 6-8 weeks, consult a dermatologist.
        """,
        timestamp: Date(),
        conditionDetected: "Acne",
        confidenceScore: 0.87,
        recommendations: ["Benzoyl Peroxide", "Salicylic Acid", "Non-comedogenic products"]
    ),
    AnalysisHistory(
        imageData: Data(),
        diagnosis: """
        🩺 **Professional Dermatological Assessment**
        
        **Clinical Skin Assessment:**
        The skin appears to show signs of eczema with dry, red, and slightly inflamed patches.
        
        **Recommendations:**
        - Apply fragrance-free moisturizer multiple times daily
        - Use mild, soap-free cleansers
        - Consider hydrocortisone cream for flare-ups
        - Avoid known triggers
        """,
        timestamp: Date().addingTimeInterval(-86400),  // Yesterday
        conditionDetected: "Eczema",
        confidenceScore: 0.92,
        recommendations: ["Moisturizer", "Hydrocortisone", "Avoid triggers"]
    ),
    AnalysisHistory(
        imageData: Data(),
        diagnosis: """
        🩺 **Professional Dermatological Assessment**
        
        **Clinical Skin Assessment:**
        Healthy skin with good hydration levels and even tone. No visible concerns detected.
        
        **Recommendations:**
        - Continue current skincare routine
        - Always use sunscreen SPF 30+
        - Stay hydrated
        """,
        timestamp: Date().addingTimeInterval(-172800),  // 2 days ago
        conditionDetected: nil,
        confidenceScore: 0.95,
        recommendations: ["Sunscreen", "Hydration", "Maintain routine"]
    )
]
