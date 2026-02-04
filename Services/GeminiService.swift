// GeminiService.swift - FINAL FIXED
// Location: AyurScan/Services/GeminiService.swift

import Foundation
import UIKit
import Combine

class GeminiService: ObservableObject {
    static let shared = GeminiService()
    
    @Published var isAnalyzing = false
    @Published var lastError: String?
    
    private let mistralKey = "hkAp5ETLUCrWVjVC0oM9tOoU6q5yXnYP"
    private let geminiKey = "AIzaSyDNVWqcjyp2TcJb1X8A5qXESjpxE8LdJxE"
    
    private let mistralURL = "https://api.mistral.ai/v1/chat/completions"
    private let geminiURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"
    
    enum AIProvider: String {
        case mistral = "Mistral AI Pixtral"
        case gemini = "Google Gemini"
    }
    
    var primaryProvider: AIProvider = .gemini
    
    // MARK: - Main Analysis Function
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
        
        // ⭐ FIX: Process image consistently for both camera & gallery
        let processedImage = image.preparedForAPIUpload()
        
        switch primaryProvider {
        case .gemini:
            do {
                print("🔮 Trying Gemini...")
                return try await analyzeWithGemini(processedImage)
            } catch {
                print("⚠️ Gemini failed: \(error.localizedDescription)")
                print("🔄 Falling back to Mistral...")
                return try await analyzeWithMistral(processedImage)
            }
        case .mistral:
            do {
                print("🌀 Trying Mistral...")
                return try await analyzeWithMistral(processedImage)
            } catch {
                print("⚠️ Mistral failed: \(error.localizedDescription)")
                print("🔄 Falling back to Gemini...")
                return try await analyzeWithGemini(processedImage)
            }
        }
    }
    
    // MARK: - Mistral Analysis
    private func analyzeWithMistral(_ image: UIImage) async throws -> String {
        guard let base64Image = image.toBase64JPEG() else {
            throw GeminiError.imageProcessingFailed
        }
        
        guard let url = URL(string: mistralURL) else {
            throw GeminiError.invalidURL
        }
        
        let requestBody: [String: Any] = [
            "model": "pixtral-12b-2409",
            "messages": [
                [
                    "role": "system",
                    "content": "You are an expert dermatologist AI assistant specialized in skin analysis."
                ],
                [
                    "role": "user",
                    "content": [
                        ["type": "text", "text": buildPrompt()],
                        ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(base64Image)"]]
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
        request.timeoutInterval = 90
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.invalidResponse
        }
        
        print("🌀 Mistral Status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            throw GeminiError.unknownError(httpResponse.statusCode)
        }
        
        return try parseMistralResponse(data)
    }
    
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
    
    // MARK: - Gemini Analysis
    private func analyzeWithGemini(_ image: UIImage) async throws -> String {
        guard let base64Image = image.toBase64JPEG() else {
            throw GeminiError.imageProcessingFailed
        }
        
        guard let url = URL(string: "\(geminiURL)?key=\(geminiKey)") else {
            throw GeminiError.invalidURL
        }
        
        let requestBody: [String: Any] = [
            "contents": [[
                "parts": [
                    ["text": buildPrompt()],
                    ["inline_data": ["mime_type": "image/jpeg", "data": base64Image]]
                ]
            ]],
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
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 90
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.invalidResponse
        }
        
        print("🔮 Gemini Status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw GeminiError.apiError(message)
            }
            throw GeminiError.unknownError(httpResponse.statusCode)
        }
        
        return try parseGeminiResponse(data)
    }
    
    private func parseGeminiResponse(_ data: Data) throws -> String {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            throw GeminiError.parsingFailed
        }
        return formatFinalResponse(text, provider: .gemini)
    }
    
    // MARK: - Build Prompt
    private func buildPrompt() -> String {
        return """
        You are an expert dermatologist AI. Analyze this skin image and provide a CONCISE, well-formatted report.
        
        Format your response EXACTLY like this:
        
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        📊 SEVERITY: [Healthy/Mild/Moderate/Severe]
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        
        🔍 WHAT I OBSERVED
        • [Observation 1]
        • [Observation 2]
        • [Observation 3]
        
        🩺 POSSIBLE CONDITIONS
        1. [Condition] - [Likelihood %]
           [Brief description]
        2. [Condition] - [Likelihood %]
           [Brief description]
        
        💊 WHAT YOU SHOULD DO
        • [Action 1]
        • [Action 2]
        • [Action 3]
        
        🌿 AYURVEDIC REMEDIES
        
        ▸ [Remedy 1 Name]
          Ingredients: [list]
          How to use: [instructions]
        
        ▸ [Remedy 2 Name]
          Ingredients: [list]
          How to use: [instructions]
        
        ✨ DAILY SKINCARE TIPS
        • [Tip 1]
        • [Tip 2]
        • [Tip 3]
        
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        
        Guidelines:
        - Be CONCISE - no lengthy paragraphs
        - Use Indian Ayurvedic ingredients (Neem, Haldi, Aloe Vera, Chandan, Multani Mitti, Tulsi)
        - If skin is healthy, say so positively
        - End with: "⚠️ Consult a dermatologist for proper diagnosis"
        """
    }
    
    // MARK: - Format Response
    private func formatFinalResponse(_ text: String, provider: AIProvider) -> String {
        return """
        🔬 **AYURSCAN SKIN ANALYSIS REPORT**
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        
        \(text)
        
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        
        ⚕️ **IMPORTANT DISCLAIMER**
        This AI analysis is for informational purposes only 
        and does NOT replace professional medical advice. 
        Always consult a board-certified dermatologist.
        
        🏥 Use "Nearby Hospitals" to find dermatologists near you.
        
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        🤖 Powered by \(provider.rawValue) | AyurScan v1.0
        """
    }
    
    func switchProvider(to provider: AIProvider) {
        self.primaryProvider = provider
    }
}

