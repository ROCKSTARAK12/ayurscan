// AnalysisResultView.swift
// Professional Medical Analysis Result UI
// Location: AyurScan/Views/AnalysisResultView.swift

import SwiftUI

// MARK: - Structured Analysis Data Model
struct SkinAnalysisResult: Codable {
    let observedCondition: ObservedCondition
    let possibleConditions: [PossibleCondition]
    let severity: SeverityLevel
    let recommendedActions: [String]
    let ayurvedicRemedies: [AyurvedicRemedy]
    let skincareTips: [String]
    let disclaimer: String
    
    struct ObservedCondition: Codable {
        let summary: String
        let details: [String]
    }
    
    struct PossibleCondition: Codable, Identifiable {
        var id: String { name }
        let name: String
        let probability: Int // percentage
        let description: String
    }
    
    struct SeverityLevel: Codable {
        let level: String // Healthy, Mild, Moderate, Severe
        let score: Int // 1-10
        let description: String
    }
    
    struct AyurvedicRemedy: Codable, Identifiable {
        var id: String { name }
        let name: String
        let ingredients: [String]
        let instructions: String
        let benefits: String
    }
}

// MARK: - Main Analysis Result View
struct AnalysisResultView: View {
    let analysisResult: SkinAnalysisResult
    let image: UIImage?
    let onDismiss: () -> Void
    
    @State private var animateCards = false
    @State private var selectedTab = 0
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Header with Image
                headerSection
                
                // Severity Card
                severityCard
                    .offset(y: animateCards ? 0 : 30)
                    .opacity(animateCards ? 1 : 0)
                
                // Tab Selector
                tabSelector
                    .offset(y: animateCards ? 0 : 30)
                    .opacity(animateCards ? 1 : 0)
                
                // Content based on selected tab
                Group {
                    switch selectedTab {
                    case 0:
                        conditionsSection
                    case 1:
                        ayurvedicSection
                    case 2:
                        actionsSection
                    default:
                        conditionsSection
                    }
                }
                .offset(y: animateCards ? 0 : 30)
                .opacity(animateCards ? 1 : 0)
                
