// HomeView.swift
// Main camera + analysis screen - equivalent to home_page.dart
// Location: AyurScan/Views/HomeView.swift

import SwiftUI
import PhotosUI
import Combine


struct HomeView: View {
    // MARK: - State Properties
    @EnvironmentObject var appState: AppState
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var showCamera = false
    @State private var showFullAnalysis = false
    @State private var diagnosisText = "Ready to analyze your skin ✨"
    @State private var isAnalyzing = false
    @State private var showConditionsSheet = false
    @State private var showHospitalsSheet = false
    
    // Animation states
    @State private var headerOpacity: Double = 0
    @State private var cameraViewOffset: CGFloat = 50
    @State private var buttonsOffset: CGFloat = 100
    @State private var pulseAnimation = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // MARK: - Background
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.05),
                        Color.purple.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // MARK: - Header
                        headerSection
                            .opacity(headerOpacity)
                        
                        // MARK: - Camera/Image Preview
                        imagePreviewSection
                            .offset(y: cameraViewOffset)
                        
                        // MARK: - Analysis Result
                        analysisResultSection
                        
                        // MARK: - Action Buttons
                        actionButtonsSection
                            .offset(y: buttonsOffset)
                        
                        // MARK: - Footer
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
                FullAnalysisView(analysis: diagnosisText)
            }
            .onAppear {
                startAnimations()
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            // App Logo & Name
            HStack(spacing: 10) {
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("AyurScan")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
            .padding(14)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 8) {
                // History button
                NavigationLink(destination: HistoryView()) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.blue)
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                }
                
                // Settings button
                NavigationLink(destination: SettingsView()) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.blue)
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                }
                
                // Clear image button (if image selected)
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
            // Background gradient
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.blue.opacity(0.8),
                            Color.purple.opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 300)
                .shadow(color: .blue.opacity(0.3), radius: 20, x: 0, y: 10)
            
            if let image = selectedImage {
                // Show selected image
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .overlay(
                        // Fullscreen button
                        Button(action: {}) {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(.ultraThinMaterial)
                                .cornerRadius(12)
                        }
                        .padding(16),
                        alignment: .topTrailing
                    )
            } else {
                // Camera placeholder
                VStack(spacing: 20) {
                    ZStack {
                        // Pulsing circle
                        Circle()
                            .stroke(Color.cyan.opacity(0.5), lineWidth: 3)
                            .frame(width: 100, height: 100)
                            .scaleEffect(pulseAnimation ? 1.3 : 1.0)
                            .opacity(pulseAnimation ? 0.0 : 0.8)
                        
                        // Camera icon
                        Image(systemName: "viewfinder")
                            .font(.system(size: 60, weight: .light))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    // Instruction text
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
            // Header
            HStack(spacing: 12) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 24))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Medical Analysis")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            // Content
            if isAnalyzing {
                // Loading state
                HStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.3)
                    
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
                // Show "View Full Advice" button
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
                    .background(
                        LinearGradient(
                            colors: [Color.teal, Color.green],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(14)
                    .shadow(color: .teal.opacity(0.4), radius: 10, x: 0, y: 5)
                }
                
            } else {
                // Default/Error state
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
            // Row 1: Capture, Gallery, Conditions, Hospitals
            HStack(spacing: 12) {
                // Capture Button
                ActionButton(
                    title: "Capture",
                    icon: "camera.fill",
                    colors: [.blue, .blue.opacity(0.8)],
                    isDisabled: isAnalyzing
                ) {
                    showCamera = true
                }
                
                // Gallery Button
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    ActionButtonLabel(
                        title: "Gallery",
                        icon: "photo.fill",
                        colors: [.green, .green.opacity(0.8)],
                        isDisabled: isAnalyzing
                    )
                }
                .disabled(isAnalyzing)
                .onChange(of: selectedItem) { oldVal, newVal in
                    loadImage(from: newVal)
                }
                
                // Conditions Button
                NavigationLink(destination: SkinConditionsView()) {
                    ActionButtonLabel(
                        title: "Conditions",
                        icon: "list.clipboard.fill",
                        colors: [.purple, .purple.opacity(0.8)],
                        isDisabled: false
                    )
                }
                
                // Hospitals Button
                NavigationLink(destination: NearbyHospitalsView()) {
                    ActionButtonLabel(
                        title: "Hospitals",
                        icon: "cross.circle.fill",
                        colors: [.red, .red.opacity(0.8)],
                        isDisabled: false
                    )
                }
            }
            
            // Row 2: AI Medical Analysis Button
            Button(action: analyzeImage) {
                HStack(spacing: 12) {
                    if isAnalyzing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.9)
                    } else {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 20))
                    }
                    
                    Text(isAnalyzing ? "Analyzing..." : "AI Medical Analysis")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(
                    LinearGradient(
                        colors: (selectedImage == nil || isAnalyzing)
                            ? [.gray, .gray.opacity(0.8)]
                            : [.purple, .purple.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(18)
                .shadow(
                    color: (selectedImage == nil || isAnalyzing)
                        ? .clear
                        : .purple.opacity(0.4),
                    radius: 12,
                    x: 0,
                    y: 6
                )
            }
            .disabled(selectedImage == nil || isAnalyzing)
        }
    }
    
    // MARK: - Footer Section
    private var footerSection: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .foregroundColor(.orange)
            
            Text("Powered by Advanced AI • Gemini Vision")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
                .italic()
        }
        .padding(.top, 8)
        .padding(.bottom, 20)
    }
    
    // MARK: - Helper Functions
    
    private func startAnimations() {
        // Header fade in
        withAnimation(.easeOut(duration: 0.5)) {
            headerOpacity = 1.0
        }
        
        // Camera view slide up
        withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.2)) {
            cameraViewOffset = 0
        }
        
        // Buttons slide up
        withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.4)) {
            buttonsOffset = 0
        }
        
        // Pulse animation
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
            pulseAnimation = true
        }
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
                        
                        // Haptic feedback
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
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
        
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
    
    private func analyzeImage() {
        guard let image = selectedImage else {
            diagnosisText = "❌ Please capture or select an image first"
            return
        }
        
        isAnalyzing = true
        diagnosisText = "🧠 AI Doctor analyzing your skin...\n\nProcessing medical assessment..."
        
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        // Call Gemini API
        Task {
            do {
                let geminiService = GeminiService()
                let result = try await geminiService.analyzeImage(image)
                
                await MainActor.run {
                    diagnosisText = "🩺 **Professional Dermatological Assessment**\n\n\(result)"
                    isAnalyzing = false
                    
                    // Save to history
                    StorageService.shared.saveAnalysis(image: image, diagnosis: diagnosisText)
                    
                    // Success haptic
                    let notification = UINotificationFeedbackGenerator()
                    notification.notificationOccurred(.success)
                }
            } catch {
                await MainActor.run {
                    diagnosisText = "❌ Analysis failed: \(error.localizedDescription)\n\nPlease try again with a clear skin image."
                    isAnalyzing = false
                    
                    // Error haptic
                    let notification = UINotificationFeedbackGenerator()
                    notification.notificationOccurred(.error)
                }
            }
        }
    }
    
    private func isValidDiagnosis() -> Bool {
        return diagnosisText.contains("Professional Dermatological Assessment")
    }
}