// MARK: - UIImage Extension for API
extension UIImage {
    /// Prepares image for API upload - fixes orientation, resizes, compresses
    func preparedForAPIUpload(maxDimension: CGFloat = 1024) -> UIImage {
        // Fix orientation
        var img = self
        if imageOrientation != .up {
            UIGraphicsBeginImageContextWithOptions(size, false, scale)
            draw(in: CGRect(origin: .zero, size: size))
            img = UIGraphicsGetImageFromCurrentImageContext() ?? self
            UIGraphicsEndImageContext()
        }
        
        // Resize if needed
        let origSize = img.size
        if origSize.width > maxDimension || origSize.height > maxDimension {
            let ratio = min(maxDimension / origSize.width, maxDimension / origSize.height)
            let newSize = CGSize(width: origSize.width * ratio, height: origSize.height * ratio)
            UIGraphicsBeginImageContextWithOptions(newSize, true, 1.0)
            img.draw(in: CGRect(origin: .zero, size: newSize))
            img = UIGraphicsGetImageFromCurrentImageContext() ?? img
            UIGraphicsEndImageContext()
        }
        
        print("📸 Image ready: \(img.size.width)x\(img.size.height)")
        return img
    }
    
    /// Converts to base64 JPEG string
    func toBase64JPEG(quality: CGFloat = 0.8) -> String? {
        guard let data = self.jpegData(compressionQuality: quality) else { return nil }
        print("📦 Base64 size: \(data.count / 1024) KB")
        return data.base64EncodedString()
    }
}

// MARK: - Errors
enum GeminiError: LocalizedError {
    case imageProcessingFailed, invalidURL, invalidResponse, parsingFailed
    case unauthorized, rateLimited, serverError, unknownError(Int), apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .imageProcessingFailed: return "📷 Failed to process image"
        case .invalidURL: return "🔗 Invalid API URL"
        case .invalidResponse: return "📡 Invalid response"
        case .parsingFailed: return "⚠️ Failed to parse response"
        case .unauthorized: return "🔐 API key invalid"
        case .rateLimited: return "⏳ Rate limited, try again"
        case .serverError: return "🌐 Server error"
        case .unknownError(let code): return "❓ Error \(code)"
        case .apiError(let msg): return "❌ \(msg)"
        }
    }
}