                // Disclaimer
                disclaimerCard
                    .offset(y: animateCards ? 0 : 30)
                    .opacity(animateCards ? 1 : 0)
                
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Analysis Report")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") { onDismiss() }
                    .fontWeight(.semibold)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                animateCards = true
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Analysis Image
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.teal.opacity(0.3), lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
            }
            
            // Title
            HStack {
                Image(systemName: "stethoscope")
                    .font(.title2)
                    .foregroundColor(.teal)
                
                Text("AI Dermatological Report")
                    .font(.title2.bold())
                
                Spacer()
                
                // Verified Badge
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                    Text("Verified")
                        .font(.caption.bold())
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.green.opacity(0.15))
                .cornerRadius(20)
            }
        }
    }
    
    // MARK: - Severity Card
    private var severityCard: some View {
        GlassCard(cornerRadius: 20) {
            VStack(spacing: 16) {
                HStack {
                    Text("Severity Assessment")
                        .font(.headline)
                    Spacer()
                    severityBadge
                }
                
                // Severity Meter
                VStack(alignment: .leading, spacing: 8) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 12)
                            
                            // Fill
                            RoundedRectangle(cornerRadius: 10)
                                .fill(severityGradient)
                                .frame(width: geo.size.width * CGFloat(analysisResult.severity.score) / 10, height: 12)
                        }
                    }
                    .frame(height: 12)
                    
                    // Scale labels
                    HStack {
                        Text("Healthy")
                            .font(.caption2)
                            .foregroundColor(.green)
                        Spacer()
                        Text("Mild")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                        Spacer()
                        Text("Moderate")
                            .font(.caption2)
                            .foregroundColor(.orange)
                        Spacer()
                        Text("Severe")
                            .font(.caption2)
                            .foregroundColor(.red)
                    }
                }
                
                Text(analysisResult.severity.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(20)
        }
    }
    
    private var severityBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(severityColor)
                .frame(width: 10, height: 10)
            Text(analysisResult.severity.level.uppercased())
                .font(.caption.bold())
                .foregroundColor(severityColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(severityColor.opacity(0.15))
        .cornerRadius(20)
    }
    
    private var severityColor: Color {
        switch analysisResult.severity.level.lowercased() {
        case "healthy": return .green
        case "mild": return .yellow
        case "moderate": return .orange
        case "severe": return .red
        default: return .gray
        }
    }
    
    private var severityGradient: LinearGradient {
        LinearGradient(
            colors: [.green, .yellow, .orange, .red],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    // MARK: - Tab Selector
    private var tabSelector: some View {
        HStack(spacing: 0) {
            tabButton(title: "Conditions", icon: "stethoscope", index: 0)
            tabButton(title: "Ayurvedic", icon: "leaf.fill", index: 1)
            tabButton(title: "Actions", icon: "checklist", index: 2)
        }
        .padding(4)
        .background(Color.gray.opacity(0.15))
        .cornerRadius(12)
    }
    
    private func tabButton(title: String, icon: String, index: Int) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                selectedTab = index
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundColor(selectedTab == index ? .white : .primary)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(
                selectedTab == index ? Color.teal : Color.clear
            )
            .cornerRadius(10)
        }
    }
    
    // MARK: - Conditions Section
    private var conditionsSection: some View {
        VStack(spacing: 16) {
            // Observed Condition
            GlassCard(cornerRadius: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "eye.fill")
                            .foregroundColor(.teal)
                        Text("Observed Condition")
                            .font(.headline)
                    }
                    
                    Text(analysisResult.observedCondition.summary)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    ForEach(analysisResult.observedCondition.details, id: \.self) { detail in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 6))
                                .foregroundColor(.teal)
                                .padding(.top, 6)
                            Text(detail)
                                .font(.subheadline)
                        }
                    }
                }
                .padding(16)
            }
            
            // Possible Conditions
            GlassCard(cornerRadius: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "list.clipboard.fill")
                            .foregroundColor(.blue)
                        Text("Possible Conditions")
                            .font(.headline)
                    }
                    
                    ForEach(analysisResult.possibleConditions) { condition in
                        conditionRow(condition)
                    }
                }
                .padding(16)
            }
        }
    }
    
    private func conditionRow(_ condition: SkinAnalysisResult.PossibleCondition) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(condition.name)
                    .font(.subheadline.bold())
                
                Spacer()
                
                // Probability Badge
                Text("\(condition.probability)%")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(probabilityColor(condition.probability))
                    .cornerRadius(12)
            }
            
            // Probability Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(probabilityColor(condition.probability))
                        .frame(width: geo.size.width * CGFloat(condition.probability) / 100, height: 6)
                }
            }
            .frame(height: 6)
            
            Text(condition.description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(Color.gray.opacity(0.08))
        .cornerRadius(12)
    }
    
    private func probabilityColor(_ probability: Int) -> Color {
        if probability >= 70 { return .red }
        if probability >= 40 { return .orange }
        return .green
    }
    
    // MARK: - Ayurvedic Section
    private var ayurvedicSection: some View {
        VStack(spacing: 16) {
            ForEach(analysisResult.ayurvedicRemedies) { remedy in
                GlassCard(cornerRadius: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "leaf.fill")
                                .foregroundColor(.green)
                                .padding(8)
                                .background(Color.green.opacity(0.15))
                                .cornerRadius(10)
                            
                            VStack(alignment: .leading) {
                                Text(remedy.name)
                                    .font(.headline)
                                Text(remedy.benefits)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Divider()
                        
                        // Ingredients
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Ingredients")
                                .font(.subheadline.bold())
                                .foregroundColor(.teal)
                            
                            FlowLayout(spacing: 8) {
                                ForEach(remedy.ingredients, id: \.self) { ingredient in
                                    Text(ingredient)
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color.teal.opacity(0.1))
                                        .cornerRadius(8)
                                }
                            }
                        }
                        
                        // Instructions
                        VStack(alignment: .leading, spacing: 6) {
                            Text("How to Use")
                                .font(.subheadline.bold())
                                .foregroundColor(.orange)
                            
                            Text(remedy.instructions)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(16)
                }
            }
        }
    }
    
    // MARK: - Actions Section
    private var actionsSection: some View {
        VStack(spacing: 16) {
            // Recommended Actions
            GlassCard(cornerRadius: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "checklist")
                            .foregroundColor(.blue)
                        Text("Recommended Actions")
                            .font(.headline)
                    }
                    
                    ForEach(Array(analysisResult.recommendedActions.enumerated()), id: \.offset) { index, action in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(index + 1)")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24)
                                .background(Color.blue)
                                .cornerRadius(12)
                            
                            Text(action)
                                .font(.subheadline)
                        }
                    }
                }
                .padding(16)
            }
            
            // Skincare Tips
            GlassCard(cornerRadius: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.purple)
                        Text("Skincare Tips")
                            .font(.headline)
                    }
                    
                    ForEach(analysisResult.skincareTips, id: \.self) { tip in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                            Text(tip)
                                .font(.subheadline)
                        }
                    }
                }
                .padding(16)
            }
        }
    }
    
    // MARK: - Disclaimer Card
    private var disclaimerCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Important Disclaimer")
                    .font(.subheadline.bold())
                    .foregroundColor(.orange)
                
                Text(analysisResult.disclaimer)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(16)
    }
}

