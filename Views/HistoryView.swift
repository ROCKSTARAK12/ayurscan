// HistoryView.swift
// Analysis history screen
// Location: AyurScan/Views/HistoryView.swift

import SwiftUI
import Combine

struct HistoryView: View {
    @State private var history: [AnalysisHistory] = []
    @State private var isLoading = true
    @State private var selectedItem: AnalysisHistory?
    @State private var showDeleteAlert = false
    @State private var itemToDelete: AnalysisHistory?
    @State private var showClearAllAlert = false
    @State private var animateList = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.blue.opacity(0.05), Color.white],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                if isLoading {
                    loadingView
                } else if history.isEmpty {
                    emptyStateView
                } else {
                    historyListView
                }
            }
            .navigationTitle("🩺 Analysis History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !history.isEmpty {
                        Button(action: { showClearAllAlert = true }) {
                            Image(systemName: "trash")
                                .font(.system(size: 16))
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .sheet(item: $selectedItem) { item in
                HistoryDetailSheet(item: item)
            }
            .alert("Delete Analysis", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let item = itemToDelete { deleteItem(item) }
                }
            } message: {
                Text("Are you sure you want to delete this analysis?")
            }
            .alert("Clear All History", isPresented: $showClearAllAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Clear All", role: .destructive) { clearAllHistory() }
            } message: {
                Text("Are you sure you want to delete all analysis history?")
            }
        }
        .onAppear { loadHistory() }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView().scaleEffect(1.3)
            Text("Loading history...")
                .font(.system(size: 15))
                .foregroundColor(.secondary)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 120, height: 120)
                Image(systemName: "clock.badge.questionmark")
                    .font(.system(size: 50))
                    .foregroundColor(.blue.opacity(0.6))
            }
            VStack(spacing: 10) {
                Text("No Analysis History")
                    .font(.system(size: 22, weight: .semibold))
                Text("Your skin analysis history will appear here.\nStart by analyzing a skin image!")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            NavigationLink(destination: HomeView()) {
                HStack(spacing: 10) {
                    Image(systemName: "camera.fill")
                    Text("Start Analysis")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
                .cornerRadius(14)
            }
            Spacer()
        }
        .padding(20)
    }
    
    private var historyListView: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 14) {
                HStack {
                    Text("\(history.count) analyses")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Tap to view details")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 8)
                
                ForEach(Array(history.enumerated()), id: \.element.id) { index, item in
                    HistoryCard(item: item)
                        .onTapGesture {
                            selectedItem = item
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                itemToDelete = item
                                showDeleteAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            Button { shareAnalysis(item) } label: {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                        }
                        .opacity(animateList ? 1 : 0)
                        .offset(y: animateList ? 0 : 20)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(Double(index) * 0.05), value: animateList)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .padding(.bottom, 80)
        }
    }
    
    private func loadHistory() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            history = StorageService.shared.getHistory()
            isLoading = false
            withAnimation(.easeOut(duration: 0.3)) { animateList = true }
        }
    }
    
    private func deleteItem(_ item: AnalysisHistory) {
        withAnimation(.spring()) { history.removeAll { $0.id == item.id } }
        StorageService.shared.deleteAnalysis(id: item.id)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    
    private func clearAllHistory() {
        withAnimation(.spring()) { history.removeAll() }
        StorageService.shared.clearHistory()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    
    private func shareAnalysis(_ item: AnalysisHistory) {
        let text = "AyurScan Analysis:\n\n\(item.diagnosis)"
        let activityController = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            rootViewController.present(activityController, animated: true)
        }
    }
}

// MARK: - History Card Component
struct HistoryCard: View {
    let item: AnalysisHistory
    
    var body: some View {
        HStack(spacing: 14) {
            // Thumbnail
            if let uiImage = UIImage(data: item.imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 70, height: 70)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            } else {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 70, height: 70)
                    .overlay(Image(systemName: "photo").foregroundColor(.gray))
            }
            
