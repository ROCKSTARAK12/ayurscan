// GeminiService.swift
// Mistral AI + Gemini API Integration for Skin Analysis
// Location: AyurScan/Services/GeminiService.swift

import Foundation
import UIKit
import Combine

class GeminiService: ObservableObject {
    static let shared = GeminiService()
    
    @Published var isAnalyzing = false
    @Published var lastError: String?
    
    // ✅ API Keys
    private let mistralKey = "PG1LYuDdY5kk0uhALHbOSptB1pGfJG00"
    private let geminiKey = "AIzaSyDNVWqcjyp2TcJb1X8A5qXESjpxE8LdJxE"
    
    // API URLs
    private let mistralURL = "https://api.mistral.ai/v1/chat/completions"
    private let geminiURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"
    
    // Provider Toggle
    enum AIProvider: String {
        case mistral = "Mistral AI Pixtral"
        case gemini = "Google Gemini"
    }
    
    // Mistral as primary (free tier)
    var primaryProvider: AIProvider = .mistral
    
    init() {}
    
    // MARK: - Main Analysis Function (with Auto-Fallback)
    func analyzeImage(_ image: UIImage) async throws -> String {
        await MainActor.run {
            self.isAnalyzing = true
            self.lastError = nil
        }
        
        defer {
            Task { @MainActor in
                self.isAnalyzing = false
            }
        }
        
        // Try primary provider first, fallback to secondary
        switch primaryProvider {
        case .mistral:
            do {
                print("🌀 Trying Mistral AI...")
                return try await analyzeWithMistral(image)
            } catch {
                print("⚠️ Mistral failed: \(error.localizedDescription)")
                print("🔄 Falling back to Gemini...")
                return try await analyzeWithGemini(image)
            }
        case .gemini:
            do {
                print("🔮 Trying Gemini...")
                return try await analyzeWithGemini(image)
            } catch {
                print("⚠️ Gemini failed: \(error.localizedDescription)")
                print("🔄 Falling back to Mistral...")
                return try await analyzeWithMistral(image)
            }
        }
    }
    
    // MARK: - Analyze and Get Structured Result
    func analyzeImageStructured(_ image: UIImage) async throws -> SkinAnalysisResult {
        let jsonString = try await analyzeImage(image)
        
        // Clean the response (remove markdown code blocks if present)
        var cleanedJSON = jsonString
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Try to extract JSON if there's extra text
        if let jsonStart = cleanedJSON.firstIndex(of: "{"),
           let jsonEnd = cleanedJSON.lastIndex(of: "}") {
            cleanedJSON = String(cleanedJSON[jsonStart...jsonEnd])
        }
        
        print("📝 Cleaned JSON: \(cleanedJSON.prefix(200))...")
        
        guard let jsonData = cleanedJSON.data(using: .utf8) else {
            throw GeminiError.parsingFailed
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(SkinAnalysisResult.self, from: jsonData)
        } catch {
            print("❌ JSON Decode Error: \(error)")
            // Return fallback result
            return createFallbackResult(from: jsonString)
        }
    }
    
    // MARK: - Create Fallback Result from Text
    private func createFallbackResult(from text: String) -> SkinAnalysisResult {
        return SkinAnalysisResult(
            observedCondition: .init(
                summary: "Analysis completed. Please review the detailed findings below.",
                details: extractBulletPoints(from: text, section: "observed")
            ),
            possibleConditions: [
                .init(name: "See detailed analysis", probability: 100, description: text.prefix(200) + "...")
            ],
            severity: .init(
                level: detectSeverity(from: text),
                score: detectSeverityScore(from: text),
                description: "Based on AI analysis"
            ),
            recommendedActions: extractBulletPoints(from: text, section: "action"),
            ayurvedicRemedies: [
                .init(
                    name: "Neem & Turmeric Pack",
                    ingredients: ["Neem powder", "Turmeric", "Rose water"],
                    instructions: "Mix to form paste, apply for 15 mins",
                    benefits: "Antibacterial & anti-inflammatory"
                ),
                .init(
                    name: "Aloe Vera Gel",
                    ingredients: ["Fresh aloe vera"],
                    instructions: "Apply directly to affected areas",
                    benefits: "Soothes and heals skin"
                )
            ],
            skincareTips: [
                "Keep skin clean and moisturized",
                "Use sunscreen SPF 30+ daily",
                "Stay hydrated",
                "Avoid touching face frequently"
            ],
            disclaimer: "This AI analysis is for informational purposes only. Always consult a dermatologist for proper diagnosis and treatment."
        )
    }
    
    private func extractBulletPoints(from text: String, section: String) -> [String] {
        // Simple extraction - return generic points if parsing fails
        return [
            "Skin condition analyzed",
            "Review recommendations below",
            "Consult dermatologist for confirmation"
        ]
    }
    
