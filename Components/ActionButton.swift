import SwiftUI

struct GradientButton: View {
    let title: String
    var icon: String?
    var colors: [Color]
    var height: CGFloat
    var cornerRadius: CGFloat
    var isLoading: Bool
    var isDisabled: Bool
    var action: () -> Void
    
    init(
        title: String,
        icon: String? = nil,
        colors: [Color] = [.blue, .blue.opacity(0.8)],
        height: CGFloat = 50,
        cornerRadius: CGFloat = 14,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.colors = colors
        self.height = height
        self.cornerRadius = cornerRadius
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            if !isDisabled && !isLoading {
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
                action()
            }
        }) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: height > 55 ? 20 : 16))
                }
                
                Text(title)
                    .font(.system(size: height > 55 ? 18 : 14, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(
                LinearGradient(
                    colors: (isDisabled || isLoading) ? [.gray, .gray.opacity(0.8)] : colors,
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(cornerRadius)
            .shadow(
                color: (isDisabled || isLoading) ? .clear : colors.first?.opacity(0.4) ?? .clear,
                radius: 8,
                x: 0,
                y: 4
            )
        }
        .disabled(isDisabled || isLoading)
    }
}

struct IconButton: View {
    let icon: String
    var size: CGFloat
    var iconSize: CGFloat
    var color: Color
    var backgroundColor: Color?
    var action: () -> Void
    
    init(
        icon: String,
        size: CGFloat = 44,
        iconSize: CGFloat = 18,
        color: Color = .blue,
        backgroundColor: Color? = nil,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.size = size
        self.iconSize = iconSize
        self.color = color
        self.backgroundColor = backgroundColor
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            action()
        }) {
            Image(systemName: icon)
                .font(.system(size: iconSize))
                .foregroundColor(color)
                .frame(width: size, height: size)
                .background(backgroundColor ?? color.opacity(0.15))
                .cornerRadius(size / 3.5)
        }
    }
}

struct CompactActionButton: View {
    let title: String
    let icon: String
    var colors: [Color]
    var isDisabled: Bool
    var action: () -> Void
    
    init(
        title: String,
        icon: String,
        colors: [Color] = [.blue, .blue.opacity(0.8)],
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.colors = colors
        self.isDisabled = isDisabled
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            if !isDisabled {
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
                action()
            }
        }) {
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
                color: isDisabled ? .clear : colors.first?.opacity(0.4) ?? .clear,
                radius: 8,
                x: 0,
                y: 4
            )
        }
        .disabled(isDisabled)
    }
}

struct OutlineButton: View {
    let title: String
    var icon: String?
    var color: Color
    var height: CGFloat
    var action: () -> Void
    
    init(
        title: String,
        icon: String? = nil,
        color: Color = .blue,
        height: CGFloat = 50,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.color = color
        self.height = height
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            action()
        }) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                }
                
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(color.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color, lineWidth: 1.5)
            )
            .cornerRadius(12)
        }
    }
}

struct PulsingButton: View {
    let title: String
    let icon: String
    var colors: [Color]
    var action: () -> Void
    
    @State private var isPulsing = false
    
    init(
        title: String,
        icon: String,
        colors: [Color] = [.green, .teal],
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.colors = colors
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            action()
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
                        )
                    
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
                        )
                        .scaleEffect(isPulsing ? 1.05 : 1.0)
                        .opacity(isPulsing ? 0 : 0.5)
                }
            )
            .cornerRadius(16)
            .shadow(color: colors.first?.opacity(0.4) ?? .clear, radius: 12, x: 0, y: 6)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        GradientButton(title: "Primary Button", icon: "arrow.right", colors: [.blue, .purple]) {}
        
        GradientButton(title: "Loading...", isLoading: true) {}
        
        GradientButton(title: "Disabled", isDisabled: true) {}
        
        HStack(spacing: 12) {
            CompactActionButton(title: "Camera", icon: "camera.fill", colors: [.blue, .cyan]) {}
            CompactActionButton(title: "Gallery", icon: "photo.fill", colors: [.green, .mint]) {}
            CompactActionButton(title: "Settings", icon: "gearshape.fill", colors: [.purple, .pink]) {}
        }
        
        OutlineButton(title: "Outline Button", icon: "plus") {}
        
        PulsingButton(title: "Start Analysis", icon: "brain.head.profile") {}
        
        HStack(spacing: 12) {
            IconButton(icon: "heart.fill", color: .red) {}
            IconButton(icon: "star.fill", color: .orange) {}
            IconButton(icon: "bookmark.fill", color: .blue) {}
        }
    }
    .padding()
}