            VStack(alignment: .leading, spacing: 6) {
                // Severity Badge + Title
                HStack(spacing: 8) {
                    SeverityBadge(severity: item.severity)
                    Text(item.title)
                        .font(.system(size: 15, weight: .semibold))
                        .lineLimit(1)
                }
                
                Text(item.preview)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack(spacing: 6) {
                    Image(systemName: "clock").font(.system(size: 10))
                    Text(item.smartFormattedDate).font(.system(size: 11))
                }
                .foregroundColor(.secondary.opacity(0.8))
            }
            
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Severity Badge
struct SeverityBadge: View {
    let severity: String
    
    var body: some View {
        Text(severity)
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(severityColor)
            .cornerRadius(6)
    }
    
    private var severityColor: Color {
        switch severity.lowercased() {
        case "healthy": return .green
        case "mild": return .yellow
        case "moderate": return .orange
        case "severe": return .red
        default: return .gray
        }
    }
}

// MARK: - History Detail Sheet (Beautiful Formatted)
struct HistoryDetailSheet: View {
    let item: AnalysisHistory
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Image
                    if let uiImage = UIImage(data: item.imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 250)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: 8)
                    }
                    
                    // Date & Severity Header
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .foregroundColor(.blue)
                            Text(item.smartFormattedDate)
                                .font(.system(size: 13))
                        }
                        
                        Spacer()
                        
                        // Severity Badge
                        HStack(spacing: 4) {
                            Circle()
                                .fill(severityColor(item.severity))
                                .frame(width: 8, height: 8)
                            Text(item.severity)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(severityColor(item.severity))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(severityColor(item.severity).opacity(0.15))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 4)
                    
                    // Parsed Sections
                    ForEach(parseAnalysisSections(), id: \.title) { section in
                        HistorySectionCard(section: section)
                    }
                    
                    // Disclaimer
                    disclaimerCard
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Analysis Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button { shareAnalysis() } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
    }
    
    private var disclaimerCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text("This AI analysis is for informational purposes only. Always consult a qualified dermatologist for proper diagnosis.")
                .font(.caption)
                .foregroundColor(.orange.opacity(0.9))
        }
        .padding(14)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func severityColor(_ severity: String) -> Color {
        switch severity.lowercased() {
        case "healthy": return .green
        case "mild": return .yellow
        case "moderate": return .orange
        case "severe": return .red
        default: return .gray
        }
    }
    
    // MARK: - Parse Sections
    private func parseAnalysisSections() -> [HistorySection] {
        var sections: [HistorySection] = []
        
        let sectionPatterns: [(icon: String, title: String, color: Color, keywords: [String])] = [
            ("chart.bar.fill", "Severity", .red, ["SEVERITY", "📊"]),
            ("eye.fill", "What I Observed", .blue, ["OBSERVED", "🔍"]),
            ("stethoscope", "Possible Conditions", .purple, ["POSSIBLE CONDITIONS", "🩺"]),
            ("checklist", "What You Should Do", .green, ["SHOULD DO", "💊", "RECOMMENDED"]),
            ("leaf.fill", "Ayurvedic Remedies", .orange, ["AYURVEDIC", "🌿"]),
            ("sparkles", "Skincare Tips", .pink, ["SKINCARE", "TIPS", "✨"])
        ]
        
        let lines = item.diagnosis.components(separatedBy: "\n")
        var currentSection: (title: String, icon: String, color: Color, content: [String])? = nil
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            if trimmedLine.isEmpty || trimmedLine.contains("━━") || trimmedLine.contains("___") { continue }
            
            var foundSection = false
            for pattern in sectionPatterns {
                if pattern.keywords.contains(where: { trimmedLine.uppercased().contains($0) }) {
                    if let current = currentSection, !current.content.isEmpty {
                        sections.append(HistorySection(icon: current.icon, title: current.title, color: current.color, content: current.content))
                    }
                    currentSection = (pattern.title, pattern.icon, pattern.color, [])
                    foundSection = true
                    break
                }
            }
            
            if !foundSection, currentSection != nil {
                let cleanedLine = trimmedLine
                    .replacingOccurrences(of: "•", with: "")
                    .replacingOccurrences(of: "▸", with: "")
                    .replacingOccurrences(of: "**", with: "")
                    .replacingOccurrences(of: "*", with: "")
                    .replacingOccurrences(of: "___", with: "")
                    .trimmingCharacters(in: .whitespaces)
                
                if !cleanedLine.isEmpty && cleanedLine.count > 2 {
                    currentSection?.content.append(cleanedLine)
                }
            }
        }
        
        if let current = currentSection, !current.content.isEmpty {
            sections.append(HistorySection(icon: current.icon, title: current.title, color: current.color, content: current.content))
        }
        
        return sections
    }
    
    private func shareAnalysis() {
        let text = "AyurScan Analysis (\(item.smartFormattedDate)):\n\n\(item.diagnosis)"
        let activityController = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            rootViewController.present(activityController, animated: true)
        }
    }
}

