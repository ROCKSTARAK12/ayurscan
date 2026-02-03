// NearbyHospitalsView.swift
// Nearby hospitals finder screen - equivalent to nearby_hospitals_screen.dart
// Location: AyurScan/Views/NearbyHospitalsView.swift

import SwiftUI
import CoreLocation
import Combine

struct NearbyHospitalsView: View {
    // MARK: - State Properties
    @StateObject private var locationService = LocationService()
    
    @State private var hospitals: [Hospital] = []
    @State private var filteredHospitals: [Hospital] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var searchText = ""
    @State private var selectedFilter = "All"
    @State private var isRefreshing = false
    @State private var animateList = false
    
    // Filter options
    let filterOptions = ["All", "Emergency", "General", "Clinic", "Specialty"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.gray.opacity(0.05)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // MARK: - Search & Filter Section
                    searchAndFilterSection
                    
                    // MARK: - Stats Row
                    statsSection
                    
                    // MARK: - Content
                    if isLoading {
                        loadingView
                    } else if let error = errorMessage {
                        errorView(error)
                    } else if filteredHospitals.isEmpty {
                        emptyView
                    } else {
                        hospitalsListSection
                    }
                }
            }
            .navigationTitle("Nearby Hospitals")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: refreshHospitals) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16, weight: .medium))
                            .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                            .animation(
                                isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default,
                                value: isRefreshing
                            )
                    }
                    .disabled(isLoading)
                }
            }
        }
        .onAppear {
            locationService.requestPermission()
            loadHospitals()
        }
    }
    
    // MARK: - Search & Filter Section
    private var searchAndFilterSection: some View {
        VStack(spacing: 14) {
            // Search Bar
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18))
                    .foregroundColor(.gray)
                
                TextField("Search hospitals...", text: $searchText)
                    .font(.system(size: 16))
                    .onChange(of: searchText) { _, _ in
                        filterHospitals()
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        filterHospitals()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            
            // Filter Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(filterOptions, id: \.self) { option in
                        FilterChipHospital(
                            title: option,
                            isSelected: selectedFilter == option
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                selectedFilter = option
                                filterHospitals()
                            }
                            
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - Stats Section
    private var statsSection: some View {
        HStack(spacing: 0) {
            StatItemView(
                icon: "cross.circle.fill",
                value: "\(filteredHospitals.count)",
                label: "Found",
                color: .red
            )
            
            Spacer()
            
            StatItemView(
                icon: "location.circle.fill",
                value: "5km",
                label: "Radius",
                color: .blue
            )
            
            Spacer()
            
            StatItemView(
                icon: "staroflife.fill",
                value: "\(hospitals.filter { $0.type == "Emergency" }.count)",
                label: "Emergency",
                color: .orange
            )
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            LinearGradient(
                colors: [Color.red.opacity(0.08), Color.pink.opacity(0.08)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(18)
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ProgressView()
                .scaleEffect(1.5)
                .tint(.red)
            
            Text("Finding nearby hospitals...")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
    
    // MARK: - Error View
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("Oops! Something went wrong")
                .font(.system(size: 20, weight: .semibold))
            
            Text(error)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: {
                isLoading = true
                errorMessage = nil
                loadHospitals()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                    Text("Retry")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(Color.red)
                .cornerRadius(12)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Empty View
    private var emptyView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "building.2")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("No hospitals found")
                .font(.system(size: 20, weight: .semibold))
            
            Text("Try adjusting your search or filters")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
    
    // MARK: - Hospitals List Section
    private var hospitalsListSection: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 16) {
                ForEach(Array(filteredHospitals.enumerated()), id: \.element.id) { index, hospital in
                    HospitalCard(hospital: hospital)
                        .opacity(animateList ? 1 : 0)
                        .offset(y: animateList ? 0 : 30)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.8)
                            .delay(Double(index) * 0.05),
                            value: animateList
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Functions
    private func loadHospitals() {
        isLoading = true
        errorMessage = nil
        
        // Simulate API call (Replace with actual Overpass API call)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Sample data
            self.hospitals = [
                Hospital(
                    name: "Apollo Hospital",
                    latitude: 28.6139,
                    longitude: 77.2090,
                    distance: 850,
                    type: "General",
                    phone: "+91-11-2692-5858",
                    rating: 4.6
                ),
                Hospital(
                    name: "Max Emergency Care",
                    latitude: 28.6145,
                    longitude: 77.2095,
                    distance: 1200,
                    type: "Emergency",
                    phone: "+91-11-2651-5050",
                    rating: 4.8
                ),
                Hospital(
                    name: "Fortis Heart Institute",
                    latitude: 28.6150,
                    longitude: 77.2100,
                    distance: 2100,
                    type: "Specialty",
                    phone: "+91-11-4277-6222",
                    rating: 4.7
                ),
                Hospital(
                    name: "City Clinic",
                    latitude: 28.6155,
                    longitude: 77.2105,
                    distance: 650,
                    type: "Clinic",
                    phone: "+91-11-2345-6789",
                    rating: 4.2
                ),
                Hospital(
                    name: "AIIMS Emergency",
                    latitude: 28.6160,
                    longitude: 77.2110,
                    distance: 3500,
                    type: "Emergency",
                    phone: "+91-11-2658-8500",
                    rating: 4.9
                ),
                Hospital(
                    name: "Medanta Hospital",
                    latitude: 28.6165,
                    longitude: 77.2115,
                    distance: 4200,
                    type: "General",
                    phone: "+91-124-4141-414",
                    rating: 4.5
                ),
                Hospital(
                    name: "BLK Super Speciality",
                    latitude: 28.6170,
                    longitude: 77.2120,
                    distance: 2800,
                    type: "Specialty",
                    phone: "+91-11-3040-3040",
                    rating: 4.4
                )
            ]
            
            self.filteredHospitals = self.hospitals.sorted { $0.distance < $1.distance }
            self.isLoading = false
            
            withAnimation(.easeOut(duration: 0.3)) {
                self.animateList = true
            }
            
            // Haptic feedback
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        }
    }
    
    private func refreshHospitals() {
        isRefreshing = true
        animateList = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            loadHospitals()
            isRefreshing = false
        }
    }
    
    private func filterHospitals() {
        var result = hospitals
        
        // Search filter
        if !searchText.isEmpty {
            result = result.filter { hospital in
                hospital.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Type filter
        if selectedFilter != "All" {
            result = result.filter { $0.type == selectedFilter }
        }
        
        // Sort by distance
        filteredHospitals = result.sorted { $0.distance < $1.distance }
    }
}

// MARK: - Filter Chip for Hospitals
struct FilterChipHospital: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(
                    isSelected
                        ? AnyShapeStyle(Color.red)
                        : AnyShapeStyle(Color.white)
                )
                .cornerRadius(20)
                .shadow(
                    color: isSelected ? .red.opacity(0.3) : .black.opacity(0.05),
                    radius: isSelected ? 8 : 4,
                    x: 0,
                    y: isSelected ? 4 : 2
                )
        }
    }
}

// MARK: - Stat Item View
struct StatItemView: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.15))
                .cornerRadius(12)
            
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Hospital Card Component
struct HospitalCard: View {
    let hospital: Hospital
    
