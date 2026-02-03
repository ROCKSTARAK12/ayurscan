import Foundation
import UIKit
import Combine

class StorageService {
    static let shared = StorageService()
    
    private let historyKey = "analysis_history"
    private let maxHistoryCount = 100
    
    private init() {}
    
    func saveAnalysis(image: UIImage, diagnosis: String) {
        guard let imageData = image.jpegData(compressionQuality: 0.5) else { return }
        
        var history = getHistory()
        
        let newItem = AnalysisHistory(
            imageData: imageData,
            diagnosis: diagnosis
        )
        
        history.insert(newItem, at: 0)
        
        if history.count > maxHistoryCount {
            history = Array(history.prefix(maxHistoryCount))
        }
        
        saveHistory(history)
    }
    
    func saveAnalysis(_ item: AnalysisHistory) {
        var history = getHistory()
        history.insert(item, at: 0)
        
        if history.count > maxHistoryCount {
            history = Array(history.prefix(maxHistoryCount))
        }
        
        saveHistory(history)
    }
    
    func getHistory() -> [AnalysisHistory] {
        guard let data = UserDefaults.standard.data(forKey: historyKey) else {
            return []
        }
        
        do {
            let history = try JSONDecoder().decode([AnalysisHistory].self, from: data)
            return history
        } catch {
            print("Failed to decode history: \(error)")
            return []
        }
    }
    
    func deleteAnalysis(id: UUID) {
        var history = getHistory()
        history.removeAll { $0.id == id }
        saveHistory(history)
    }
    
    func clearHistory() {
        UserDefaults.standard.removeObject(forKey: historyKey)
    }
    
    func getAnalysis(by id: UUID) -> AnalysisHistory? {
        return getHistory().first { $0.id == id }
    }
    
    func updateAnalysis(_ item: AnalysisHistory) {
        var history = getHistory()
        if let index = history.firstIndex(where: { $0.id == item.id }) {
            history[index] = item
            saveHistory(history)
        }
    }
    
    func getHistoryCount() -> Int {
        return getHistory().count
    }
    
    func getRecentAnalyses(limit: Int = 5) -> [AnalysisHistory] {
        return Array(getHistory().prefix(limit))
    }
    
    func searchHistory(query: String) -> [AnalysisHistory] {
        let history = getHistory()
        guard !query.isEmpty else { return history }
        
        return history.filter { item in
            item.diagnosis.localizedCaseInsensitiveContains(query) ||
            (item.conditionDetected?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }
    
    func getHistoryByDateRange(from startDate: Date, to endDate: Date) -> [AnalysisHistory] {
        return getHistory().filter { item in
            item.timestamp >= startDate && item.timestamp <= endDate
        }
    }
    
    func exportHistory() -> Data? {
        let history = getHistory()
        return try? JSONEncoder().encode(history)
    }
    
    func importHistory(from data: Data) -> Bool {
        guard let importedHistory = try? JSONDecoder().decode([AnalysisHistory].self, from: data) else {
            return false
        }
        
        var currentHistory = getHistory()
        let existingIds = Set(currentHistory.map { $0.id })
        
        let newItems = importedHistory.filter { !existingIds.contains($0.id) }
        currentHistory.append(contentsOf: newItems)
        
        currentHistory.sort { $0.timestamp > $1.timestamp }
        
        if currentHistory.count > maxHistoryCount {
            currentHistory = Array(currentHistory.prefix(maxHistoryCount))
        }
        
        saveHistory(currentHistory)
        return true
    }
    
    private func saveHistory(_ history: [AnalysisHistory]) {
        do {
            let data = try JSONEncoder().encode(history)
            UserDefaults.standard.set(data, forKey: historyKey)
        } catch {
            print("Failed to save history: \(error)")
        }
    }
}

extension StorageService {
    
    func saveAPIKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: "gemini_api_key")
    }
    
    func getAPIKey() -> String? {
        return UserDefaults.standard.string(forKey: "gemini_api_key")
    }
    
    func saveSettings(_ settings: [String: Any]) {
        for (key, value) in settings {
            UserDefaults.standard.set(value, forKey: key)
        }
    }
    
    func getSetting<T>(forKey key: String, defaultValue: T) -> T {
        return UserDefaults.standard.object(forKey: key) as? T ?? defaultValue
    }
    
    func removeSetting(forKey key: String) {
        UserDefaults.standard.removeObject(forKey: key)
    }
    
    func resetAllSettings() {
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
    }
}