// MARK: - History Section Model
struct HistorySection: Identifiable {
    var id: String { title }
    let icon: String
    let title: String
    let color: Color
    let content: [String]
}

// MARK: - History Section Card
struct HistorySectionCard: View {
    let section: HistorySection
    @State private var isExpanded = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Button {
                withAnimation(.spring(response: 0.3)) { isExpanded.toggle() }
            } label: {
                HStack {
                    Image(systemName: section.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(section.color)
                        .cornerRadius(8)
                    
                    Text(section.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                }
            }
            
            // Content
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(section.content.enumerated()), id: \.offset) { index, item in
                        contentRow(item, index: index)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(14)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 6, y: 3)
    }
    
    @ViewBuilder
    private func contentRow(_ text: String, index: Int) -> some View {
        if section.title == "Severity" {
            // Severity display
            HStack {
                Text(text)
                    .font(.subheadline.bold())
                    .foregroundColor(severityTextColor(text))
                Spacer()
            }
        } else if section.title == "Possible Conditions" && (text.contains("-") || text.contains("%")) {
            conditionRow(text)
        } else if text.contains(":") && section.title == "Ayurvedic Remedies" {
            remedyRow(text)
        } else {
            bulletPoint(text)
        }
    }
    
    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(section.color.opacity(0.7))
                .frame(width: 5, height: 5)
                .padding(.top, 6)
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.primary)
        }
    }
    
    private func conditionRow(_ text: String) -> some View {
        let parts = text.split(separator: "-", maxSplits: 1)
        let name = String(parts.first ?? "").trimmingCharacters(in: .whitespaces)
        let detail = parts.count > 1 ? String(parts[1]).trimmingCharacters(in: .whitespaces) : ""
        
        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(name)
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                if let percentage = extractPercentage(from: text) {
                    Text("\(percentage)%")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(percentageColor(percentage))
                        .cornerRadius(6)
                }
            }
            if !detail.isEmpty && !detail.contains("%") {
                Text(detail)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .padding(10)
        .background(Color.gray.opacity(0.06))
        .cornerRadius(10)
    }
    
    private func remedyRow(_ text: String) -> some View {
        let parts = text.split(separator: ":", maxSplits: 1)
        if parts.count == 2 {
            return AnyView(
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(parts[0]))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(section.color)
                    Text(String(parts[1]).trimmingCharacters(in: .whitespaces))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            )
        } else {
            return AnyView(bulletPoint(text))
        }
    }
    
    private func severityTextColor(_ text: String) -> Color {
        let lower = text.lowercased()
        if lower.contains("healthy") { return .green }
        if lower.contains("mild") { return .yellow }
        if lower.contains("moderate") { return .orange }
        if lower.contains("severe") { return .red }
        return .gray
    }
    
    private func extractPercentage(from text: String) -> Int? {
        let pattern = #"(\d+)%"#
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range(at: 1), in: text) {
            return Int(text[range])
        }
        return nil
    }
    
    private func percentageColor(_ percentage: Int) -> Color {
        if percentage >= 70 { return .red }
        if percentage >= 40 { return .orange }
        return .green
    }
}

#Preview {
    HistoryView()
}
