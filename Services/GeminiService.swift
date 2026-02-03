import Foundation
import UIKit
import Combine

class GeminiService: ObservableObject {
    static let shared = GeminiService()
    
    @Published var isAnalyzing = false
    @Published var lastError: String?
    
    private var apiKey: String {
        UserDefaults.standard.string(forKey: "gemini_api_key") ?? ""
    }
    
    private var selectedModel: String {
        UserDefaults.standard.string(forKey: "selected_model") ?? "gemini-1.5-flash"
    }
    
    private var temperature: Double {
        UserDefaults.standard.double(forKey: "temperature") != 0
            ? UserDefaults.standard.double(forKey: "temperature")
            : 0.7
    }
    
    private var maxTokens: Int {
        let tokens = UserDefaults.standard.integer(forKey: "max_tokens")
        return tokens != 0 ? tokens : 1200
    }
    
    private var baseURL: String {
        "https://generativelanguage.googleapis.com/v1beta/models/\(selectedModel):generateContent"
    }
    
    func analyzeImage(_ image: UIImage) async throws -> String {
        guard !apiKey.isEmpty else {
            throw GeminiError.missingAPIKey
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw GeminiError.imageProcessingFailed
        }
        
        let base64String = imageData.base64EncodedString()
        
        let prompt = """
        You are an experienced dermatologist with 20+ years of clinical practice. Analyze this skin image and provide:

        1. **Clinical Skin Assessment**: Detailed evaluation of skin condition, texture, tone, and overall dermatological health
        2. **Pathological Analysis**: Identify any lesions, discolorations, inflammatory conditions, or abnormal skin manifestations
        3. **Differential Diagnosis**: List possible conditions based on visual findings with confidence levels
        4. **Skin Type Classification**: Determine Fitzpatrick skin type and specific skin characteristics
        5. **Treatment Recommendations**: 
           - Specific topical treatments and active ingredients
           - Skincare regimen with product recommendations
           - Lifestyle modifications
           - Expected treatment timeline and outcomes
        6. **Preventive Measures**: Long-term skin health strategies and risk factor management

        Provide your professional medical opinion with authority and detail.
        """
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt],
                        [
                            "inline_data": [
                                "mime_type": "image/jpeg",
                                "data": base64String
                            ]
                        ]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": temperature,
                "topP": 0.8,
                "maxOutputTokens": maxTokens
            ]
        ]
        
        guard let url = URL(string: "\(baseURL)?key=\(apiKey)") else {
            throw GeminiError.invalidURL
        }
        
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
        
        switch httpResponse.statusCode {
        case 200:
            return try parseResponse(data)
        case 400:
            throw GeminiError.badRequest
        case 401:
            throw GeminiError.unauthorized
        case 403:
            throw GeminiError.forbidden
        case 429:
            throw GeminiError.rateLimited
        case 500...599:
            throw GeminiError.serverError
        default:
            throw GeminiError.unknownError(httpResponse.statusCode)
        }
    }
    
    private func parseResponse(_ data: Data) throws -> String {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw GeminiError.parsingFailed
        }
        
        if let error = json["error"] as? [String: Any],
           let message = error["message"] as? String {
            throw GeminiError.apiError(message)
        }
        
        guard let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            throw GeminiError.parsingFailed
        }
        
        return text
    }
}

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
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "API key not configured. Please add your Gemini API key in Settings."
        case .imageProcessingFailed:
            return "Failed to process the image. Please try again."
        case .invalidURL:
            return "Invalid API URL configuration."
        case .requestCreationFailed:
            return "Failed to create API request."
        case .invalidResponse:
            return "Invalid response from server."
        case .parsingFailed:
            return "Failed to parse API response."
        case .badRequest:
            return "Bad request. Please check image format."
        case .unauthorized:
            return "Invalid API key. Please check your Gemini API key."
        case .forbidden:
            return "Access forbidden. API key may not have required permissions."
        case .rateLimited:
            return "Rate limit exceeded. Please try again later."
        case .serverError:
            return "Server error. Please try again later."
        case .unknownError(let code):
            return "Unknown error occurred. Status code: \(code)"
        case .apiError(let message):
            return "API Error: \(message)"
        }
    }
}
