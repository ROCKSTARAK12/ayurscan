// AyurScanApp.swift
// Main App Entry Point with Location Permission
// Location: AyurScan/AyurScanApp.swift

import SwiftUI
import Combine

@main
struct AyurScanApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var locationService = LocationService.shared
    
    var body: some Scene {
        WindowGroup {
            SplashNavigationView()
                .environmentObject(appState)
                .environmentObject(locationService)
                .onAppear {
                    // Request location permission on app launch
                    locationService.requestPermission()
                }
        }
    }
}

// MARK: - App State
class AppState: ObservableObject {
    @Published var selectedImage: UIImage? = nil
    @Published var analysisResult: String = ""
    @Published var isAnalyzing: Bool = false
    @Published var hasSeenWelcome: Bool = false
    
    init() {
        hasSeenWelcome = UserDefaults.standard.bool(forKey: "hasSeenWelcome")
    }
    
    func markWelcomeAsSeen() {
        hasSeenWelcome = true
        UserDefaults.standard.set(true, forKey: "hasSeenWelcome")
    }
    
    func clearAnalysis() {
        selectedImage = nil
        analysisResult = ""
        isAnalyzing = false
    }
}

// MARK: - Splash Navigation View
struct SplashNavigationView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var locationService: LocationService
    @State private var showSplash = true
    @State private var showWelcome = true
    
    var body: some View {
        ZStack {
            if showSplash {
                SplashView()
                    .transition(.opacity)
            } else if showWelcome && !appState.hasSeenWelcome {
                WelcomeView(showWelcome: $showWelcome)
                    .transition(.slide)
            } else {
                MainTabView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: showSplash)
        .animation(.easeInOut(duration: 0.3), value: showWelcome)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    showSplash = false
                }
            }
        }
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "camera.fill")
                    Text("Scan")
                }
                .tag(0)
            
            SkinConditionsView()
                .tabItem {
                    Image(systemName: "list.bullet.clipboard")
                    Text("Conditions")
                }
                .tag(1)
            
            NearbyHospitalsView()
                .tabItem {
                    Image(systemName: "cross.circle.fill")
                    Text("Hospitals")
                }
                .tag(2)
            
            HistoryView()
                .tabItem {
                    Image(systemName: "clock.fill")
                    Text("History")
                }
                .tag(3)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
                .tag(4)
        }
        .tint(.teal)
    }
}

#Preview {
    SplashNavigationView()
        .environmentObject(AppState())
        .environmentObject(LocationService.shared)
}
