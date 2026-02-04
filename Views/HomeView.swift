    // HomeView.swift - FINAL FIXED
    // Replace your entire HomeView.swift with this
    // Location: AyurScan/Views/HomeView.swift

    import SwiftUI
    import PhotosUI

    struct HomeView: View {
        @EnvironmentObject var appState: AppState
        
        @State private var selectedItem: PhotosPickerItem?
        @State private var selectedImage: UIImage?
        @State private var showCamera = false
        @State private var showFullAnalysis = false
        @State private var diagnosisText = "Ready to analyze your skin ✨"
        @State private var isAnalyzing = false
        
        @State private var headerOpacity: Double = 0
        @State private var cameraViewOffset: CGFloat = 50
        @State private var buttonsOffset: CGFloat = 100
        @State private var pulseAnimation = false
        
        var body: some View {
            NavigationStack {
                ZStack {
                    LinearGradient(colors: [Color.blue.opacity(0.05), Color.purple.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
                    
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
                // ⭐ FIXED: Using CustomCameraView instead of CameraView
                .sheet(isPresented: $showCamera) {
                    CustomCameraView(capturedImage: $selectedImage)
                }
                .sheet(isPresented: $showFullAnalysis) {
                    FullAnalysisView(analysis: diagnosisText, image: selectedImage)
                }
                .onAppear { startAnimations() }
                .onChange(of: selectedImage) { _, newImage in
                    if newImage != nil {
                        diagnosisText = "Perfect! Your image is ready for AI analysis 🔬"
                    }
                }
            }
        }
        
        // MARK: - Header
        private var headerSection: some View {
            HStack {
                HStack(spacing: 10) {
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                    Text("AyurScan")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                }
                .padding(14)
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                
                Spacer()
                
                HStack(spacing: 8) {
                    NavigationLink(destination: HistoryView()) {
                        Image(systemName: "clock.fill").font(.system(size: 18)).foregroundColor(.blue)
                            .frame(width: 44, height: 44).background(.ultraThinMaterial).cornerRadius(12)
                    }
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape.fill").font(.system(size: 18)).foregroundColor(.blue)
                            .frame(width: 44, height: 44).background(.ultraThinMaterial).cornerRadius(12)
                    }
                    if selectedImage != nil {
                        Button(action: clearImage) {
                            Image(systemName: "xmark.circle.fill").font(.system(size: 18)).foregroundColor(.red)
                                .frame(width: 44, height: 44).background(.ultraThinMaterial).cornerRadius(12)
                        }
                    }
                }
            }
        }
        
        // MARK: - Image Preview
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
                            .padding(.horizontal, 24).padding(.vertical, 14)
                            .background(.ultraThinMaterial)
                            .cornerRadius(20)
                    }
                }
            }
        }
        
        // MARK: - Analysis Result
        private var analysisResultSection: some View {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 12) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 24))
                        .foregroundStyle(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                    Text("Medical Analysis").font(.system(size: 22, weight: .bold))
                }
                
                if isAnalyzing {
                    HStack(spacing: 16) {
                        ProgressView().scaleEffect(1.3)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("🧠 AI Doctor analyzing...").font(.system(size: 15, weight: .medium))
                            Text("Processing medical assessment...").font(.system(size: 13)).foregroundColor(.secondary)
                        }
                    }
                } else if isValidDiagnosis() {
                    Button { showFullAnalysis = true } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "doc.text.fill").font(.system(size: 18))
                            Text("View Full Advice").font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity).frame(height: 52)
                        .background(LinearGradient(colors: [.teal, .green], startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(14)
                    }
                } else {
                    Text(diagnosisText).font(.system(size: 15)).foregroundColor(.secondary)
                }
            }
            .padding(20)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
        }
        
        // MARK: - Action Buttons
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
                    .onChange(of: selectedItem) { _, newVal in loadImage(from: newVal) }
                    
                    NavigationLink(destination: DoctorsListView()) {
                        ActionButtonLabel(title: "Doctors", icon: "stethoscope", colors: [.teal, .teal.opacity(0.8)], isDisabled: false)
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
                        Text(isAnalyzing ? "Analyzing..." : "AI Medical Analysis").font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity).frame(height: 58)
                    .background(LinearGradient(colors: (selectedImage == nil || isAnalyzing) ? [.gray, .gray.opacity(0.8)] : [.purple, .purple.opacity(0.8)], startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(18)
                }
                .disabled(selectedImage == nil || isAnalyzing)
            }
        }
        
        private var footerSection: some View {
            HStack(spacing: 8) {
                Image(systemName: "sparkles").foregroundColor(.orange)
                Text("Powered by Advanced AI").font(.system(size: 13, weight: .medium)).foregroundColor(.secondary).italic()
            }
            .padding(.top, 8).padding(.bottom, 20)
        }
        
        // MARK: - Functions
        private func startAnimations() {
            withAnimation(.easeOut(duration: 0.5)) { headerOpacity = 1.0 }
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.2)) { cameraViewOffset = 0 }
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.4)) { buttonsOffset = 0 }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) { pulseAnimation = true }
        }
        
        // ⭐ FIXED: Gallery image now processed for API
        private func loadImage(from item: PhotosPickerItem?) {
            guard let item = item else { return }
            item.loadTransferable(type: Data.self) { result in
                if case .success(let data) = result, let data = data, let img = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.selectedImage = img.preparedForAPI()
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
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
        }
        
        private func analyzeImage() {
            guard let image = selectedImage else { return }
            isAnalyzing = true
            diagnosisText = "🧠 AI Doctor analyzing..."
            
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
        let title: String, icon: String, colors: [Color]
        var isDisabled: Bool = false
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                ActionButtonLabel(title: title, icon: icon, colors: colors, isDisabled: isDisabled)
            }.disabled(isDisabled)
        }
    }

    struct ActionButtonLabel: View {
        let title: String, icon: String, colors: [Color]
        var isDisabled: Bool = false
        
        var body: some View {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 20))
                Text(title).font(.system(size: 11, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity).frame(height: 65)
            .background(LinearGradient(colors: isDisabled ? [.gray] : colors, startPoint: .top, endPoint: .bottom))
            .cornerRadius(14)
        }
    }

    // MARK: - Full Analysis View
    // MARK: - Full Analysis View (Beautiful Formatted)
    // Replace the existing FullAnalysisView in HomeView.swift with this

    struct FullAnalysisView: View {
        let analysis: String
        let image: UIImage?
        @Environment(\.dismiss) var dismiss
        
        var body: some View {
            NavigationStack {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Image Header
                        if let img = image {
                            ZStack(alignment: .bottomLeading) {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                                
                                // Gradient overlay
                                LinearGradient(colors: [.clear, .black.opacity(0.5)], startPoint: .top, endPoint: .bottom)
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                                
                                // Badge
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.seal.fill")
                                    Text("AI Analyzed")
                                }
                                .font(.caption.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.ultraThinMaterial)
                                .cornerRadius(20)
                                .padding(12)
                            }
                        }
                        
                        // Parsed Content Cards
                        ForEach(parseAnalysis(), id: \.title) { section in
                            SectionCardView(section: section)
                        }
                        
                        // Disclaimer
                        disclaimerView
                    }
                    .padding(16)
                }
                .background(Color(.systemGroupedBackground))
                .navigationTitle("Analysis Report")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { dismiss() }
                            .fontWeight(.semibold)
                            .foregroundColor(.teal)
                    }
                }
            }
        }
        
        // MARK: - Disclaimer View
        private var disclaimerView: some View {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.title3)
                
                Text("This AI analysis is for informational purposes only. Always consult a board-certified dermatologist for accurate diagnosis and treatment.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(16)
        }
        
        // MARK: - Parse Analysis into Sections
        private func parseAnalysis() -> [AnalysisSection] {
            var sections: [AnalysisSection] = []
            let text = analysis
            
            // Severity
            if let severity = extractSection(from: text, containing: ["SEVERITY"]) {
                let level = extractSeverityLevel(from: severity)
                sections.append(AnalysisSection(
                    title: "Severity Assessment",
                    icon: "chart.bar.fill",
                    color: severityColor(level),
                    type: .severity(level: level)
                ))
            }
            
            // What I Observed
            if let observed = extractSection(from: text, containing: ["OBSERVED", "🔍"]) {
                let points = extractBulletPoints(from: observed)
                if !points.isEmpty {
                    sections.append(AnalysisSection(
                        title: "What Was Observed",
                        icon: "eye.fill",
                        color: .blue,
                        type: .bullets(points)
                    ))
                }
            }
            
            // Possible Conditions
            if let conditions = extractSection(from: text, containing: ["POSSIBLE CONDITIONS", "🩺"]) {
                let items = extractConditions(from: conditions)
                if !items.isEmpty {
                    sections.append(AnalysisSection(
                        title: "Possible Conditions",
                        icon: "stethoscope",
                        color: .purple,
                        type: .conditions(items)
                    ))
                }
            }
            
            // What You Should Do
            if let actions = extractSection(from: text, containing: ["SHOULD DO", "💊", "RECOMMENDED"]) {
                let points = extractBulletPoints(from: actions)
                if !points.isEmpty {
                    sections.append(AnalysisSection(
                        title: "Recommended Actions",
                        icon: "checklist",
                        color: .green,
                        type: .numbered(points)
                    ))
                }
            }
            
            // Ayurvedic Remedies
            if let ayurvedic = extractSection(from: text, containing: ["AYURVEDIC", "🌿"]) {
                let remedies = extractRemedies(from: ayurvedic)
                if !remedies.isEmpty {
                    sections.append(AnalysisSection(
                        title: "Ayurvedic Remedies",
                        icon: "leaf.fill",
                        color: .orange,
                        type: .remedies(remedies)
                    ))
                }
            }
            
            // Skincare Tips
            if let tips = extractSection(from: text, containing: ["SKINCARE", "TIPS", "✨", "DAILY"]) {
                let points = extractBulletPoints(from: tips)
                if !points.isEmpty {
                    sections.append(AnalysisSection(
                        title: "Daily Skincare Tips",
                        icon: "sparkles",
                        color: .pink,
                        type: .bullets(points)
                    ))
                }
            }
            
            return sections
        }
        
        // MARK: - Helper Functions
        private func extractSection(from text: String, containing keywords: [String]) -> String? {
            let lines = text.components(separatedBy: "\n")
            var capturing = false
            var result: [String] = []
            
            for line in lines {
                let upper = line.uppercased()
                
                // Check if this line starts a new section
                if keywords.contains(where: { upper.contains($0) }) {
                    capturing = true
                    continue
                }
                
                // Check if we hit another section header
                if capturing {
                    let sectionHeaders = ["SEVERITY", "OBSERVED", "POSSIBLE", "SHOULD DO", "AYURVEDIC", "SKINCARE", "TIPS", "DISCLAIMER", "IMPORTANT", "━━"]
                    if sectionHeaders.contains(where: { upper.contains($0) }) && !keywords.contains(where: { upper.contains($0) }) {
                        break
                    }
                    result.append(line)
                }
            }
            
            let joined = result.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            return joined.isEmpty ? nil : joined
        }
        
        private func extractSeverityLevel(from text: String) -> String {
            let lower = text.lowercased()
            if lower.contains("healthy") || lower.contains("normal") { return "Healthy" }
            if lower.contains("severe") { return "Severe" }
            if lower.contains("moderate") { return "Moderate" }
            if lower.contains("mild") { return "Mild" }
            return "Mild"
        }
        
        private func severityColor(_ level: String) -> Color {
            switch level.lowercased() {
            case "healthy": return .green
            case "mild": return .yellow
            case "moderate": return .orange
            case "severe": return .red
            default: return .gray
            }
        }
        
        private func extractBulletPoints(from text: String) -> [String] {
            let lines = text.components(separatedBy: "\n")
            var points: [String] = []
            
            for line in lines {
                var cleaned = line
                    .replacingOccurrences(of: "•", with: "")
                    .replacingOccurrences(of: "▸", with: "")
                    .replacingOccurrences(of: "**", with: "")
                    .replacingOccurrences(of: "- ", with: "")
                    .trimmingCharacters(in: .whitespaces)
                
                // Remove leading numbers like "1.", "2."
                if let range = cleaned.range(of: #"^\d+\.\s*"#, options: .regularExpression) {
                    cleaned = String(cleaned[range.upperBound...])
                }
                
                if !cleaned.isEmpty && cleaned.count > 3 && !cleaned.hasPrefix("━") {
                    points.append(cleaned)
                }
            }
            
            return points
        }
        
        private func extractConditions(from text: String) -> [(name: String, probability: Int, description: String)] {
            var conditions: [(String, Int, String)] = []
            let lines = text.components(separatedBy: "\n")
            
            var currentName = ""
            var currentProb = 0
            var currentDesc = ""
            
            for line in lines {
                let cleaned = line.replacingOccurrences(of: "**", with: "").trimmingCharacters(in: .whitespaces)
                
                // Check for percentage
                if let probMatch = cleaned.range(of: #"(\d+)%"#, options: .regularExpression) {
                    let probStr = cleaned[probMatch].replacingOccurrences(of: "%", with: "")
                    currentProb = Int(probStr) ?? 50
                    
                    // Extract name (before the dash or percentage)
                    if let dashRange = cleaned.range(of: " – ") ?? cleaned.range(of: " - ") {
                        currentName = String(cleaned[..<dashRange.lowerBound])
                            .replacingOccurrences(of: #"^\d+\.\s*"#, with: "", options: .regularExpression)
                            .trimmingCharacters(in: .whitespaces)
                    }
                } else if !cleaned.isEmpty && cleaned.count > 10 && currentName.isEmpty == false {
                    // This is likely a description line
                    currentDesc = cleaned
                    conditions.append((currentName, currentProb, currentDesc))
                    currentName = ""
                    currentProb = 0
                    currentDesc = ""
                }
            }
            
            return conditions
        }
        
        private func extractRemedies(from text: String) -> [(name: String, details: String)] {
            var remedies: [(String, String)] = []
            let lines = text.components(separatedBy: "\n")
            
            var currentName = ""
            var currentDetails: [String] = []
            
            for line in lines {
                let cleaned = line.replacingOccurrences(of: "**", with: "")
                    .replacingOccurrences(of: "▸", with: "")
                    .trimmingCharacters(in: .whitespaces)
                
                if cleaned.isEmpty || cleaned.hasPrefix("━") { continue }
                
                // Check if this is a remedy name (short line, often starts with capital)
                if cleaned.count < 40 && !cleaned.lowercased().hasPrefix("ingredient") && !cleaned.lowercased().hasPrefix("how") && !cleaned.contains(":") {
                    if !currentName.isEmpty {
                        remedies.append((currentName, currentDetails.joined(separator: "\n")))
                    }
                    currentName = cleaned
                    currentDetails = []
                } else if !currentName.isEmpty {
                    currentDetails.append(cleaned)
                }
            }
            
            if !currentName.isEmpty {
                remedies.append((currentName, currentDetails.joined(separator: "\n")))
            }
            
            return remedies
        }
    }

    // MARK: - Section Data Model
    struct AnalysisSection: Identifiable {
        var id: String { title }
        let title: String
        let icon: String
        let color: Color
        let type: SectionType
        
        enum SectionType {
            case severity(level: String)
            case bullets([String])
            case numbered([String])
            case conditions([(name: String, probability: Int, description: String)])
            case remedies([(name: String, details: String)])
        }
    }

    // MARK: - Section Card View
    struct SectionCardView: View {
        let section: AnalysisSection
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack(spacing: 10) {
                    Image(systemName: section.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(section.color)
                        .cornerRadius(8)
                    
                    Text(section.title)
                        .font(.headline)
                    
                    Spacer()
                }
                
                Divider()
                
                // Content based on type
                switch section.type {
                case .severity(let level):
                    severityView(level: level)
                case .bullets(let points):
                    bulletsView(points: points)
                case .numbered(let points):
                    numberedView(points: points)
                case .conditions(let items):
                    conditionsView(items: items)
                case .remedies(let items):
                    remediesView(items: items)
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        }
        
        // MARK: - Severity View
        private func severityView(level: String) -> some View {
            VStack(spacing: 12) {
                HStack {
                    Text(level)
                        .font(.title2.bold())
                        .foregroundColor(section.color)
                    
                    Spacer()
                    
                    Text(severityEmoji(level))
                        .font(.title)
                }
                
                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 10)
                        
                        RoundedRectangle(cornerRadius: 6)
                            .fill(LinearGradient(colors: [.green, .yellow, .orange, .red], startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * severityProgress(level), height: 10)
                    }
                }
                .frame(height: 10)
                
                HStack {
                    Text("Healthy").font(.caption2).foregroundColor(.green)
                    Spacer()
                    Text("Severe").font(.caption2).foregroundColor(.red)
                }
            }
        }
        
        private func severityEmoji(_ level: String) -> String {
            switch level.lowercased() {
            case "healthy": return "✅"
            case "mild": return "⚠️"
            case "moderate": return "🟠"
            case "severe": return "🔴"
            default: return "ℹ️"
            }
        }
        
        private func severityProgress(_ level: String) -> CGFloat {
            switch level.lowercased() {
            case "healthy": return 0.15
            case "mild": return 0.35
            case "moderate": return 0.65
            case "severe": return 0.9
            default: return 0.3
            }
        }
        
        // MARK: - Bullets View
        private func bulletsView(points: [String]) -> some View {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(points, id: \.self) { point in
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(section.color.opacity(0.7))
                            .frame(width: 6, height: 6)
                            .padding(.top, 6)
                        
                        Text(point)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        
        // MARK: - Numbered View
        private func numberedView(points: [String]) -> some View {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(points.enumerated()), id: \.offset) { index, point in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1)")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .frame(width: 22, height: 22)
                            .background(section.color)
                            .cornerRadius(11)
                        
                        Text(point)
                            .font(.subheadline)
                    }
                }
            }
        }
        
        // MARK: - Conditions View
        private func conditionsView(items: [(name: String, probability: Int, description: String)]) -> some View {
            VStack(spacing: 12) {
                ForEach(items.indices, id: \.self) { index in
                    let item = items[index]
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(item.name)
                                .font(.subheadline.bold())
                            
                            Spacer()
                            
                            Text("\(item.probability)%")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(probabilityColor(item.probability))
                                .cornerRadius(10)
                        }
                        
                        // Progress bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 5)
                                
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(probabilityColor(item.probability))
                                    .frame(width: geo.size.width * CGFloat(item.probability) / 100, height: 5)
                            }
                        }
                        .frame(height: 5)
                        
                        if !item.description.isEmpty {
                            Text(item.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(12)
                    .background(Color.gray.opacity(0.06))
                    .cornerRadius(10)
                }
            }
        }
        
        private func probabilityColor(_ prob: Int) -> Color {
            if prob >= 70 { return .red }
            if prob >= 40 { return .orange }
            return .green
        }
        
        // MARK: - Remedies View
        private func remediesView(items: [(name: String, details: String)]) -> some View {
            VStack(spacing: 12) {
                ForEach(items.indices, id: \.self) { index in
                    let item = items[index]
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "leaf.fill")
                                .foregroundColor(.green)
                            Text(item.name)
                                .font(.subheadline.bold())
                        }
                        
                        Text(item.details)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.green.opacity(0.08))
                    .cornerRadius(10)
                }
            }
        }
    }
    #Preview {
        HomeView().environmentObject(AppState())
    }
