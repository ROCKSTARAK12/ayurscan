// SettingsView.swift
// Clean Settings Screen - User Friendly
// Location: AyurScan/Views/SettingsView.swift

import SwiftUI

struct SettingsView: View {
    // User Preferences Only
    @AppStorage("dark_mode") private var isDarkMode = false
    @AppStorage("notifications_enabled") private var notificationsEnabled = true
    @AppStorage("auto_save_enabled") private var autoSaveEnabled = true
    @AppStorage("haptic_feedback_enabled") private var hapticFeedbackEnabled = true
    @AppStorage("language") private var selectedLanguage = "English"
    
    @State private var showResetAlert = false
    @State private var showClearHistoryAlert = false
    @State private var showSavedToast = false
    @State private var animateContent = false
    
    let languages = ["English", "Hindi", "Hinglish"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background Gradient
                LinearGradient(
                    colors: [Color.teal.opacity(0.05), Color.white],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Profile Card
                        profileSection
                        
                        // App Preferences
                        appPreferencesSection
                        
                        // Analysis Settings
                        analysisSettingsSection
                        
                        // Support & Help
                        supportSection
                        
                        // About
                        aboutSection
                        
                        // Danger Zone
                        dangerZoneSection
                        
                        // Footer
                        footerSection
                    }
                    .padding(20)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 30)
                }
                
                // Toast
                if showSavedToast {
                    VStack {
                        Spacer()
                        toastView
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .alert("Clear History", isPresented: $showClearHistoryAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Clear All", role: .destructive) { clearHistory() }
            } message: {
                Text("Are you sure you want to delete all analysis history? This cannot be undone.")
            }
            .alert("Reset Settings", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) { resetSettings() }
            } message: {
                Text("Reset all settings to default?")
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animateContent = true
            }
        }
    }
    
    // MARK: - Profile Section
    private var profileSection: some View {
        VStack(spacing: 16) {
            // App Icon & Name
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.teal, .green],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: .teal.opacity(0.4), radius: 10, y: 5)
                
                Image(systemName: "leaf.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 4) {
                Text("AyurScan")
                    .font(.system(size: 24, weight: .bold))
                
                Text("AI-Powered Skin Analysis")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            // Stats Row
            HStack(spacing: 30) {
                StatItem(value: "\(getAnalysisCount())", label: "Analyses", icon: "chart.bar.fill", color: .blue)
                StatItem(value: "Free", label: "Plan", icon: "star.fill", color: .orange)
                StatItem(value: "v1.0", label: "Version", icon: "info.circle.fill", color: .purple)
            }
            .padding(.top, 8)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 15, y: 8)
        )
    }
    
    // MARK: - App Preferences Section
    private var appPreferencesSection: some View {
        SettingsSectionView(title: "App Preferences", icon: "slider.horizontal.3", iconColor: .blue) {
            VStack(spacing: 0) {
                SettingsToggleRow(
                    title: "Dark Mode",
                    subtitle: "Use dark theme",
                    icon: "moon.fill",
                    iconColor: .indigo,
                    isOn: $isDarkMode
                )
                
                Divider().padding(.vertical, 8)
                
                SettingsToggleRow(
                    title: "Notifications",
                    subtitle: "Get analysis reminders",
                    icon: "bell.fill",
                    iconColor: .red,
                    isOn: $notificationsEnabled
                )
                
                Divider().padding(.vertical, 8)
                
                SettingsToggleRow(
                    title: "Haptic Feedback",
                    subtitle: "Vibration on actions",
                    icon: "iphone.radiowaves.left.and.right",
                    iconColor: .orange,
                    isOn: $hapticFeedbackEnabled
                )
            }
        }
    }
    
    // MARK: - Analysis Settings Section
    private var analysisSettingsSection: some View {
        SettingsSectionView(title: "Analysis Settings", icon: "brain.head.profile", iconColor: .purple) {
            VStack(spacing: 0) {
                SettingsToggleRow(
                    title: "Auto Save",
                    subtitle: "Save analyses automatically",
                    icon: "arrow.down.doc.fill",
                    iconColor: .green,
                    isOn: $autoSaveEnabled
                )
                
                Divider().padding(.vertical, 8)
                
                // Language Picker
                HStack(spacing: 14) {
                    Image(systemName: "globe")
                        .font(.system(size: 18))
                        .foregroundColor(.teal)
                        .frame(width: 30)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Report Language")
                            .font(.system(size: 15, weight: .medium))
                        Text("Language for analysis reports")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Picker("", selection: $selectedLanguage) {
                        ForEach(languages, id: \.self) { lang in
                            Text(lang).tag(lang)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.teal)
                }
                .padding(.vertical, 8)
            }
        }
    }
    
    // MARK: - Support Section
    private var supportSection: some View {
        SettingsSectionView(title: "Support & Help", icon: "questionmark.circle.fill", iconColor: .teal) {
            VStack(spacing: 0) {
                SettingsLinkRow(
                    title: "How to Use",
                    subtitle: "Learn app features",
                    icon: "book.fill",
                    iconColor: .blue
                ) {
                    // Navigate to tutorial
                }
                
                Divider().padding(.vertical, 8)
                
                SettingsLinkRow(
                    title: "FAQs",
                    subtitle: "Common questions",
                    icon: "questionmark.bubble.fill",
                    iconColor: .orange
                ) {
                    // Navigate to FAQs
                }
                
                Divider().padding(.vertical, 8)
                
                SettingsLinkRow(
                    title: "Contact Support",
                    subtitle: "Get help via email",
                    icon: "envelope.fill",
                    iconColor: .green
                ) {
                    sendSupportEmail()
                }
                
                Divider().padding(.vertical, 8)
                
                SettingsLinkRow(
                    title: "Rate App",
                    subtitle: "Leave a review",
                    icon: "star.fill",
                    iconColor: .yellow
                ) {
                    // Open App Store
                }
            }
        }
    }
    
    // MARK: - About Section
    private var aboutSection: some View {
        SettingsSectionView(title: "About", icon: "info.circle.fill", iconColor: .gray) {
            VStack(spacing: 0) {
                AboutRow(label: "Version", value: "1.0.0", icon: "number")
                Divider().padding(.vertical, 8)
                AboutRow(label: "Developer", value: "Pulse_Point", icon: "person.fill")
                Divider().padding(.vertical, 8)
                AboutRow(label: "AI Engine", value: "Mistral + Gemini", icon: "cpu.fill")
                Divider().padding(.vertical, 8)
                
                // Social Links
                HStack(spacing: 20) {
                    SocialButton(icon: "link", color: .blue) {
                        // Website
                    }
                    SocialButton(icon: "camera.fill", color: .pink) {
                        // Instagram
                    }
                    SocialButton(icon: "envelope.fill", color: .green) {
                        sendSupportEmail()
                    }
                }
                .padding(.top, 8)
            }
        }
    }
    
    // MARK: - Danger Zone Section
    private var dangerZoneSection: some View {
        SettingsSectionView(title: "Data & Storage", icon: "externaldrive.fill", iconColor: .red) {
            VStack(spacing: 0) {
                Button(action: { showClearHistoryAlert = true }) {
                    HStack(spacing: 14) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.orange)
                            .frame(width: 30)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Clear History")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.primary)
                            Text("Delete all saved analyses")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 8)
                }
                
                Divider().padding(.vertical, 8)
                
                Button(action: { showResetAlert = true }) {
                    HStack(spacing: 14) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 18))
                            .foregroundColor(.red)
                            .frame(width: 30)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Reset Settings")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.red)
                            Text("Restore default settings")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 8)
                }
            }
        }
    }
    
    // MARK: - Footer Section
    private var footerSection: some View {
        VStack(spacing: 8) {
            Text("Made with ❤️ in India")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            
            Text("© 2025 AyurScan. All rights reserved.")
                .font(.system(size: 11))
                .foregroundColor(.secondary.opacity(0.7))
        }
        .padding(.top, 20)
        .padding(.bottom, 40)
    }
    
    // MARK: - Toast View
    private var toastView: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.white)
            Text("Settings saved!")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(Color.green)
        .cornerRadius(25)
        .shadow(color: .green.opacity(0.4), radius: 10, y: 5)
        .padding(.bottom, 100)
    }
    
    // MARK: - Functions
    private func getAnalysisCount() -> Int {
        return StorageService.shared.getHistory().count
    }
    
    private func clearHistory() {
        StorageService.shared.clearHistory()
        showToast()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    
    private func resetSettings() {
        isDarkMode = false
        notificationsEnabled = true
        autoSaveEnabled = true
        hapticFeedbackEnabled = true
        selectedLanguage = "English"
        showToast()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    
    private func showToast() {
        withAnimation { showSavedToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showSavedToast = false }
        }
    }
    
    private func sendSupportEmail() {
        if let url = URL(string: "mailto:support@ayurscan.com") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Stat Item Component
struct StatItem: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
            
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Settings Section View
struct SettingsSectionView<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor)
                Text(title)
                    .font(.system(size: 18, weight: .bold))
            }
            
            content
                .padding(16)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        }
    }
}

// MARK: - Settings Toggle Row
struct SettingsToggleRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(iconColor)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(.teal)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Settings Link Row
struct SettingsLinkRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 8)
        }
    }
}

// MARK: - About Row
struct AboutRow: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .frame(width: 30)
            Text(label)
                .font(.system(size: 15))
            Spacer()
            Text(value)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Social Button
struct SocialButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(color)
                .cornerRadius(12)
        }
    }
}

#Preview {
    SettingsView()
}
