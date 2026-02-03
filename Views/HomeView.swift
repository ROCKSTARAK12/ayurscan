// HomeView.swift
// Main camera + analysis screen
// Location: AyurScan/Views/HomeView.swift

import SwiftUI
import PhotosUI
import Combine

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var showCamera = false
    @State private var showFullAnalysis = false
    @State private var diagnosisText = "Ready to analyze your skin ✨"
    @State private var isAnalyzing = false
    @State private var showConditionsSheet = false
    @State private var showHospitalsSheet = false
    
    @State private var headerOpacity: Double = 0
    @State private var cameraViewOffset: CGFloat = 50
    @State private var buttonsOffset: CGFloat = 100
    @State private var pulseAnimation = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.blue.opacity(0.05), Color.purple.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        headerSection.opacity(headerOpacity)
                        imagePreviewSection.offset(y: cameraViewOffset)
                        analysisResultSection
                        actionButtonsSection.offset(y: buttonsOffset)
                        footerSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showCamera) {
                CameraView(image: $selectedImage)
            }
            .sheet(isPresented: $showFullAnalysis) {
                FullAnalysisView(analysis: diagnosisText, image: selectedImage)
            }
            .onAppear { startAnimations() }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            HStack(spacing: 10) {
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                
                Text("AyurScan")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
            .padding(14)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            
            Spacer()
            
            HStack(spacing: 8) {
                NavigationLink(destination: HistoryView()) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.blue)
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                }
                
                NavigationLink(destination: SettingsView()) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.blue)
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                }
                
                if selectedImage != nil {
                    Button(action: clearImage) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.red)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)
                    }
                }
            }
        }
    }
    
    // MARK: - Image Preview Section
    private var imagePreviewSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(LinearGradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(height: 300)
                .shadow(color: .blue.opacity(0.3), radius: 20, x: 0, y: 10)
            
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
            } else {
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .stroke(Color.cyan.opacity(0.5), lineWidth: 3)
                            .frame(width: 100, height: 100)
                            .scaleEffect(pulseAnimation ? 1.3 : 1.0)
                            .opacity(pulseAnimation ? 0.0 : 0.8)
                        
                        Image(systemName: "viewfinder")
                            .font(.system(size: 60, weight: .light))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    Text("Position skin area in frame")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                }
            }
        }
    }
    
    // MARK: - Analysis Result Section
    private var analysisResultSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 24))
                    .foregroundStyle(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                
                Text("Medical Analysis")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            if isAnalyzing {
                HStack(spacing: 16) {
                    ProgressView().scaleEffect(1.3)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("🧠 AI Doctor analyzing your skin...")
                            .font(.system(size: 15, weight: .medium))
                        Text("Processing medical assessment...")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
                
            } else if isValidDiagnosis() {
                Button(action: { showFullAnalysis = true }) {
                    HStack(spacing: 10) {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 18))
                        Text("View Full Advice")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(LinearGradient(colors: [Color.teal, Color.green], startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(14)
                    .shadow(color: .teal.opacity(0.4), radius: 10, x: 0, y: 5)
                }
            } else {
                Text(diagnosisText)
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 15, x: 0, y: 5)
    }
    
    // MARK: - Action Buttons Section
    private var actionButtonsSection: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                ActionButton(title: "Capture", icon: "camera.fill", colors: [.blue, .blue.opacity(0.8)], isDisabled: isAnalyzing) {
                    showCamera = true
                }
                
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    ActionButtonLabel(title: "Gallery", icon: "photo.fill", colors: [.green, .green.opacity(0.8)], isDisabled: isAnalyzing)
                }
                .disabled(isAnalyzing)
                .onChange(of: selectedItem) { oldVal, newVal in loadImage(from: newVal) }
                
                NavigationLink(destination: SkinConditionsView()) {
                    ActionButtonLabel(title: "Conditions", icon: "list.clipboard.fill", colors: [.purple, .purple.opacity(0.8)], isDisabled: false)
                }
                
                NavigationLink(destination: NearbyHospitalsView()) {
                    ActionButtonLabel(title: "Hospitals", icon: "cross.circle.fill", colors: [.red, .red.opacity(0.8)], isDisabled: false)
                }
            }
            
            Button(action: analyzeImage) {
                HStack(spacing: 12) {
                    if isAnalyzing {
                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)).scaleEffect(0.9)
                    } else {
                        Image(systemName: "brain.head.profile").font(.system(size: 20))
                    }
                    Text(isAnalyzing ? "Analyzing..." : "AI Medical Analysis")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(LinearGradient(colors: (selectedImage == nil || isAnalyzing) ? [.gray, .gray.opacity(0.8)] : [.purple, .purple.opacity(0.8)], startPoint: .leading, endPoint: .trailing))
                .cornerRadius(18)
                .shadow(color: (selectedImage == nil || isAnalyzing) ? .clear : .purple.opacity(0.4), radius: 12, x: 0, y: 6)
            }
            .disabled(selectedImage == nil || isAnalyzing)
        }
    }
    
    private var footerSection: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles").foregroundColor(.orange)
            Text("Powered by Advanced AI • Mistral Vision")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
                .italic()
        }
        .padding(.top, 8)
        .padding(.bottom, 20)
    }
    
    // MARK: - Helper Functions
    private func startAnimations() {
        withAnimation(.easeOut(duration: 0.5)) { headerOpacity = 1.0 }
        withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.2)) { cameraViewOffset = 0 }
        withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.4)) { buttonsOffset = 0 }
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) { pulseAnimation = true }
    }
    
    private func loadImage(from item: PhotosPickerItem?) {
        guard let item = item else { return }
        item.loadTransferable(type: Data.self) { result in
            switch result {
            case .success(let data):
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.selectedImage = image
                        self.diagnosisText = "Perfect! Your image is ready for AI analysis 🔬"
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
                }
            case .failure(let error):
                print("Error loading image: \(error)")
                DispatchQueue.main.async {
                    self.diagnosisText = "❌ Failed to load image. Please try again."
                }
            }
        }
    }
    
    private func clearImage() {
        withAnimation(.spring()) {
            selectedImage = nil
            diagnosisText = "Ready to analyze your skin ✨"
            selectedItem = nil
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    private func analyzeImage() {
        guard let image = selectedImage else {
            diagnosisText = "❌ Please capture or select an image first"
            return
        }
        
        isAnalyzing = true
        diagnosisText = "🧠 AI Doctor analyzing your skin..."
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        Task {
            do {
                let result = try await GeminiService.shared.analyzeImage(image)
                await MainActor.run {
                    diagnosisText = result
                    isAnalyzing = false
                    StorageService.shared.saveAnalysis(image: image, diagnosis: diagnosisText)
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            } catch {
                await MainActor.run {
                    diagnosisText = "❌ Analysis failed: \(error.localizedDescription)"
                    isAnalyzing = false
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                }
            }
        }
    }
    
    private func isValidDiagnosis() -> Bool {
        diagnosisText.contains("SEVERITY") || diagnosisText.contains("OBSERVED") || diagnosisText.contains("━━")
    }
}

// MARK: - Action Button Components
struct ActionButton: View {
    let title: String
    let icon: String
    let colors: [Color]
    var isDisabled: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ActionButtonLabel(title: title, icon: icon, colors: colors, isDisabled: isDisabled)
        }
        .disabled(isDisabled)
    }
}

