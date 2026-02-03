import SwiftUI

struct SkinConditionsView: View {
    @State private var searchText = ""
    @State private var selectedCategory = "All"
    @State private var animateList = false
    
    let categories = ["All", "Common", "Chronic", "Infections", "Allergic"]
    
    var filteredConditions: [SkinCondition] {
        var result = skinConditions
        
        if !searchText.isEmpty {
            result = result.filter { condition in
                condition.name.localizedCaseInsensitiveContains(searchText) ||
                condition.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        if selectedCategory != "All" {
            result = result.filter { $0.category == selectedCategory }
        }
        
        return result
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.gray.opacity(0.06)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    searchBarSection
                    categoryFilterSection
                    
                    if filteredConditions.isEmpty {
                        emptyStateView
                    } else {
                        conditionsListSection
                    }
                }
            }
            .navigationTitle("Skin Conditions")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                animateList = true
            }
        }
    }
    
    private var searchBarSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18))
                .foregroundColor(.gray)
            
            TextField("Search skin conditions...", text: $searchText)
                .font(.system(size: 16))
                .autocorrectionDisabled()
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private var categoryFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(categories, id: \.self) { category in
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            selectedCategory = category
                        }
                    }) {
                        Text(category)
                            .font(.system(size: 14, weight: selectedCategory == category ? .semibold : .medium))
                            .foregroundColor(selectedCategory == category ? .white : .primary)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(
                                selectedCategory == category
                                    ? AnyShapeStyle(LinearGradient(colors: [.teal, .green], startPoint: .leading, endPoint: .trailing))
                                    : AnyShapeStyle(Color.white)
                            )
                            .cornerRadius(20)
                            .shadow(color: selectedCategory == category ? .teal.opacity(0.3) : .black.opacity(0.05), radius: 8, x: 0, y: 4)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            Text("No conditions found")
                .font(.system(size: 20, weight: .semibold))
            Text("Try a different search term")
                .font(.system(size: 15))
                .foregroundColor(.secondary)
            Spacer()
        }
    }
    
    private var conditionsListSection: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 16) {
                ForEach(Array(filteredConditions.enumerated()), id: \.element.id) { index, condition in
                    NavigationLink(destination: SkinConditionDetailView(condition: condition)) {
                        SkinConditionCardView(condition: condition)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .opacity(animateList ? 1 : 0)
                    .offset(y: animateList ? 0 : 30)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.05), value: animateList)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
    }
}

struct SkinConditionCardView: View {
    let condition: SkinCondition
    
    var body: some View {
        HStack(spacing: 16) {
            AsyncImage(url: URL(string: condition.imageUrl)) { phase in
                switch phase {
                case .empty:
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 100, height: 90)
                        .overlay(ProgressView().scaleEffect(0.8))
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 90)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                case .failure:
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 100, height: 90)
                        .overlay(Image(systemName: "photo").font(.system(size: 24)).foregroundColor(.gray))
                @unknown default:
                    EmptyView()
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(condition.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(String(condition.description.prefix(80)) + "...")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                if !condition.medicines.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "pills.fill").font(.system(size: 11))
                        Text("\(condition.medicines.count) medicines").font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.teal)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.teal.opacity(0.12))
                    .cornerRadius(8)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.teal)
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}

#Preview {
    SkinConditionsView()
}
