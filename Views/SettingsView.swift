import SwiftUI
import Combine

struct SettingsView: View {
    @AppStorage("gemini_api_key") private var apiKey = ""
    @AppStorage("dark_mode") private var isDarkMode = false
    @AppStorage("notifications_enabled") private var notificationsEnabled = true
    @AppStorage("auto_save_enabled") private var autoSaveEnabled = true
    @AppStorage("haptic_feedback_enabled") private var hapticFeedbackEnabled = true
    @AppStorage("selected_model") private var selectedModel = "gemini-1.5-flash"
    @AppStorage("temperature") private var temperature: Double = 0.7
    @AppStorage("max_tokens") private var maxTokens: Double = 1200
    
    @State private var showApiKey = false
    @State private var showResetAlert = false
    @State private var showSavedToast = false
    @State private var animateContent = false
    
    let availableModels = [
        "gemini-1.5-flash",
        "gemini-1.5-pro",
        "gemini-1.0-pro-vision"
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.gray.opacity(0.06)
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        apiConfigurationSection
                        modelSettingsSection
                        appPreferencesSection
                        aboutSection
                        dangerZoneSection
                        footerSection
                    }
                    .padding(20)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 30)
                }
                
                if showSavedToast {
                    VStack {
                        Spacer()
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
                        .padding(.bottom, 100)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showResetAlert = true }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 16))
                    }
                }
            }
            .alert("Reset Settings", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) { performReset() }
            } message: {
                Text("Are you sure you want to reset all settings?")
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animateContent = true
            }
        }
    }
    
    private var apiConfigurationSection: some View {
        SettingsSectionView(title: "API Configuration", icon: "key.fill", iconColor: .orange) {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Gemini API Key")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 12) {
                        Image(systemName: "key.fill")
                            .foregroundColor(.orange)
                            .frame(width: 20)
                        
                        if showApiKey {
                            TextField("Enter your API key", text: $apiKey)
                                .font(.system(size: 15))
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                        } else {
                            SecureField("Enter your API key", text: $apiKey)
                                .font(.system(size: 15))
                        }
                        
                        Button(action: { showApiKey.toggle() }) {
                            Image(systemName: showApiKey ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(14)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
            }
        }
    }
    
    private var modelSettingsSection: some View {
        SettingsSectionView(title: "Model Settings", icon: "brain", iconColor: .purple) {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("AI Model")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: "cpu")
                            .foregroundColor(.purple)
                        
                        Picker("Model", selection: $selectedModel) {
                            ForEach(availableModels, id: \.self) { model in
                                Text(model).tag(model)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.primary)
                    }
                    .padding(14)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Temperature")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "%.1f", temperature))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.purple)
                    }
                    
                    Slider(value: $temperature, in: 0.0...2.0, step: 0.1)
                        .tint(.purple)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Max Tokens")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(maxTokens))")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.purple)
                    }
                    
                    Slider(value: $maxTokens, in: 256...4096, step: 128)
                        .tint(.purple)
                }
            }
        }
    }
    
    private var appPreferencesSection: some View {
        SettingsSectionView(title: "App Preferences", icon: "slider.horizontal.3", iconColor: .blue) {
            VStack(spacing: 4) {
                SettingsToggleRow(title: "Dark Mode", subtitle: "Use dark theme", icon: "moon.fill", iconColor: .indigo, isOn: $isDarkMode)
                Divider().padding(.vertical, 8)
                SettingsToggleRow(title: "Notifications", subtitle: "Receive alerts", icon: "bell.fill", iconColor: .red, isOn: $notificationsEnabled)
                Divider().padding(.vertical, 8)
                SettingsToggleRow(title: "Auto Save", subtitle: "Save analyses automatically", icon: "arrow.down.doc.fill", iconColor: .green, isOn: $autoSaveEnabled)
                Divider().padding(.vertical, 8)
                SettingsToggleRow(title: "Haptic Feedback", subtitle: "Vibrate on interactions", icon: "iphone.radiowaves.left.and.right", iconColor: .orange, isOn: $hapticFeedbackEnabled)
            }
        }
    }
    
    private var aboutSection: some View {
        SettingsSectionView(title: "About", icon: "info.circle.fill", iconColor: .gray) {
            VStack(spacing: 4) {
                HStack {
                    Image(systemName: "number").foregroundColor(.gray).frame(width: 30)
                    Text("Version")
                    Spacer()
                    Text("1.0.0").foregroundColor(.secondary)
                }
                .padding(.vertical, 12)
                
                Divider()
                
                HStack {
                    Image(systemName: "person.fill").foregroundColor(.gray).frame(width: 30)
                    Text("Developer")
                    Spacer()
                    Text("Shreya Jaiswal").foregroundColor(.secondary)
                }
                .padding(.vertical, 12)
            }
        }
    }
    
    private var dangerZoneSection: some View {
        SettingsSectionView(title: "Danger Zone", icon: "exclamationmark.triangle.fill", iconColor: .red) {
            Button(action: { showResetAlert = true }) {
                HStack {
                    Image(systemName: "trash.fill").foregroundColor(.red).frame(width: 30)
                    Text("Reset All Settings").foregroundColor(.red)
                    Spacer()
                }
                .padding(.vertical, 12)
            }
        }
    }
    
    private var footerSection: some View {
        VStack(spacing: 8) {
            Text("Made with ❤️ in India")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
        .padding(.top, 20)
    }
    
    private func performReset() {
        apiKey = ""
        isDarkMode = false
        notificationsEnabled = true
        autoSaveEnabled = true
        hapticFeedbackEnabled = true
        selectedModel = "gemini-1.5-flash"
        temperature = 0.7
        maxTokens = 1200
        showSavedNotification()
    }
    
    private func showSavedNotification() {
        withAnimation { showSavedToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showSavedToast = false }
        }
    }
}

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
                Text(title).font(.system(size: 15, weight: .medium))
                Text(subtitle).font(.system(size: 12)).foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn).labelsHidden().tint(.green)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    SettingsView()
}