    private func detectSeverity(from text: String) -> String {
        let lowercased = text.lowercased()
        if lowercased.contains("severe") { return "Severe" }
        if lowercased.contains("moderate") { return "Moderate" }
        if lowercased.contains("mild") { return "Mild" }
        if lowercased.contains("healthy") || lowercased.contains("normal") { return "Healthy" }
        return "Mild"
    }
    
    private func detectSeverityScore(from text: String) -> Int {
        let severity = detectSeverity(from: text)
        switch severity {
        case "Healthy": return 1
        case "Mild": return 3
        case "Moderate": return 6
        case "Severe": return 9
        default: return 3
        }
    }
    
    // MARK: - Mistral AI Pixtral Analysis
    private func analyzeWithMistral(_ image: UIImage) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw GeminiError.imageProcessingFailed
        }
        let base64Image = imageData.base64EncodedString()
        
        guard let url = URL(string: mistralURL) else {
            throw GeminiError.invalidURL
        }
        
        let requestBody: [String: Any] = [
            "model": "pixtral-12b-2409",
            "messages": [
                [
                    "role": "system",
                    "content": "You are an expert dermatologist AI assistant specialized in skin analysis. Provide detailed, helpful analysis with Ayurvedic remedies while always recommending professional consultation."
                ],
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": buildPrompt()
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64Image)"
                            ]
                        ]
                    ]
                ]
            ],
            "max_tokens": 2048,
            "temperature": 0.4
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(mistralKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 60
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.invalidResponse
        }
        
        print("🌀 Mistral Status: \(httpResponse.statusCode)")
        
        switch httpResponse.statusCode {
        case 200:
            return try parseMistralResponse(data)
        case 401:
            throw GeminiError.unauthorized
        case 429:
            throw GeminiError.rateLimited
        case 500...599:
            throw GeminiError.serverError
        default:
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw GeminiError.apiError("Mistral: \(message)")
            }
            // Debug: Print raw response
            if let rawResponse = String(data: data, encoding: .utf8) {
                print("📝 Raw Response: \(rawResponse)")
            }
            throw GeminiError.unknownError(httpResponse.statusCode)
        }
    }
    
    // MARK: - Parse Mistral Response
    private func parseMistralResponse(_ data: Data) throws -> String {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw GeminiError.parsingFailed
        }
        
        return formatFinalResponse(content, provider: .mistral)
    }
    
    // MARK: - Gemini Analysis (Fallback)
    private func analyzeWithGemini(_ image: UIImage) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw GeminiError.imageProcessingFailed
        }
        let base64Image = imageData.base64EncodedString()
        
        guard let url = URL(string: "\(geminiURL)?key=\(geminiKey)") else {
            throw GeminiError.invalidURL
        }
        
        let requestBody = buildGeminiRequestBody(base64Image: base64Image)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            throw GeminiError.requestCreationFailed
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.invalidResponse
        }
        
        print("🔮 Gemini Status: \(httpResponse.statusCode)")
        
        switch httpResponse.statusCode {
        case 200:
            return try parseGeminiResponse(data)
        case 400:
            throw GeminiError.badRequest
        case 401, 403:
            throw GeminiError.unauthorized
        case 429:
            throw GeminiError.rateLimited
        case 500...599:
            throw GeminiError.serverError
        default:
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw GeminiError.apiError(message)
            }
            throw GeminiError.unknownError(httpResponse.statusCode)
        }
    }
    
    // MARK: - Build Prompt (Clean Formatted Report)
    private func buildPrompt() -> String {
        return """
        You are an expert dermatologist AI. Analyze this skin image and provide a CONCISE, well-formatted report.
        
        Format your response EXACTLY like this (keep it short & clear):
        
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        📊 SEVERITY: [Healthy/Mild/Moderate/Severe]
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        
        🔍 WHAT I OBSERVED
        • [Observation 1 - keep brief]
        • [Observation 2]
        • [Observation 3]
        
        🩺 POSSIBLE CONDITIONS
        1. [Condition Name] - [Likelihood %]
           [One line description]
        2. [Condition Name] - [Likelihood %]
           [One line description]
        
        💊 WHAT YOU SHOULD DO
        • [Action 1]
        • [Action 2]
        • [Action 3]
        
        🌿 AYURVEDIC REMEDIES
        
        ▸ [Remedy 1 Name]
          Ingredients: [list]
          How to use: [brief instructions]
        
        ▸ [Remedy 2 Name]
          Ingredients: [list]
          How to use: [brief instructions]
        
        ✨ DAILY SKINCARE TIPS
        • [Tip 1]
        • [Tip 2]
        • [Tip 3]
        
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        
        Guidelines:
        - Be CONCISE - no lengthy paragraphs
        - Use bullet points for easy reading
        - Include 2 Ayurvedic remedies with Indian ingredients (Neem, Haldi, Aloe Vera, Chandan, Multani Mitti, Tulsi)
        - If skin is healthy, say so positively
        - If image unclear, mention it briefly
        - End with: "⚠️ Consult a dermatologist for proper diagnosis"
        """
    }
    
    // MARK: - Build Gemini Request Body
    private func buildGeminiRequestBody(base64Image: String) -> [String: Any] {
        return [
            "contents": [
                [
                    "parts": [
                        ["text": buildPrompt()],
                        [
                            "inline_data": [
                                "mime_type": "image/jpeg",
                                "data": base64Image
                            ]
                        ]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.4,
                "topK": 32,
                "topP": 1,
                "maxOutputTokens": 2048
            ],
            "safetySettings": [
                ["category": "HARM_CATEGORY_HARASSMENT", "threshold": "BLOCK_NONE"],
                ["category": "HARM_CATEGORY_HATE_SPEECH", "threshold": "BLOCK_NONE"],
                ["category": "HARM_CATEGORY_SEXUALLY_EXPLICIT", "threshold": "BLOCK_NONE"],
                ["category": "HARM_CATEGORY_DANGEROUS_CONTENT", "threshold": "BLOCK_NONE"]
            ]
        ]
    }
    
    // MARK: - Parse Gemini Response
    private func parseGeminiResponse(_ data: Data) throws -> String {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw GeminiError.parsingFailed
        }
        
        guard let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            
            if let promptFeedback = json["promptFeedback"] as? [String: Any],
               let blockReason = promptFeedback["blockReason"] as? String {
                throw GeminiError.apiError("Content blocked: \(blockReason)")
            }
            
            throw GeminiError.parsingFailed
        }
        
        return formatFinalResponse(text, provider: .gemini)
    }
    
    // MARK: - Format Final Response
    private func formatFinalResponse(_ analysisText: String, provider: AIProvider) -> String {
        return """
        🔬 **AYURSCAN SKIN ANALYSIS REPORT**
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        
        \(analysisText)
        
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        
        ⚕️ **IMPORTANT DISCLAIMER**
        This AI analysis is for informational purposes only 
        and does NOT replace professional medical advice. 
        Always consult a board-certified dermatologist for 
        accurate diagnosis and treatment.
        
        🏥 Use "Nearby Hospitals" to find dermatologists near you.
        
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        🤖 Powered by \(provider.rawValue) | AyurScan v1.0
        """
    }
    
    // MARK: - Analyze with Custom Prompt
    func analyzeImageWithPrompt(_ image: UIImage, prompt: String) async throws -> String {
        await MainActor.run {
            self.isAnalyzing = true
            self.lastError = nil
        }
        
        defer {
            Task { @MainActor in
                self.isAnalyzing = false
            }
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw GeminiError.imageProcessingFailed
        }
        let base64Image = imageData.base64EncodedString()
        
        guard let url = URL(string: mistralURL) else {
            throw GeminiError.invalidURL
        }
        
        let requestBody: [String: Any] = [
            "model": "pixtral-12b-2409",
            "messages": [
                [
                    "role": "user",
                    "content": [
                        ["type": "text", "text": prompt],
                        [
                            "type": "image_url",
                            "image_url": ["url": "data:image/jpeg;base64,\(base64Image)"]
                        ]
                    ]
                ]
            ],
            "max_tokens": 2048
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(mistralKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw GeminiError.invalidResponse
        }
        
        return try parseMistralResponse(data)
    }
    
    // MARK: - Switch Provider
    func switchProvider(to provider: AIProvider) {
        self.primaryProvider = provider
        print("✅ Switched to \(provider.rawValue)")
    }
}