struct ActionButtonLabel: View {
    let title: String
    let icon: String
    let colors: [Color]
    var isDisabled: Bool = false
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 20))
            Text(title).font(.system(size: 11, weight: .semibold))
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 65)
        .background(LinearGradient(colors: isDisabled ? [.gray, .gray.opacity(0.8)] : colors, startPoint: .top, endPoint: .bottom))
        .cornerRadius(14)
        .shadow(color: isDisabled ? .clear : colors[0].opacity(0.4), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Full Analysis View (Beautiful Formatted)
struct FullAnalysisView: View {
    let analysis: String
    let image: UIImage?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Header Card
                    headerCard
                    
                    // Image Preview
                    if let img = image {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                    }
                    
                    // Parsed Sections
                    ForEach(parseAnalysisSections(), id: \.title) { section in
                        SectionCard(section: section)
                    }
                    
                    // Disclaimer
                    disclaimerCard
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Medical Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
    
    private var headerCard: some View {
        HStack {
            Image(systemName: "brain.head.profile")
                .font(.title2)
                .foregroundColor(.teal)
                .padding(12)
                .background(Color.teal.opacity(0.15))
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("AI Dermatological Report")
                    .font(.headline)
                Text("Professional Assessment")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.caption)
                Text("Verified")
                    .font(.caption.bold())
            }
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.green)
            .cornerRadius(12)
        }
        .padding(16)
        .background(Color.blue.opacity(0.08))
        .cornerRadius(16)
    }
    
    private var disclaimerCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            
            Text("This AI analysis is for informational purposes only. Always consult a qualified dermatologist for proper diagnosis and treatment.")
                .font(.caption)
                .foregroundColor(.orange.opacity(0.9))
        }
        .padding(16)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Parse Analysis into Sections
    private func parseAnalysisSections() -> [AnalysisSection] {
        var sections: [AnalysisSection] = []
        
        // Define section patterns
        let sectionPatterns: [(icon: String, title: String, color: Color, keywords: [String])] = [
            ("chart.bar.fill", "Severity", .red, ["SEVERITY", "📊"]),
            ("eye.fill", "What I Observed", .blue, ["OBSERVED", "🔍"]),
            ("stethoscope", "Possible Conditions", .purple, ["POSSIBLE CONDITIONS", "🩺"]),
            ("checklist", "What You Should Do", .green, ["SHOULD DO", "💊", "RECOMMENDED"]),
            ("leaf.fill", "Ayurvedic Remedies", .orange, ["AYURVEDIC", "🌿"]),
            ("sparkles", "Skincare Tips", .pink, ["SKINCARE", "TIPS", "✨"])
        ]
        
        // Split by section dividers
        let lines = analysis.components(separatedBy: "\n")
        var currentSection: (title: String, icon: String, color: Color, content: [String])? = nil
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            // Skip empty lines and dividers
            if trimmedLine.isEmpty || trimmedLine.contains("━━") || trimmedLine.contains("---") {
                continue
            }
            
            // Check if this line starts a new section
            var foundSection = false
            for pattern in sectionPatterns {
                if pattern.keywords.contains(where: { trimmedLine.uppercased().contains($0) }) {
                    // Save previous section
                    if let current = currentSection, !current.content.isEmpty {
                        sections.append(AnalysisSection(
                            icon: current.icon,
                            title: current.title,
                            color: current.color,
                            content: current.content
                        ))
                    }
                    // Start new section
                    currentSection = (pattern.title, pattern.icon, pattern.color, [])
                    foundSection = true
                    break
                }
            }
            
            // Add content to current section
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
        
        // Add last section
        if let current = currentSection, !current.content.isEmpty {
            sections.append(AnalysisSection(
                icon: current.icon,
                title: current.title,
                color: current.color,
                content: current.content
            ))
        }
        
        return sections
    }
}

