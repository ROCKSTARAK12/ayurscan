import SwiftUI

struct GlassCard<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat
    var opacity: Double
    var shadowRadius: CGFloat
    var shadowY: CGFloat
    
    init(
        cornerRadius: CGFloat = 20,
        opacity: Double = 0.1,
        shadowRadius: CGFloat = 10,
        shadowY: CGFloat = 5,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.opacity = opacity
        self.shadowRadius = shadowRadius
        self.shadowY = shadowY
        self.content = content()
    }
    
    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.5),
                                        Color.white.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(color: .black.opacity(opacity), radius: shadowRadius, x: 0, y: shadowY)
    }
}

struct GlassCardStyle: ViewModifier {
    var cornerRadius: CGFloat = 20
    var opacity: Double = 0.1
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(opacity), radius: 10, x: 0, y: 5)
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 20, opacity: Double = 0.1) -> some View {
        self.modifier(GlassCardStyle(cornerRadius: cornerRadius, opacity: opacity))
    }
}

struct GradientGlassCard<Content: View>: View {
    let content: Content
    var colors: [Color]
    var cornerRadius: CGFloat
    
    init(
        colors: [Color] = [.blue, .purple],
        cornerRadius: CGFloat = 20,
        @ViewBuilder content: () -> Content
    ) {
        self.colors = colors
        self.cornerRadius = cornerRadius
        self.content = content()
    }
    
    var body: some View {
        content
            .background(
                ZStack {
                    LinearGradient(
                        colors: colors.map { $0.opacity(0.3) },
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                colors.first?.opacity(0.6) ?? .white.opacity(0.6),
                                colors.last?.opacity(0.2) ?? .white.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: colors.first?.opacity(0.3) ?? .black.opacity(0.1), radius: 15, x: 0, y: 8)
    }
}

#Preview {
    ZStack {
        LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
        
        VStack(spacing: 20) {
            GlassCard {
                Text("Glass Card")
                    .padding(20)
            }
            
            GradientGlassCard(colors: [.pink, .orange]) {
                Text("Gradient Glass")
                    .padding(20)
            }
            
            Text("Using Modifier")
                .padding(20)
                .glassCard()
        }
    }
}
