// NearbyHospitalsView.swift
// Find Nearby Dermatologists & Skin Clinics
// Location: AyurScan/Views/NearbyHospitalsView.swift

import SwiftUI
import CoreLocation

struct NearbyHospitalsView: View {
    @StateObject private var locationService = LocationService.shared
    @StateObject private var hospitalService = HospitalService.shared
    
    @State private var hospitals: [Hospital] = []
    @State private var filteredHospitals: [Hospital] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var searchText = ""
    @State private var selectedFilter = "All"
    @State private var isRefreshing = false
    @State private var animateList = false
    @State private var showLocationAlert = false
    
    let filterOptions = ["All", "Dermatologist", "Cosmetic", "Hospital", "Clinic"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color.teal.opacity(0.05), Color.white],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Location Header
                    locationHeaderSection
                    
                    // Search & Filter
                    searchAndFilterSection
                    
                    // Stats
                    statsSection
                    
                    // Content
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
            .navigationTitle("Find Dermatologists")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: refreshHospitals) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16, weight: .medium))
                            .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                            .animation(isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isRefreshing)
                    }
                    .disabled(isLoading)
                }
            }
            .alert("Location Required", isPresented: $showLocationAlert) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Please enable location access in Settings to find dermatologists near you.")
            }
        }
        .onAppear {
            checkLocationAndLoad()
        }
        .onChange(of: locationService.currentLocation) { _, newLocation in
            if newLocation != nil && hospitals.isEmpty {
                loadHospitals()
            }
        }
    }
    
    // MARK: - Location Header
    private var locationHeaderSection: some View {
        HStack(spacing: 12) {
            // Location Icon
            ZStack {
                Circle()
                    .fill(locationService.isAuthorized ? Color.teal.opacity(0.15) : Color.red.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: locationService.isAuthorized ? "location.fill" : "location.slash.fill")
                    .font(.system(size: 18))
                    .foregroundColor(locationService.isAuthorized ? .teal : .red)
            }
            
            // Location Info
            VStack(alignment: .leading, spacing: 4) {
                Text("Your Location")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                Text(locationService.currentCity)
                    .font(.system(size: 16, weight: .semibold))
                
                if !locationService.currentAddress.isEmpty {
                    Text(locationService.currentAddress)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Refresh Location serive
            if locationService.isAuthorized {
                Button {
                    locationService.getCurrentLocation()
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 14))
                        .foregroundColor(.teal)
                        .padding(10)
                        .background(Color.teal.opacity(0.1))
                        .cornerRadius(10)
                }
            } else {
                Button {
                    showLocationAlert = true
                } label: {
                    Text("Enable")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.teal)
                        .cornerRadius(8)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
    
    // MARK: - Search & Filter
    private var searchAndFilterSection: some View {
        VStack(spacing: 12) {
            // Search Bar
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search dermatologists...", text: $searchText)
                    .font(.system(size: 15))
                    .onChange(of: searchText) { _, _ in filterHospitals() }
                
                if !searchText.isEmpty {
                    Button { searchText = ""; filterHospitals() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(14)
            .background(Color.white)
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
            
            // Filter Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(filterOptions, id: \.self) { option in
                        FilterChip(
                            title: option,
                            icon: getFilterIcon(option),
                            isSelected: selectedFilter == option,
                            color: getFilterColor(option)
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                selectedFilter = option
                                filterHospitals()
                            }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
            StatBox(
                icon: "stethoscope",
                value: "\(filteredHospitals.filter { $0.type == "Dermatologist" }.count)",
                label: "Dermatologists",
                color: .teal
            )
            
            Spacer()
            
            StatBox(
                icon: "mappin.circle.fill",
                value: "10km",
                label: "Search Radius",
                color: .blue
            )
            
            Spacer()
            
            StatBox(
                icon: "cross.circle.fill",
                value: "\(filteredHospitals.count)",
                label: "Total Found",
                color: .orange
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            LinearGradient(
                colors: [Color.teal.opacity(0.08), Color.blue.opacity(0.08)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(16)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ZStack {
                Circle()
                    .stroke(Color.teal.opacity(0.2), lineWidth: 4)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(Color.teal, lineWidth: 4)
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(isLoading ? 360 : 0))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isLoading)
            }
            
            Text("Finding dermatologists near you...")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
    
    // MARK: - Error View
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "location.slash.fill")
                .font(.system(size: 60))
                .foregroundColor(.red.opacity(0.6))
            
            Text("Location Required")
                .font(.system(size: 20, weight: .semibold))
            
            Text(error)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "gearshape.fill")
                    Text("Open Settings")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(Color.teal)
                .cornerRadius(12)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Empty View
    private var emptyView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "stethoscope")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("No dermatologists found")
                .font(.system(size: 20, weight: .semibold))
            
            Text("Try adjusting your search or filters")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
    
    // MARK: - Hospitals List
    private var hospitalsListSection: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 14) {
                ForEach(Array(filteredHospitals.enumerated()), id: \.element.id) { index, hospital in
                    DermatologistCard(hospital: hospital)
                        .opacity(animateList ? 1 : 0)
                        .offset(y: animateList ? 0 : 30)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.05),
                            value: animateList
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Functions
    
    private func checkLocationAndLoad() {
        if locationService.isAuthorized {
            if locationService.currentLocation != nil {
                loadHospitals()
            } else {
                locationService.getCurrentLocation()
            }
        } else {
            locationService.requestPermission()
            isLoading = false
            errorMessage = "Please enable location access to find nearby dermatologists."
        }
    }
    
    private func loadHospitals() {
        guard let location = locationService.currentLocation else {
            errorMessage = "Unable to get your location"
            isLoading = false
            return
        }
        
        isLoading = true
        errorMessage = nil
        animateList = false
        
        Task {
            await hospitalService.loadHospitals(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
            
            await MainActor.run {
                hospitals = hospitalService.hospitals
                filteredHospitals = hospitals
                isLoading = false
                
                withAnimation(.easeOut(duration: 0.3)) {
                    animateList = true
                }
                
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }
    }
    
    private func refreshHospitals() {
        isRefreshing = true
        animateList = false
        locationService.getCurrentLocation()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            loadHospitals()
            isRefreshing = false
        }
    }
    
    private func filterHospitals() {
        var result = hospitals
        
        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        if selectedFilter != "All" {
            result = result.filter { $0.type == selectedFilter }
        }
        
        filteredHospitals = result.sorted { $0.distance < $1.distance }
    }
    
    private func getFilterIcon(_ filter: String) -> String {
        switch filter {
        case "Dermatologist": return "stethoscope"
        case "Cosmetic": return "sparkles"
        case "Hospital": return "building.2.fill"
        case "Clinic": return "cross.case.fill"
        default: return "square.grid.2x2.fill"
        }
    }
    
    private func getFilterColor(_ filter: String) -> Color {
        switch filter {
        case "Dermatologist": return .teal
        case "Cosmetic": return .pink
        case "Hospital": return .blue
        case "Clinic": return .orange
        default: return .gray
        }
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isSelected ? color : Color.white)
            .cornerRadius(20)
            .shadow(color: isSelected ? color.opacity(0.3) : .black.opacity(0.05), radius: isSelected ? 8 : 4, y: isSelected ? 4 : 2)
        }
    }
}

// MARK: - Stat Box
struct StatBox: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
            
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Dermatologist Card
struct DermatologistCard: View {
    let hospital: Hospital
    
    var body: some View {
        VStack(spacing: 14) {
            // Header
            HStack(spacing: 14) {
                // Icon
                Image(systemName: hospital.typeIcon)
                    .font(.system(size: 24))
                    .foregroundColor(hospital.typeColor)
                    .frame(width: 54, height: 54)
                    .background(hospital.typeColor.opacity(0.15))
                    .cornerRadius(14)
                
                // Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(hospital.name)
                        .font(.system(size: 16, weight: .semibold))
                        .lineLimit(2)
                    
                    HStack(spacing: 12) {
                        // Distance
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 11))
                            Text(hospital.formattedDistance)
                                .font(.system(size: 12))
                        }
                        .foregroundColor(.secondary)
                        
                        // Rating
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.orange)
                            Text(hospital.formattedRating)
                                .font(.system(size: 12))
                        }
                        .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Type Badge
                Text(hospital.type)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(hospital.typeColor)
                    .cornerRadius(10)
            }
            
            // Action Buttons
            HStack(spacing: 10) {
                // Directions
                Button { openDirections() } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                            .font(.system(size: 13))
                        Text("Directions")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                
                // Call
                if !hospital.phone.isEmpty {
                    Button { callHospital() } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "phone.fill")
                                .font(.system(size: 13))
                            Text("Call")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(width: 90)
                        .frame(height: 40)
                        .background(Color.green)
                        .cornerRadius(10)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
    }
    
    private func openDirections() {
        if let url = hospital.mapsURL {
            UIApplication.shared.open(url)
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    
    private func callHospital() {
        if let url = hospital.phoneURL {
            UIApplication.shared.open(url)
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

#Preview {
    NearbyHospitalsView()
}
