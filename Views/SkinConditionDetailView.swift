// SkinConditionDetailView.swift
// Condition detail screen - equivalent to skin_condition_detail_screen.dart
// Location: AyurScan/Views/SkinConditionDetailView.swift

import SwiftUI

struct SkinConditionDetailView: View {
    // MARK: - Properties
    let condition: SkinCondition
    
    // Animation states
    @State private var headerOpacity: Double = 0
    @State private var contentOffset: CGFloat = 50
    @State private var contentOpacity: Double = 0
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // MARK: - Hero Image Section
                heroImageSection
                
                // MARK: - Content Section
                VStack(alignment: .leading, spacing: 24) {
                    // Title
                    Text(condition.name)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.teal)
                    
                    // Description Card
                    descriptionCard
                    
                    // Medicines Section
                    if !condition.medicines.isEmpty {
                        medicinesSection
                    }
                    
                    // Disclaimer
                    disclaimerCard
                }
                .padding(20)
                .offset(y: contentOffset)
                .opacity(contentOpacity)
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            startAnimations()
        }
    }
    
    // MARK: - Hero Image Section
    private var heroImageSection: some View {
        ZStack(alignment: .bottomLeading) {
            // Image
            AsyncImage(url: URL(string: condition.imageUrl)) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 280)
                        .overlay(ProgressView())
                    
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(height: 280)
                        .clipped()
                    
                case .failure:
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 280)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                        )
                    
                @unknown default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 280)
            
            // Gradient overlay
            LinearGradient(
                colors: [.clear, .black.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 150)
            .frame(maxWidth: .infinity, alignment: .bottom)
            
            // Condition name on image
            Text(condition.name)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .padding(20)
                .opacity(headerOpacity)
        }
        .clipShape(
            RoundedCornerShape(corners: [.bottomLeft, .bottomRight], radius: 24)
        )
        .shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: 8)
    }
    
    // MARK: - Description Card
    private var descriptionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.teal)
                
                Text("About This Condition")
                    .font(.system(size: 18, weight: .semibold))
            }
            
            // Description text
            Text(condition.description)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.08))
        .cornerRadius(16)
    }
    
    // MARK: - Medicines Section
    private var medicinesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack(spacing: 10) {
                Image(systemName: "pills.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.teal)
                
                Text("Recommended Medicines")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.teal)
            }
            
            // Medicine Cards
            ForEach(condition.medicines) { medicine in
                MedicineCard(medicine: medicine)
            }
        }
    }
    
    // MARK: - Disclaimer Card
    private var disclaimerCard: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 22))
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Disclaimer")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.orange)
                
                Text("This information is for educational purposes only. Always consult with a healthcare professional before starting any treatment. Some medicines may require a prescription.")
                    .font(.system(size: 14))
                    .foregroundColor(.orange.opacity(0.9))
                    .lineSpacing(4)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.12))
        .cornerRadius(14)
        .padding(.bottom, 30)
    }
    
    // MARK: - Animations
    private func startAnimations() {
        withAnimation(.easeOut(duration: 0.5)) {
            headerOpacity = 1.0
        }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
            contentOffset = 0
            contentOpacity = 1.0
        }
    }
}

// MARK: - Medicine Card Component
struct MedicineCard: View {
    let medicine: Medicine
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header (Always visible)
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
                
                // Haptic feedback
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
            }) {
                HStack(spacing: 14) {
                    // Medicine type icon
                    Image(systemName: medicineIcon)
                        .font(.system(size: 22))
                        .foregroundColor(medicineColor)
                        .frame(width: 50, height: 50)
                        .background(medicineColor.opacity(0.15))
                        .cornerRadius(12)
                    
                    // Medicine info
                    VStack(alignment: .leading, spacing: 6) {
                        Text(medicine.name)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                        
                        // Type badge
                        Text(medicine.type.uppercased())
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(medicineColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(medicineColor.opacity(0.15))
                            .cornerRadius(8)
                    }
                    
                    Spacer()
                    
                    // Expand/collapse icon
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.gray)
                        .rotationEffect(.degrees(isExpanded ? 0 : 0))
                }
                .padding(16)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expanded content
            if isExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    Divider()
                        .padding(.horizontal, 16)
                    
                    // Description
                    Text(medicine.description)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineSpacing(4)
                        .padding(.horizontal, 16)
                    
                    // Available at section
                    HStack(spacing: 8) {
                        Image(systemName: "storefront.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.teal)
                        
                        Text("Available at:")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .padding(.horizontal, 16)
                    
                    // Store buttons
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(medicine.links) { link in
                                StoreButton(link: link)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 16)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
    
    // Medicine type icon
    private var medicineIcon: String {
        switch medicine.type.lowercased() {
        case "topical":
            return "bandage.fill"
        case "oral":
            return "pills.fill"
        case "otc":
            return "cross.case.fill"
        default:
            return "pill.fill"
        }
    }
    
    // Medicine type color
    private var medicineColor: Color {
        switch medicine.type.lowercased() {
        case "topical":
            return .blue
        case "oral":
            return .green
        case "otc":
            return .orange
        default:
            return .teal
        }
    }
}

// MARK: - Store Button Component
struct StoreButton: View {
    let link: MedicineLink
    
    var body: some View {
        Link(destination: URL(string: link.url)!) {
            HStack(spacing: 8) {
                Image(systemName: storeIcon)
                    .font(.system(size: 14))
                
                Text(link.storeName)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(storeColor)
            .cornerRadius(10)
            .shadow(color: storeColor.opacity(0.4), radius: 6, x: 0, y: 3)
        }
    }
    
    // Store icon based on name
    private var storeIcon: String {
        let storeLower = link.storeName.lowercased()
        if storeLower.contains("amazon") {
            return "cart.fill"
        } else if storeLower.contains("flipkart") {
            return "bag.fill"
        } else {
            return "cross.case.fill"
        }
    }
    
    // Store color based on name
    private var storeColor: Color {
        let storeLower = link.storeName.lowercased()
        if storeLower.contains("amazon") {
            return Color(red: 0.14, green: 0.18, blue: 0.24)
        } else if storeLower.contains("flipkart") {
            return Color(red: 0.02, green: 0.49, blue: 0.84)
        } else if storeLower.contains("pharmeasy") {
            return Color(red: 0.06, green: 0.64, blue: 0.06)
        } else if storeLower.contains("apollo") {
            return Color(red: 0.0, green: 0.65, blue: 0.32)
        } else if storeLower.contains("netmeds") {
            return Color(red: 0.18, green: 0.49, blue: 0.2)
        } else if storeLower.contains("medplus") {
            return Color(red: 0.1, green: 0.46, blue: 0.82)
        } else if storeLower.contains("truemeds") {
            return Color(red: 0.56, green: 0.14, blue: 0.67)
        } else {
            return .teal
        }
    }
}

// MARK: - Custom Rounded Corner Shape
struct RoundedCornerShape: Shape {
    var corners: UIRectCorner
    var radius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        SkinConditionDetailView(condition: skinConditions[0])
    }
}
