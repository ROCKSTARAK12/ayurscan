// WelcomeView.swift
// Welcome/Onboarding screen - equivalent to welcome_screen.dart
// Location: AyurScan/Views/WelcomeView.swift

import SwiftUI
import Combine

struct WelcomeView: View {
    // MARK: - Properties
    @Binding var showWelcome: Bool
    @EnvironmentObject var appState: AppState
    
    // MARK: - Animation States
    @State private var iconScale: CGFloat = 0.3
    @State private var iconOpacity: Double = 0.0
    @State private var iconRotation: Double = -30
    @State private var titleOpacity: Double = 0.0
    @State private var titleOffset: CGFloat = 30
    @State private var descriptionOpacity: Double = 0.0
    @State private var buttonOpacity: Double = 0.0
    @State private var buttonOffset: CGFloat = 50
    @State private var floatingOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // MARK: - Background
            Color(red: 0.9, green: 0.96, blue: 0.9) // Light green tint
                .ignoresSafeArea()
            
            // Decorative circles
            Circle()
                .fill(Color.green.opacity(0.1))
                .frame(width: 300, height: 300)
                .offset(x: -150, y: -300)
            
            Circle()
                .fill(Color.green.opacity(0.08))
                .frame(width: 200, height: 200)
                .offset(x: 150, y: 400)
            
            // MARK: - Main Content
            VStack(spacing: 0) {
                Spacer()
                
                // MARK: - Icon Section
                ZStack {
                    // Background glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.green.opacity(0.3), Color.clear],
                                center: .center,
                                startRadius: 20,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                    
                    // Main camera icon
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 120, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.13, green: 0.55, blue: 0.13),
                                    Color.teal
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .green.opacity(0.3), radius: 20, x: 0, y: 10)
                }
                .scaleEffect(iconScale)
                .opacity(iconOpacity)
                .rotationEffect(.degrees(iconRotation))
                .offset(y: floatingOffset)
                
                Spacer()
                    .frame(height: 40)
                
                // MARK: - Title Section
                VStack(spacing: 16) {
                    Text("Welcome to AyurScan")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text("Use AI-powered skin analysis to get personalized skincare advice quickly and easily.")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 40)
                }
                .offset(y: titleOffset)
                .opacity(titleOpacity)
                
                Spacer()
                    .frame(height: 20)
                
                // MARK: - Features List
                VStack(spacing: 16) {
                    FeatureRow(
                        icon: "camera.fill",
                        title: "Scan Your Skin",
                        description: "Capture or upload skin images",
                        color: .blue
                    )
                    
                    FeatureRow(
                        icon: "brain.head.profile",
                        title: "AI Analysis",
                        description: "Get instant professional assessment",
                        color: .purple
                    )
                    
                    FeatureRow(
                        icon: "cross.case.fill",
                        title: "Find Hospitals",
                        description: "Locate nearby medical facilities",
                        color: .red
                    )
                }
                .padding(.horizontal, 30)
                .opacity(descriptionOpacity)
                
                Spacer()
                
                // MARK: - Get Started Button
                Button(action: {
                    // Haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                    
                    // Mark welcome as seen
                    appState.markWelcomeAsSeen()
                    
                    // Navigate to main app
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        showWelcome = false
                    }
                }) {
                    HStack(spacing: 12) {
                        Text("Get Started")
                            .font(.system(size: 19, weight: .semibold))
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 0.13, green: 0.55, blue: 0.13),
                                Color(red: 0.0, green: 0.5, blue: 0.0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: .green.opacity(0.4), radius: 15, x: 0, y: 8)
                }
                .padding(.horizontal, 40)
                .offset(y: buttonOffset)
                .opacity(buttonOpacity)
                
                Spacer()
                    .frame(height: 50)
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    // MARK: - Animation Functions
    private func startAnimations() {
        // Icon animation
        withAnimation(.spring(response: 0.9, dampingFraction: 0.6)) {
            iconScale = 1.0
            iconOpacity = 1.0
            iconRotation = 0
        }
        
        // Title animation
        withAnimation(.easeOut(duration: 0.7).delay(0.3)) {
            titleOpacity = 1.0
            titleOffset = 0
        }
        
        // Features animation
        withAnimation(.easeOut(duration: 0.6).delay(0.5)) {
            descriptionOpacity = 1.0
        }
        
        // Button animation
        withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.7)) {
            buttonOpacity = 1.0
            buttonOffset = 0
        }
        
        // Floating animation (continuous)
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true).delay(1.0)) {
            floatingOffset = -10
        }
    }
}

// MARK: - Feature Row Component
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(color)
                .frame(width: 50, height: 50)
                .background(color.opacity(0.15))
                .cornerRadius(12)
            
            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview
#Preview {
    WelcomeView(showWelcome: .constant(true))
        .environmentObject(AppState())
}
