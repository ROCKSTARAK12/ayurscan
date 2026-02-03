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
        self.conditionDetected = Self.extractCondition(from: diagnosis)
        self.confidenceScore = Self.extractConfidence(from: diagnosis)
        self.recommendations = Self.extractRecommendations(from: diagnosis)
    }
    
    // MARK: - Computed Properties
    
    var image: UIImage? {
        UIImage(data: imageData)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
    
    var relativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
    
    var smartFormattedDate: String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        
        if calendar.isDateInToday(timestamp) {
            formatter.dateFormat = "'Today at' h:mm a"
        } else if calendar.isDateInYesterday(timestamp) {
            formatter.dateFormat = "'Yesterday at' h:mm a"
        } else if calendar.isDate(timestamp, equalTo: Date(), toGranularity: .weekOfYear) {
            formatter.dateFormat = "EEEE 'at' h:mm a"
        } else if calendar.isDate(timestamp, equalTo: Date(), toGranularity: .year) {
            formatter.dateFormat = "MMM d 'at' h:mm a"
        } else {
            formatter.dateFormat = "MMM d, yyyy"
        }
        
        return formatter.string(from: timestamp)
    }
    
    /// Returns severity from diagnosis
    var severity: String {
        let lower = diagnosis.lowercased()
        if lower.contains("severe") { return "Severe" }
        if lower.contains("moderate") { return "Moderate" }
        if lower.contains("mild") { return "Mild" }
        if lower.contains("healthy") { return "Healthy" }
        return "Unknown"
    }
    
    /// Returns severity color name
    var severityColor: String {
        switch severity {
        case "Healthy": return "green"
        case "Mild": return "yellow"
        case "Moderate": return "orange"
        case "Severe": return "red"
        default: return "gray"
        }
    }
    
    /// Returns title extracted from diagnosis
    var title: String {
        // Try to extract condition name
        if let condition = conditionDetected, !condition.isEmpty {
            return condition
        }
        
        // Try to find severity
        if severity != "Unknown" {
            return "\(severity) Skin Condition"
        }
        
        // Fallback
        return "Skin Analysis"
    }
    
    /// Returns preview text
    var preview: String {
        // Try to extract observed condition summary
        if let observedSection = extractSection(keyword: "OBSERVED") {
            let cleaned = observedSection
                .replacingOccurrences(of: "•", with: "")
                .replacingOccurrences(of: "**", with: "")
                .components(separatedBy: "\n")
                .first?
                .trimmingCharacters(in: .whitespaces) ?? ""
            
            if !cleaned.isEmpty && cleaned.count > 10 {
                return String(cleaned.prefix(100)) + (cleaned.count > 100 ? "..." : "")
            }
        }
        
        // Fallback to first meaningful line
        let lines = diagnosis.components(separatedBy: "\n")
        for line in lines {
            let cleaned = line
                .replacingOccurrences(of: "━", with: "")
                .replacingOccurrences(of: "**", with: "")
                .replacingOccurrences(of: "🔍", with: "")
                .replacingOccurrences(of: "📊", with: "")
                .trimmingCharacters(in: .whitespaces)
            
            if cleaned.count > 20 && !cleaned.contains("SEVERITY") && !cleaned.contains("━") {
                return String(cleaned.prefix(100)) + (cleaned.count > 100 ? "..." : "")
            }
        }
        
        return "Tap to view full analysis"
    }
    
    var confidencePercentage: String? {
        guard let score = confidenceScore else { return nil }
        return String(format: "%.0f%%", score * 100)
    }
    
    /// Checks if diagnosis is valid/complete (updated for new format)
    var isValidDiagnosis: Bool {
        diagnosis.contains("SEVERITY") ||
        diagnosis.contains("OBSERVED") ||
        diagnosis.contains("━━") ||
        diagnosis.contains("AYURVEDIC") ||
        diagnosis.contains("Professional Dermatological Assessment") ||
        diagnosis.count > 100
    }
    
    // MARK: - Section Extraction Helpers
    
    private func extractSection(keyword: String) -> String? {
        let lines = diagnosis.components(separatedBy: "\n")
        var capturing = false
        var content: [String] = []
        
        for line in lines {
            if line.uppercased().contains(keyword) {
                capturing = true
                continue
            }
            
            if capturing {
                // Stop at next section
                if line.contains("━━") || line.uppercased().contains("🔍") ||
                   line.uppercased().contains("🩺") || line.uppercased().contains("💊") ||
                   line.uppercased().contains("🌿") || line.uppercased().contains("✨") ||
                   line.uppercased().contains("📊") {
                    break
                }
                content.append(line)
            }
        }
        
        return content.isEmpty ? nil : content.joined(separator: "\n")
    }
    
    // MARK: - Static Extraction Methods
    
    static func extractCondition(from diagnosis: String) -> String? {
        // Look for condition in POSSIBLE CONDITIONS section
        let lines = diagnosis.components(separatedBy: "\n")
        var inConditionsSection = false
        
        for line in lines {
            if line.uppercased().contains("POSSIBLE CONDITIONS") || line.contains("🩺") {
                inConditionsSection = true
                continue
            }
            
            if inConditionsSection {
                // Look for first condition with percentage
                if line.contains("%") || line.contains("-") {
                    let cleaned = line
                        .replacingOccurrences(of: "1.", with: "")
                        .replacingOccurrences(of: "2.", with: "")
                        .replacingOccurrences(of: "•", with: "")
                        .components(separatedBy: "-")
                        .first?
                        .trimmingCharacters(in: .whitespaces)
                    
                    if let condition = cleaned, !condition.isEmpty, condition.count > 3 {
                        return condition
                    }
                }
                
                // Stop at next section
                if line.contains("━━") || line.contains("💊") || line.contains("🌿") {
                    break
                }
            }
        }
        
        return nil
    }
    
    static func extractConfidence(from diagnosis: String) -> Double? {
        // Extract first percentage from POSSIBLE CONDITIONS
        let pattern = #"(\d+)%"#
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: diagnosis, range: NSRange(diagnosis.startIndex..., in: diagnosis)),
           let range = Range(match.range(at: 1), in: diagnosis),
           let percentage = Int(diagnosis[range]) {
            return Double(percentage) / 100.0
        }
        return nil
    }
    
    static func extractRecommendations(from diagnosis: String) -> [String]? {
        var recommendations: [String] = []
        let lines = diagnosis.components(separatedBy: "\n")
        var inRecommendationsSection = false
        
        for line in lines {
            if line.uppercased().contains("SHOULD DO") || line.uppercased().contains("RECOMMENDED") || line.contains("💊") {
                inRecommendationsSection = true
                continue
            }
            
            if inRecommendationsSection {
                // Stop at next section
                if line.contains("━━") || line.contains("🌿") || line.contains("✨") || line.uppercased().contains("AYURVEDIC") {
                    break
                }
                
                let cleaned = line
                    .replacingOccurrences(of: "•", with: "")
                    .replacingOccurrences(of: "**", with: "")
                    .trimmingCharacters(in: .whitespaces)
                
                if !cleaned.isEmpty && cleaned.count > 5 {
                    recommendations.append(cleaned)
                }
            }
        }
        
        return recommendations.isEmpty ? nil : recommendations
    }
    
    // MARK: - Get Parsed Sections (for UI)
    
    func getParsedSections() -> [ParsedSection] {
        var sections: [ParsedSection] = []
        
        let sectionPatterns: [(icon: String, title: String, colorName: String, keywords: [String])] = [
            ("chart.bar.fill", "Severity", "red", ["SEVERITY", "📊"]),
            ("eye.fill", "What I Observed", "blue", ["OBSERVED", "🔍"]),
            ("stethoscope", "Possible Conditions", "purple", ["POSSIBLE CONDITIONS", "🩺"]),
            ("checklist", "What You Should Do", "green", ["SHOULD DO", "💊", "RECOMMENDED"]),
            ("leaf.fill", "Ayurvedic Remedies", "orange", ["AYURVEDIC", "🌿"]),
            ("sparkles", "Skincare Tips", "pink", ["SKINCARE", "TIPS", "✨"])
        ]
        
        let lines = diagnosis.components(separatedBy: "\n")
        var currentSection: (title: String, icon: String, colorName: String, content: [String])? = nil
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            if trimmedLine.isEmpty || trimmedLine.contains("━━") || trimmedLine.contains("---") {
                continue
            }
            
            var foundSection = false
            for pattern in sectionPatterns {
                if pattern.keywords.contains(where: { trimmedLine.uppercased().contains($0) }) {
                    if let current = currentSection, !current.content.isEmpty {
                        sections.append(ParsedSection(
                            icon: current.icon,
                            title: current.title,
                            colorName: current.colorName,
                            content: current.content
                        ))
                    }
                    currentSection = (pattern.title, pattern.icon, pattern.colorName, [])
                    foundSection = true
                    break
                }
            }
            
            if !foundSection, currentSection != nil {
                let cleanedLine = trimmedLine
                    .replacingOccurrences(of: "•", with: "")
                    .replacingOccurrences(of: "▸", with: "")
                    .replacingOccurrences(of: "**", with: "")
                    .trimmingCharacters(in: .whitespaces)
                
                if !cleanedLine.isEmpty && !cleanedLine.hasPrefix("━") {
                    currentSection?.content.append(cleanedLine)
                }
            }
        }
        
        if let current = currentSection, !current.content.isEmpty {
            sections.append(ParsedSection(
                icon: current.icon,
                title: current.title,
                colorName: current.colorName,
                content: current.content
            ))
        }
        
        return sections
    }
    
    // MARK: - Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: AnalysisHistory, rhs: AnalysisHistory) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Parsed Section Model