// MARK: - Analysis Section Model
struct AnalysisSection: Identifiable {
    var id: String { title }
    let icon: String
    let title: String
    let color: Color
    let content: [String]
}

// MARK: - Section Card View
struct SectionCard: View {
    let section: AnalysisSection
    @State private var isExpanded = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: section.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(section.color)
                        .cornerRadius(8)
                    
                    Text(section.title)
                        .font(.headline)
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
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
    
    @ViewBuilder
    private func contentRow(_ text: String, index: Int) -> some View {
        if section.title == "Severity" {
            // Special severity display
            HStack {
                Text(text)
                    .font(.title3.bold())
                    .foregroundColor(severityColor(text))
                Spacer()
                severityBadge(text)
            }
        } else if text.contains(":") && section.title == "Ayurvedic Remedies" {
            // Key-value for remedies
            let parts = text.split(separator: ":", maxSplits: 1)
            if parts.count == 2 {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(parts[0]))
                        .font(.subheadline.bold())
                        .foregroundColor(section.color)
                    Text(String(parts[1]).trimmingCharacters(in: .whitespaces))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } else {
                bulletPoint(text)
            }
        } else if section.title == "Possible Conditions" && text.contains("-") {
            // Condition with percentage
            conditionRow(text)
        } else {
            bulletPoint(text)
        }
    }
    
    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(section.color.opacity(0.7))
                .frame(width: 6, height: 6)
                .padding(.top, 6)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }
    
    private func conditionRow(_ text: String) -> some View {
        let parts = text.split(separator: "-", maxSplits: 1)
        let name = String(parts.first ?? "").trimmingCharacters(in: .whitespaces)
        let detail = parts.count > 1 ? String(parts[1]).trimmingCharacters(in: .whitespaces) : ""
        
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(name)
                    .font(.subheadline.bold())
                
                Spacer()
                
                if let percentage = extractPercentage(from: text) {
                    Text("\(percentage)%")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(percentageColor(percentage))
                        .cornerRadius(8)
                }
            }
            
            if !detail.isEmpty && !detail.contains("%") {
                Text(detail)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(10)
        .background(Color.gray.opacity(0.08))
        .cornerRadius(10)
    }
    
    private func severityColor(_ text: String) -> Color {
        let lower = text.lowercased()
        if lower.contains("healthy") { return .green }
        if lower.contains("mild") { return .yellow }
        if lower.contains("moderate") { return .orange }
        if lower.contains("severe") { return .red }
        return .gray
    }
    
    private func severityBadge(_ text: String) -> some View {
        let lower = text.lowercased()
        let (label, color): (String, Color) = {
            if lower.contains("healthy") { return ("✅ Healthy", .green) }
            if lower.contains("mild") { return ("⚠️ Mild", .yellow) }
            if lower.contains("moderate") { return ("🟠 Moderate", .orange) }
            if lower.contains("severe") { return ("🔴 Severe", .red) }
            return ("", .gray)
        }()
        
        return Text(label)
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.2))
            .cornerRadius(8)
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

// MARK: - Camera View
struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        init(_ parent: CameraView) { self.parent = parent }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.image = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.image = originalImage
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    HomeView().environmentObject(AppState())
}