// MARK: - Action Button Component
struct ActionButton: View {
    let title: String
    let icon: String
    let colors: [Color]
    var isDisabled: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ActionButtonLabel(
                title: title,
                icon: icon,
                colors: colors,
                isDisabled: isDisabled
            )
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
            Image(systemName: icon)
                .font(.system(size: 20))
            
            Text(title)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 65)
        .background(
            LinearGradient(
                colors: isDisabled ? [.gray, .gray.opacity(0.8)] : colors,
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(14)
        .shadow(
            color: isDisabled ? .clear : colors[0].opacity(0.4),
            radius: 8,
            x: 0,
            y: 4
        )
    }
}

// MARK: - Full Analysis View (Sheet)
struct FullAnalysisView: View {
    let analysis: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header Card
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 24))
                            .foregroundColor(.teal)
                            .padding(12)
                            .background(Color.teal.opacity(0.15))
                            .cornerRadius(12)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("AI Dermatological Report")
                                .font(.system(size: 17, weight: .bold))
                            
                            Text("Professional Assessment")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Verified badge
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 12))
                            Text("Verified")
                                .font(.system(size: 11, weight: .semibold))
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
                    
                    // Analysis Content
                    Text(analysis)
                        .font(.system(size: 15))
                        .lineSpacing(6)
                        .padding(20)
                        .background(Color.gray.opacity(0.08))
                        .cornerRadius(16)
                    
                    // Disclaimer
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        
                        Text("This AI analysis is for informational purposes only. Always consult a qualified healthcare professional for medical advice.")
                            .font(.system(size: 13))
                            .foregroundColor(.orange.opacity(0.9))
                    }
                    .padding(16)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding(20)
            }
            .navigationTitle("Medical Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                }
            }
        }
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
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
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

// MARK: - Preview
#Preview {
    HomeView()
        .environmentObject(AppState())
}
