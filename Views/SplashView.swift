// SplashView.swift
// Splash screen - equivalent to splash_screen.dart
// Location: AyurScan/Views/SplashView.swift

import SwiftUI

struct SplashView: View {
    // MARK: - Animation States
    @State private var iconScale: CGFloat = 0.5
    @State private var iconOpacity: Double = 0.0
    @State private var titleOffset: CGFloat = 50
    @State private var titleOpacity: Double = 0.0
    @State private var taglineOpacity: Double = 0.0
    @State private var pulseAnimation: Bool = false
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        ZStack {
            // MARK: - Background Gradient
            LinearGradient(
                colors: [
                    Color(red: 0.13, green: 0.55, blue: 0.13), // Dark green
                    Color(red: 0.0, green: 0.5, blue: 0.0),    // Green
                    Color(red: 0.13, green: 0.55, blue: 0.13)  // Dark green
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // MARK: - Animated Background Circles
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 300, height: 300)
                .offset(x: -100, y: -200)
                .blur(radius: 60)
            
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 250, height: 250)
                .offset(x: 150, y: 300)
                .blur(radius: 50)
            
            // MARK: - Main Content
            VStack(spacing: 24) {
                Spacer()
                
                // App Icon with animations
                ZStack {
                    // Pulsing background circle
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 140, height: 140)
                        .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                        .opacity(pulseAnimation ? 0.0 : 0.5)
                    
                    // Main icon
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 100))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.9)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                        .rotationEffect(.degrees(rotationAngle))
                }
                .scaleEffect(iconScale)
                .opacity(iconOpacity)
                
                // App Name
                Text("AyurScan")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(3)
                    .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 3)
                    .offset(y: titleOffset)
                    .opacity(titleOpacity)
                
                // Tagline
                Text("AI Powered Skin Analysis")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
                    .tracking(1)
                    .opacity(taglineOpacity)
                
                Spacer()
                
                // Loading indicator
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                    
                    Text("Loading...")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                .opacity(taglineOpacity)
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    // MARK: - Animation Functions
    private func startAnimations() {
        // Icon scale and fade in
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
            iconScale = 1.0
            iconOpacity = 1.0
        }
        
        // Small rotation effect
        withAnimation(.easeInOut(duration: 0.6).delay(0.2)) {
            rotationAngle = 5
        }
        withAnimation(.easeInOut(duration: 0.3).delay(0.5)) {
            rotationAngle = 0
        }
        
        // Title slide up and fade in
        withAnimation(.easeOut(duration: 0.6).delay(0.4)) {
            titleOffset = 0
            titleOpacity = 1.0
        }
        
        // Tagline fade in
        withAnimation(.easeIn(duration: 0.5).delay(0.8)) {
            taglineOpacity = 1.0
        }
        
        // Start pulse animation (repeating)
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false).delay(1.0)) {
            pulseAnimation = true
        }
    }
}

// MARK: - Preview
#Preview {
    SplashView()
}