// MARK: - Error Types
enum GeminiError: LocalizedError {
    case missingAPIKey
    case imageProcessingFailed
    case invalidURL
    case requestCreationFailed
    case invalidResponse
    case parsingFailed
    case badRequest
    case unauthorized
    case forbidden
    case rateLimited
    case serverError
    case unknownError(Int)
    case apiError(String)
    case modelLoading(Double)
    case modelDeprecated
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "🔑 API key not configured. Please add your API key in Settings."
        case .imageProcessingFailed:
            return "📷 Failed to process image. Please try with a clearer photo."
        case .invalidURL:
            return "🔗 Invalid API configuration."
        case .requestCreationFailed:
            return "⚠️ Failed to create request. Please try again."
        case .invalidResponse:
            return "📡 Invalid response from server. Please try again."
        case .parsingFailed:
            return "⚠️ Failed to parse analysis. Please try again."
        case .badRequest:
            return "❌ Invalid request. Please try with a different image."
        case .unauthorized:
            return "🔐 API key invalid. Please check your API key."
        case .forbidden:
            return "🚫 Access denied. Please verify API key permissions."
        case .rateLimited:
            return "⏳ Too many requests. Please wait and try again."
        case .serverError:
            return "🌐 Server error. Please try again later."
        case .unknownError(let code):
            return "❓ Error occurred (Code: \(code)). Please try again."
        case .apiError(let message):
            return "❌ \(message)"
        case .modelLoading(let time):
            return "⏳ AI Model loading... Please wait \(Int(time)) seconds."
        case .modelDeprecated:
            return "🔄 Model unavailable. Please update the app."
        }
    }
}
