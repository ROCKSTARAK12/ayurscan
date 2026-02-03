import SwiftUI
import Combine
@main
struct AyurScanApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            SplashNavigationView()
                .environmentObject(appState)
        }
    }
}

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

struct SplashNavigationView: View {
    @EnvironmentObject var appState: AppState
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
        .tint(.green)
    }
}

#Preview {
    SplashNavigationView()
        .environmentObject(AppState())
}