    var body: some View {
        VStack(spacing: 14) {
            // Header Row
            HStack(spacing: 14) {
                // Hospital type icon
                Image(systemName: hospitalIcon)
                    .font(.system(size: 24))
                    .foregroundColor(typeColor)
                    .frame(width: 54, height: 54)
                    .background(typeColor.opacity(0.15))
                    .cornerRadius(14)
                
                // Hospital info
                VStack(alignment: .leading, spacing: 6) {
                    Text(hospital.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    HStack(spacing: 14) {
                        // Distance
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 12))
                            Text(formatDistance(hospital.distance))
                                .font(.system(size: 13))
                        }
                        .foregroundColor(.secondary)
                        
                        // Rating
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.orange)
                            Text(String(format: "%.1f", hospital.rating))
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Type badge
                Text(hospital.type)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(typeColor)
                    .cornerRadius(10)
            }
            
            // Action Buttons Row
            HStack(spacing: 10) {
                // Directions Button
                Button(action: openDirections) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                            .font(.system(size: 14))
                        Text("Directions")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                
                // Call Button
                if !hospital.phone.isEmpty {
                    Button(action: callHospital) {
                        HStack(spacing: 8) {
                            Image(systemName: "phone.fill")
                                .font(.system(size: 14))
                            Text("Call")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(width: 100)
                        .frame(height: 42)
                        .background(Color.green)
                        .cornerRadius(10)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
    }
    
    // Hospital type icon
    private var hospitalIcon: String {
        switch hospital.type {
        case "Emergency":
            return "staroflife.fill"
        case "Specialty":
            return "heart.circle.fill"
        case "Clinic":
            return "cross.case.fill"
        default:
            return "building.2.fill"
        }
    }
    
    // Hospital type color
    private var typeColor: Color {
        switch hospital.type {
        case "Emergency":
            return .red
        case "Specialty":
            return .purple
        case "Clinic":
            return .orange
        default:
            return .blue
        }
    }
    
    // Format distance
    private func formatDistance(_ meters: Double) -> String {
        if meters < 1000 {
            return "\(Int(meters))m"
        } else {
            return String(format: "%.1fkm", meters / 1000)
        }
    }
    
    // Open directions in Maps
    private func openDirections() {
        let latitude = hospital.latitude
        let longitude = hospital.longitude
        
        if let url = URL(string: "maps://?daddr=\(latitude),\(longitude)") {
            UIApplication.shared.open(url)
        }
        
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
    
    // Call hospital
    private func callHospital() {
        let phone = hospital.phone.replacingOccurrences(of: "-", with: "")
        if let url = URL(string: "tel://\(phone)") {
            UIApplication.shared.open(url)
        }
        
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
}

// MARK: - Preview
#Preview {
    NearbyHospitalsView()
}