// MARK: - Flow Layout for Tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in width: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > width, x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: width, height: y + rowHeight)
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        AnalysisResultView(
            analysisResult: SkinAnalysisResult(
                observedCondition: .init(
                    summary: "Multiple inflammatory papules and pustules visible on cheeks and forehead",
                    details: [
                        "Red, inflamed papules on cheeks",
                        "Open comedones (blackheads) on nose",
                        "Mild erythema around affected areas",
                        "Skin texture appears uneven"
                    ]
                ),
                possibleConditions: [
                    .init(name: "Acne Vulgaris", probability: 85, description: "Common inflammatory skin condition"),
                    .init(name: "Rosacea", probability: 10, description: "Chronic skin condition causing redness"),
                    .init(name: "Contact Dermatitis", probability: 5, description: "Allergic skin reaction")
                ],
                severity: .init(level: "Mild", score: 3, description: "Condition is manageable with proper skincare routine"),
                recommendedActions: [
                    "Consult a dermatologist for proper diagnosis",
                    "Use gentle, non-comedogenic cleanser twice daily",
                    "Avoid touching or picking at affected areas",
                    "Stay hydrated and maintain balanced diet"
                ],
                ayurvedicRemedies: [
                    .init(
                        name: "Neem Face Pack",
                        ingredients: ["Neem powder", "Rose water", "Turmeric"],
                        instructions: "Mix ingredients to form paste. Apply for 15 mins, rinse with cold water.",
                        benefits: "Antibacterial & anti-inflammatory"
                    ),
                    .init(
                        name: "Aloe Vera Gel",
                        ingredients: ["Fresh aloe vera", "Honey"],
                        instructions: "Apply fresh gel directly to affected areas overnight.",
                        benefits: "Soothes inflammation & promotes healing"
                    )
                ],
                skincareTips: [
                    "Always remove makeup before sleeping",
                    "Use SPF 30+ sunscreen daily",
                    "Change pillowcase weekly",
                    "Avoid dairy and high-sugar foods"
                ],
                disclaimer: "This AI analysis is for informational purposes only and does NOT replace professional medical advice. Always consult a board-certified dermatologist for accurate diagnosis."
            ),
            image: nil,
            onDismiss: {}
        )
    }
}
