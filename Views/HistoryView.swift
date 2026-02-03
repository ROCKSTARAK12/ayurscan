// HistoryView.swift
// Analysis history screen - equivalent to history_screen.dart
// Location: AyurScan/Views/HistoryView.swift

import SwiftUI
import Combine

struct HistoryView: View {
    // MARK: - State Properties
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
                // Background
                LinearGradient(
                    colors: [Color.blue.opacity(0.05), Color.white],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // Content
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
                    if let item = itemToDelete {
                        deleteItem(item)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this analysis?")
            }
            .alert("Clear All History", isPresented: $showClearAllAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Clear All", role: .destructive) {
                    clearAllHistory()
                }
            } message: {
                Text("Are you sure you want to delete all analysis history? This action cannot be undone.")
            }
        }
        .onAppear {
            loadHistory()
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.3)
            
            Text("Loading history...")
                .font(.system(size: 15))
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "clock.badge.questionmark")
                    .font(.system(size: 50))
                    .foregroundColor(.blue.opacity(0.6))
            }
            
            // Text
            VStack(spacing: 10) {
                Text("No Analysis History")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("Your skin analysis history will appear here.\nStart by analyzing a skin image!")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            // Action button
            NavigationLink(destination: HomeView()) {
                HStack(spacing: 10) {
                    Image(systemName: "camera.fill")
                    Text("Start Analysis")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(14)
                .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            
            Spacer()
        }
        .padding(20)
    }
    
    // MARK: - History List View
    private var historyListView: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 14) {
                // Header info
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
                
                // History items
                ForEach(Array(history.enumerated()), id: \.element.id) { index, item in
                    HistoryCard(item: item)
                        .onTapGesture {
                            selectedItem = item
                            
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                itemToDelete = item
                                showDeleteAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            
                            Button {
                                shareAnalysis(item)
                            } label: {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                        }
                        .opacity(animateList ? 1 : 0)
                        .offset(y: animateList ? 0 : 20)
                        .animation(
                            .spring(response: 0.4, dampingFraction: 0.8)
                            .delay(Double(index) * 0.05),
                            value: animateList
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .padding(.bottom, 80)
        }
    }
    
    // MARK: - Functions
    private func loadHistory() {
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            history = StorageService.shared.getHistory()
            isLoading = false
            
            withAnimation(.easeOut(duration: 0.3)) {
                animateList = true
            }
        }
    }
    
    private func deleteItem(_ item: AnalysisHistory) {
        withAnimation(.spring()) {
            history.removeAll { $0.id == item.id }
        }
        
        // Update storage
        StorageService.shared.deleteAnalysis(id: item.id)
        
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)
    }
    
    private func clearAllHistory() {
        withAnimation(.spring()) {
            history.removeAll()
        }
        
        StorageService.shared.clearHistory()
        
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)
    }
    
    private func shareAnalysis(_ item: AnalysisHistory) {
        // Share functionality
        let text = "AyurScan Analysis:\n\n\(item.diagnosis)"
        let activityController = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )
        
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
            // Thumbnail image
            if let uiImage = UIImage(data: item.imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 70, height: 70)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            } else {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 70, height: 70)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                    )
            }
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                // Title (first line of diagnosis)
                Text(getTitle())
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                // Preview text
                Text(getPreview())
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                // Date & time
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.system(size: 11))
                    
                    Text(formatDate(item.timestamp))
                        .font(.system(size: 12))
                }
                .foregroundColor(.secondary.opacity(0.8))
            }
            
            Spacer()
            
            // Arrow icon
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
    
    private func getTitle() -> String {
        let lines = item.diagnosis.components(separatedBy: "\n")
        if let firstLine = lines.first, !firstLine.isEmpty {
            return firstLine.replacingOccurrences(of: "🩺", with: "")
                           .replacingOccurrences(of: "**", with: "")
                           .trimmingCharacters(in: .whitespaces)
        }
        return "Skin Analysis"
    }
    
    private func getPreview() -> String {
        let cleaned = item.diagnosis
            .replacingOccurrences(of: "🩺", with: "")
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "\n\n", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
        
        if cleaned.count > 80 {
            return String(cleaned.prefix(80)) + "..."
        }
        return cleaned
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        
        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "'Today,' h:mm a"
        } else if Calendar.current.isDateInYesterday(date) {
            formatter.dateFormat = "'Yesterday,' h:mm a"
        } else {
            formatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
        }
        
        return formatter.string(from: date)
    }
}

// MARK: - History Detail Sheet
struct HistoryDetailSheet: View {
    let item: AnalysisHistory
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Image
                    if let uiImage = UIImage(data: item.imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: 8)
                    }
                    
                    // Date info
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.blue)
                        
                        Text(item.timestamp.formatted(date: .long, time: .shortened))
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Diagnosis content
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 10) {
                            Image(systemName: "doc.text.fill")
                                .foregroundColor(.teal)
                            
                            Text("Analysis Report")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        
                        Text(item.diagnosis)
                            .font(.system(size: 15))
                            .foregroundColor(.primary)
                            .lineSpacing(6)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.08))
                    .cornerRadius(16)
                }
                .padding(20)
            }
            .navigationTitle("Analysis Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        shareAnalysis()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
    }
    
    private func shareAnalysis() {
        let text = "AyurScan Analysis (\(item.timestamp.formatted())):\n\n\(item.diagnosis)"
        let activityController = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            rootViewController.present(activityController, animated: true)
        }
    }
}

// MARK: - Preview
#Preview {
    HistoryView()
}