struct ParsedSection: Identifiable, Codable, Hashable {
    var id: String { title }
    let icon: String
    let title: String
    let colorName: String
    let content: [String]
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

// MARK: - Sample Analysis History (Updated format)
let sampleAnalysisHistory: [AnalysisHistory] = [
    AnalysisHistory(
        imageData: Data(),
        diagnosis: """
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        📊 SEVERITY: Mild
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        
        🔍 WHAT I OBSERVED
        • Red inflamed papules on cheeks
        • Open comedones on nose area
        • Mild erythema around affected areas
        
        🩺 POSSIBLE CONDITIONS
        1. Acne Vulgaris - 85%
           Common inflammatory skin condition
        2. Rosacea - 10%
           Chronic redness condition
        
        💊 WHAT YOU SHOULD DO
        • Use gentle non-comedogenic cleanser
        • Avoid touching face frequently
        • Consult dermatologist if persists
        
        🌿 AYURVEDIC REMEDIES
        
        ▸ Neem & Haldi Pack
          Ingredients: Neem powder, Haldi, Rose water
          How to use: Mix, apply 15 mins, rinse
        
        ▸ Aloe Vera Gel
          Ingredients: Fresh aloe vera
          How to use: Apply directly overnight
        
        ✨ DAILY SKINCARE TIPS
        • Wash face twice daily
        • Use SPF 30+ sunscreen
        • Stay hydrated
        
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        ⚠️ Consult a dermatologist for proper diagnosis
        """,
        timestamp: Date(),
        conditionDetected: "Acne Vulgaris",
        confidenceScore: 0.85,
        recommendations: ["Use gentle cleanser", "Avoid touching face", "Consult dermatologist"]
    ),
    AnalysisHistory(
        imageData: Data(),
        diagnosis: """
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        📊 SEVERITY: Healthy
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        
        🔍 WHAT I OBSERVED
        • Clear, even skin tone
        • Good hydration levels
        • No visible concerns
        
        🩺 POSSIBLE CONDITIONS
        1. Healthy Skin - 95%
           No treatment needed
        
        💊 WHAT YOU SHOULD DO
        • Continue current routine
        • Maintain hydration
        • Use daily sunscreen
        
        🌿 AYURVEDIC REMEDIES
        
        ▸ Chandan Face Pack
          Ingredients: Sandalwood powder, Rose water
          How to use: Weekly application for glow
        
        ✨ DAILY SKINCARE TIPS
        • Cleanse, tone, moisturize
        • Drink plenty of water
        • Get adequate sleep
        
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        """,
        timestamp: Date().addingTimeInterval(-86400),
        conditionDetected: nil,
        confidenceScore: 0.95,
        recommendations: ["Continue routine", "Stay hydrated", "Use sunscreen"]
    )
]
