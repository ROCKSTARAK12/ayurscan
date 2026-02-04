import SwiftUI

// MARK: - Doctor Model
struct Doctor: Identifiable {
    let id = UUID()
    let name: String
    let specialty: String
    let image: String
    let isOnline: Bool
    let experience: String
    let rating: Double
    let responses: [String]
}

// MARK: - Message Model
struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isFromUser: Bool
    let timestamp: Date
}

// MARK: - Doctors List View (WhatsApp Style)
struct DoctorsListView: View {
    let doctors: [Doctor] = [
        Doctor(
            name: "Dr. Priya Sharma",
            specialty: "Dermatologist",
            image: "person.circle.fill",
            isOnline: true,
            experience: "12 yrs exp",
            rating: 4.9,
            responses: [
                "Hello! I've reviewed your skin concern. Based on what you've described, it sounds like it could be a common inflammatory condition. Can you tell me how long you've had these symptoms?",
                "I understand. For immediate relief, I'd recommend using a gentle, fragrance-free moisturizer and avoiding harsh soaps. Have you noticed any triggers like stress or certain foods?",
                "That's helpful information. I'd suggest trying a mild hydrocortisone cream (1%) for a few days. If there's no improvement in a week, we should consider other options. Are you currently using any skincare products?",
                "Good to know. Please avoid any products with alcohol or fragrances for now. Keep the affected area clean and dry. Would you like me to suggest some Ayurvedic remedies as well?",
                "For natural treatment, you can try applying fresh aloe vera gel twice daily. Neem paste mixed with turmeric is also very effective. Make sure to do a patch test first!",
                "You're welcome! Remember to stay hydrated and maintain a balanced diet. If symptoms worsen or you develop fever, please visit a clinic immediately. Take care! 🙏"
            ]
        ),
        Doctor(
            name: "Dr. Rajesh Gupta",
            specialty: "Ayurvedic Skin Expert",
            image: "person.circle.fill",
            isOnline: true,
            experience: "18 yrs exp",
            rating: 4.8,
            responses: [
                "Namaste! I specialize in Ayurvedic treatments for skin conditions. Tell me about your skin concern - when did it start and what symptoms are you experiencing?",
                "I see. In Ayurveda, we believe skin issues often reflect internal imbalances. Your symptoms suggest a Pitta dosha imbalance. Are you experiencing any digestive issues or stress lately?",
                "That makes sense. I recommend starting with a cooling diet - include more cucumber, coconut water, and avoid spicy foods. For topical application, try Chandan (sandalwood) paste with rose water.",
                "Excellent question! You can also try Kumkumadi oil at night - it's wonderful for skin healing. Triphala powder taken with warm water before bed will help detoxify from within.",
                "For faster results, make a paste of Multani Mitti with neem water and apply for 15 minutes daily. This will draw out impurities and cool the skin. How does your skin feel in the morning?",
                "Very good progress! Continue this routine for 2-3 weeks. Also practice Pranayama (breathing exercises) - it helps balance all doshas. Feel free to message me if you have more questions! 🙏"
            ]
        ),
        Doctor(
            name: "Dr. Anita Verma",
            specialty: "Cosmetic Dermatologist",
            image: "person.circle.fill",
            isOnline: false,
            experience: "15 yrs exp",
            rating: 4.7,
            responses: [
                "Hi there! Thank you for reaching out. I specialize in both medical and cosmetic dermatology. Please describe your skin concern in detail - photos would be helpful too!",
                "Thank you for the details. This appears to be a treatable condition. First, let's establish a basic skincare routine. Are you currently using sunscreen daily?",
                "Sunscreen is crucial! Use SPF 30+ every day, even indoors. For your specific concern, I'd recommend a gentle cleanser with salicylic acid. What's your skin type - oily, dry, or combination?",
                "Perfect. For combination skin, use a gel-based moisturizer. At night, you can introduce a retinol serum gradually - start with twice a week. Have you tried any chemical exfoliants before?",
                "Start slow with exfoliants. Try a 2% BHA (salicylic acid) once a week initially. Your skin barrier needs to stay healthy. Also, change your pillowcase twice a week - it makes a big difference!",
                "Great! Consistency is key in skincare. Results typically show in 4-6 weeks. Avoid touching your face and stay hydrated. Message me in 2 weeks with an update! Best wishes! ✨"
            ]
        ),
        Doctor(
            name: "Dr. Vikram Singh",
            specialty: "General Physician",
            image: "person.circle.fill",
            isOnline: true,
            experience: "20 yrs exp",
            rating: 4.6,
            responses: [
                "Hello! I'm Dr. Vikram. While I'm a general physician, I can help with common skin concerns. What symptoms are you experiencing?",
                "I understand your concern. These symptoms could have multiple causes. Have you recently changed any products, detergents, or been exposed to new environments?",
                "That's useful information. Sometimes skin issues are linked to allergies or immune responses. Are you taking any medications currently? Any known allergies?",
                "Okay, that helps narrow things down. For now, I'd suggest antihistamine tablets if there's itching, and calamine lotion for soothing. Keep the area clean and avoid scratching.",
                "If you notice spreading, increased redness, or any pus formation, please visit a dermatologist immediately. These could indicate infection requiring antibiotics.",
                "You're doing the right thing by seeking help early. Most skin conditions are manageable with proper care. Stay positive and follow the routine. Get well soon! 🏥"
            ]
        )
    ]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(doctors) { doctor in
                    NavigationLink(destination: ChatView(doctor: doctor)) {
                        DoctorRow(doctor: doctor)
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
            }
            .listStyle(.plain)
            .navigationTitle("Consult Doctors")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Doctor Row (WhatsApp Style)
struct DoctorRow: View {
    let doctor: Doctor
    
    var body: some View {
        HStack(spacing: 14) {
            // Profile Image with Online Indicator
            ZStack(alignment: .bottomTrailing) {
                Image(systemName: doctor.image)
                    .font(.system(size: 50))
                    .foregroundStyle(LinearGradient(colors: [.teal, .blue], startPoint: .top, endPoint: .bottom))
                
                // Online indicator
                Circle()
                    .fill(doctor.isOnline ? Color.green : Color.gray)
                    .frame(width: 14, height: 14)
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
            }
            
            // Doctor Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(doctor.name)
                        .font(.system(size: 16, weight: .semibold))
                    
                    Spacer()
                    
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", doctor.rating))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(doctor.specialty)
                    .font(.system(size: 14))
                    .foregroundColor(.teal)
                
                HStack {
                    Text(doctor.experience)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(doctor.isOnline ? "Online" : "Offline")
                        .font(.caption)
                        .foregroundColor(doctor.isOnline ? .green : .gray)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Chat View (WhatsApp Style)
struct ChatView: View {
    let doctor: Doctor
    
    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var responseIndex = 0
    @State private var isTyping = false
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Chat Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        // Welcome message
                        if messages.isEmpty {
                            welcomeCard
                        }
                        
                        ForEach(messages) { message in
                            MessageBubble(message: message, doctorName: doctor.name)
                                .id(message.id)
                        }
                        
                        // Typing indicator
                        if isTyping {
                            TypingIndicator(doctorName: doctor.name)
                                .id("typing")
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 16)
                }
                .onChange(of: messages.count) { _, _ in
                    withAnimation {
                        proxy.scrollTo(messages.last?.id, anchor: .bottom)
                    }
                }
                .onChange(of: isTyping) { _, typing in
                    if typing {
                        withAnimation {
                            proxy.scrollTo("typing", anchor: .bottom)
                        }
                    }
                }
            }
            
            // Input Bar
            inputBar
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(doctor.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text(doctor.name)
                        .font(.subheadline.bold())
                    Text(doctor.isOnline ? "Online" : "Offline")
                        .font(.caption2)
                        .foregroundColor(doctor.isOnline ? .green : .gray)
                }
            }
        }
    }
    
    // MARK: - Welcome Card
    private var welcomeCard: some View {
        VStack(spacing: 12) {
            Image(systemName: doctor.image)
                .font(.system(size: 60))
                .foregroundStyle(LinearGradient(colors: [.teal, .blue], startPoint: .top, endPoint: .bottom))
            
            Text(doctor.name)
                .font(.headline)
            
            Text(doctor.specialty)
                .font(.subheadline)
                .foregroundColor(.teal)
            
            Text("👋 Start a conversation by typing your skin concern below")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8)
        .padding(.top, 40)
    }
    
    // MARK: - Input Bar
    private var inputBar: some View {
        HStack(spacing: 12) {
            // Text Field
            HStack {
                TextField("Type your message...", text: $inputText, axis: .vertical)
                    .lineLimit(1...4)
                    .focused($isInputFocused)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
            }
            .background(Color(.systemBackground))
            .cornerRadius(24)
            .shadow(color: .black.opacity(0.05), radius: 4)
            
            // Send Button
            Button(action: sendMessage) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        LinearGradient(colors: inputText.isEmpty ? [.gray] : [.teal, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .cornerRadius(22)
            }
            .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Send Message
    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        
        // Add user message
        let userMessage = ChatMessage(text: text, isFromUser: true, timestamp: Date())
        messages.append(userMessage)
        inputText = ""
        isInputFocused = false
        
        // Show typing indicator
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isTyping = true
        }
        
        // Send doctor response after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 1.5...2.5)) {
            isTyping = false
            
            let response = doctor.responses[responseIndex % doctor.responses.count]
            let doctorMessage = ChatMessage(text: response, isFromUser: false, timestamp: Date())
            messages.append(doctorMessage)
            
            responseIndex += 1
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}

// MARK: - Message Bubble
struct MessageBubble: View {
    let message: ChatMessage
    let doctorName: String
    
    var body: some View {
        HStack {
            if message.isFromUser { Spacer(minLength: 60) }
            
            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .font(.system(size: 15))
                    .foregroundColor(message.isFromUser ? .white : .primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        message.isFromUser
                        ? LinearGradient(colors: [.teal, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(colors: [Color(.systemBackground), Color(.systemBackground)], startPoint: .top, endPoint: .bottom)
                    )
                    .cornerRadius(18)
                    .shadow(color: .black.opacity(0.05), radius: 4)
                
                Text(formatTime(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if !message.isFromUser { Spacer(minLength: 60) }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Typing Indicator
struct TypingIndicator: View {
    let doctorName: String
    @State private var animating = false
    
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 8, height: 8)
                        .scaleEffect(animating ? 1.0 : 0.5)
                        .animation(
                            .easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                            value: animating
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .cornerRadius(18)
            .shadow(color: .black.opacity(0.05), radius: 4)
            
            Spacer()
        }
        .onAppear { animating = true }
    }
}

// MARK: - Preview
#Preview {
    DoctorsListView()
}
