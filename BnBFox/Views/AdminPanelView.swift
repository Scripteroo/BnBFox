//
//  AdminPanelView.swift
//  BnBFox
//
//  Created on 12/12/2025.
//

import SwiftUI

struct AdminPanelView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = AdminPanelViewModel()
    @State private var showOnboardingSheet = false
    @State private var showInstructionsModal = false
    @State private var instructionsScrollTarget: String? = nil
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 8) {
                        Text("iCal Connect")
                            .font(.system(size: 24, weight: .bold))
                            .multilineTextAlignment(.center)
                        
                        Text("Connect your AirBnB, VRBO and Booking.com Calendars")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 24)
                    
                    // Property list
                    VStack(spacing: 16) {
                        ForEach(viewModel.properties) { property in
                            PropertyConfigCard(
                                property: property,
                                onUpdate: { updated in
                                    viewModel.updateProperty(updated)
                                },
                                onDelete: {
                                    viewModel.deleteProperty(property)
                                },
                                onToggleLock: {
                                    viewModel.toggleLock(property)
                                }
                            )
                        }
                        
                        // Add button
                        Button(action: {
                            viewModel.addNewProperty()
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.blue)
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        instructionsScrollTarget = nil
                        showInstructionsModal = true
                    }) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                    }
                }
            }
            .onAppear {
                // Show onboarding sheet if properties list is empty
                if viewModel.properties.isEmpty {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showOnboardingSheet = true
                    }
                }
            }
            .sheet(isPresented: $showOnboardingSheet) {
                OnboardingSheet(
                    onPlatformSelected: { platform in
                        showOnboardingSheet = false
                        instructionsScrollTarget = platform
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showInstructionsModal = true
                        }
                    },
                    onDismiss: {
                        showOnboardingSheet = false
                    }
                )
            }
            .sheet(isPresented: $showInstructionsModal) {
                InfoView(scrollTarget: instructionsScrollTarget)
            }
        }
    }
}

struct PropertyConfigCard: View {
    let property: PropertyConfig
    let onUpdate: (PropertyConfig) -> Void
    let onDelete: () -> Void
    let onToggleLock: () -> Void
    
    @State private var complexName: String
    @State private var unitName: String
    @State private var airbnbURL: String
    @State private var vrboURL: String
    @State private var bookingURL: String
    @State private var additionalFeeds: [ICalFeed] = []
    @State private var streetAddress: String
    @State private var unit: String
    @State private var city: String
    @State private var state: String
    @State private var zipCode: String
    @State private var country: String
    @State private var showDeleteConfirmation = false
    
    init(property: PropertyConfig, onUpdate: @escaping (PropertyConfig) -> Void, onDelete: @escaping () -> Void, onToggleLock: @escaping () -> Void) {
        self.property = property
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        self.onToggleLock = onToggleLock
        _complexName = State(initialValue: property.complexName)
        _unitName = State(initialValue: property.unitName)
        _airbnbURL = State(initialValue: property.getFeedURL(for: "AirBnB"))
        _vrboURL = State(initialValue: property.getFeedURL(for: "VRBO"))
        _bookingURL = State(initialValue: property.getFeedURL(for: "Booking.com"))
        
        // Load additional feeds (non-default platforms)
        let additionalFeeds = property.iCalFeeds.filter { !$0.isDefault }
        _additionalFeeds = State(initialValue: additionalFeeds)
        
        // Initialize address fields
        _streetAddress = State(initialValue: property.streetAddress)
        _unit = State(initialValue: property.unit)
        _city = State(initialValue: property.city)
        _state = State(initialValue: property.state)
        _zipCode = State(initialValue: property.zipCode)
        _country = State(initialValue: property.country)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with property name and buttons
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    // Complex name - editable when unlocked
                    if property.isLocked {
                        Text(complexName.isEmpty ? "Property Name" : complexName)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    } else {
                        TextField("", text: $complexName, prompt: Text("Property Name").foregroundColor(.gray.opacity(0.5)))
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: complexName) { _ in
                                updateProperty()
                            }
                    }
                    
                    // Unit name - editable when unlocked
                    if property.isLocked {
                        Text(unitName)
                            .font(.system(size: 20, weight: .bold))
                    } else {
                        TextField("Unit Name", text: $unitName)
                            .font(.system(size: 20, weight: .bold))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: unitName) { _ in
                                updateProperty()
                            }
                    }
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    // Lock/Unlock button
                    Button(action: onToggleLock) {
                        Image(systemName: property.isLocked ? "lock.fill" : "lock.open.fill")
                            .font(.system(size: 24))
                            .foregroundColor(property.isLocked ? .green : .gray)
                    }
                    
                    // Delete button - only visible when unlocked
                    if !property.isLocked {
                        Button(action: {
                            showDeleteConfirmation = true
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            
            Divider()
                .padding(.vertical, 4)
            
            // iCal URL fields - disabled when locked
            VStack(spacing: 8) {
                // Default feeds (Airbnb, VRBO, Booking.com)
                URLTextField(
                    placeholder: property.isLocked ? airbnbURL : "AirBnB iCal",
                    text: $airbnbURL,
                    isDisabled: property.isLocked,
                    onChange: { updateProperty() }
                )
                
                URLTextField(
                    placeholder: property.isLocked ? vrboURL : "VRBO iCal",
                    text: $vrboURL,
                    isDisabled: property.isLocked,
                    onChange: { updateProperty() }
                )
                
                URLTextField(
                    placeholder: property.isLocked ? bookingURL : "Booking.com iCal",
                    text: $bookingURL,
                    isDisabled: property.isLocked,
                    onChange: { updateProperty() }
                )
                
                // Additional feeds (custom platforms)
                ForEach(additionalFeeds.indices, id: \.self) { index in
                    HStack(spacing: 8) {
                        VStack(spacing: 4) {
                            // Platform name field
                            TextField("Platform Name", text: Binding(
                                get: { additionalFeeds[index].platformName },
                                set: { newValue in
                                    additionalFeeds[index].platformName = newValue
                                    updateProperty()
                                }
                            ))
                            .font(.system(size: 12))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .disabled(property.isLocked)
                            
                            // URL field
                            URLTextField(
                                placeholder: property.isLocked ? additionalFeeds[index].url : "iCal URL",
                                text: Binding(
                                    get: { additionalFeeds[index].url },
                                    set: { newValue in
                                        additionalFeeds[index].url = newValue
                                        updateProperty()
                                    }
                                ),
                                isDisabled: property.isLocked,
                                onChange: { updateProperty() }
                            )
                        }
                        
                        // Delete button for additional feeds (only when unlocked)
                        if !property.isLocked {
                            Button(action: {
                                deleteAdditionalFeed(at: index)
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
                
                // + button to add more feeds (only when unlocked)
                if !property.isLocked {
                    Button(action: addAdditionalFeed) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20))
                            Text("Add iCal Feed")
                                .font(.system(size: 14))
                        }
                        .foregroundColor(.blue)
                    }
                    .padding(.top, 4)
                }
            }
            
            // Address fields section
            Divider()
                .padding(.vertical, 8)
            
            VStack(spacing: 8) {
                // Street Address
                TextField("Street Address", text: $streetAddress)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(property.isLocked)
                    .onChange(of: streetAddress) { _ in
                        updateProperty()
                    }
                
                // City, State, ZIP in a row
                HStack(spacing: 8) {
                    TextField("City", text: $city)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(property.isLocked)
                        .onChange(of: city) { _ in
                            updateProperty()
                        }
                    
                    TextField("State", text: $state)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(property.isLocked)
                        .frame(width: 80)
                        .onChange(of: state) { _ in
                            updateProperty()
                        }
                    
                    TextField("ZIP", text: $zipCode)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(property.isLocked)
                        .frame(width: 80)
                        .onChange(of: zipCode) { _ in
                            updateProperty()
                        }
                }
                
                // Country picker
                HStack {
                    Text("Country:")
                        .foregroundColor(.gray)
                        .frame(width: 70, alignment: .leading)
                    
                    Picker("", selection: $country) {
                        Text("USA").tag("USA")
                        Text("Canada").tag("Canada")
                        Text("Mexico").tag("Mexico")
                        Text("Costa Rica").tag("Costa Rica")
                        Text("Panama").tag("Panama")
                        Text("United Kingdom").tag("United Kingdom")
                        Text("France").tag("France")
                        Text("Germany").tag("Germany")
                        Text("Spain").tag("Spain")
                        Text("Italy").tag("Italy")
                        Text("Other").tag("Other")
                    }
                    .pickerStyle(MenuPickerStyle())
                    .disabled(property.isLocked)
                    .onChange(of: country) { _ in
                        updateProperty()
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
        .alert("Are you sure you want to delete this unit?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        }
    }
    
    private func updateProperty() {
        var updated = property
        updated.complexName = complexName
        updated.unitName = unitName
        updated.updateFeedURL(airbnbURL, for: "AirBnB")
        updated.updateFeedURL(vrboURL, for: "VRBO")
        updated.updateFeedURL(bookingURL, for: "Booking.com")
        
        // Update additional feeds
        // Remove old non-default feeds and add current ones
        updated.iCalFeeds = updated.iCalFeeds.filter { $0.isDefault } + additionalFeeds
        
        // Update address fields
        updated.streetAddress = streetAddress
        updated.unit = unit
        updated.city = city
        updated.state = state
        updated.zipCode = zipCode
        updated.country = country
        
        onUpdate(updated)
    }
    
    private func addAdditionalFeed() {
        let newFeed = ICalFeed(
            platformName: "Other",
            url: "",
            isDefault: false
        )
        additionalFeeds.append(newFeed)
        updateProperty()
        print("➕ Added new iCal feed slot")
    }
    
    private func deleteAdditionalFeed(at index: Int) {
        guard index < additionalFeeds.count else { return }
        let feedName = additionalFeeds[index].platformName
        additionalFeeds.remove(at: index)
        updateProperty()
        print("🗑️ Deleted iCal feed: \(feedName)")
    }
}

struct URLTextField: View {
    let placeholder: String
    @Binding var text: String
    let isDisabled: Bool
    let onChange: () -> Void
    
    var body: some View {
        if isDisabled {
            // Show as read-only text when locked
            Text(text.isEmpty ? placeholder : text)
                .font(.system(size: 14))
                .foregroundColor(text.isEmpty ? .gray.opacity(0.5) : .primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(5)
        } else {
            // Editable when unlocked
            TextField(placeholder, text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .onChange(of: text) { _ in
                    onChange()
                }
        }
    }
}

// PropertyConfig is now defined in PropertyService.swift

@MainActor
class AdminPanelViewModel: ObservableObject {
    @Published var properties: [PropertyConfig] = []
    
    private let availableColors: [Color] = [
        Color.orange,
        Color.yellow,
        Color.green,
        Color.blue,
        Color.purple,
        Color.pink
    ]
    
    init() {
        loadProperties()
    }
    
    func loadProperties() {
        // Load from PropertyService
        let existingProperties = PropertyService.shared.getAllProperties()
        
        properties = existingProperties.map { property in
            // Convert Property sources to ICalFeeds
            var feeds: [ICalFeed] = []
            
            // Add AirBnB feed
            if let airbnbSource = property.sources.first(where: { $0.platform == .airbnb }) {
                feeds.append(ICalFeed(platformName: "AirBnB", url: airbnbSource.url.absoluteString, isDefault: true))
            } else {
                feeds.append(ICalFeed(platformName: "AirBnB", isDefault: true))
            }
            
            // Add VRBO feed
            if let vrboSource = property.sources.first(where: { $0.platform == .vrbo }) {
                feeds.append(ICalFeed(platformName: "VRBO", url: vrboSource.url.absoluteString, isDefault: true))
            } else {
                feeds.append(ICalFeed(platformName: "VRBO", isDefault: true))
            }
            
            // Add Booking.com feed
            if let bookingSource = property.sources.first(where: { $0.platform == .bookingCom }) {
                feeds.append(ICalFeed(platformName: "Booking.com", url: bookingSource.url.absoluteString, isDefault: true))
            } else {
                feeds.append(ICalFeed(platformName: "Booking.com", isDefault: true))
            }
            
            return PropertyConfig(
                id: property.id.uuidString,
                complexName: property.complexName,
                unitName: property.unitName,
                streetAddress: property.streetAddress,
                unit: property.unit,
                city: property.city,
                state: property.state,
                zipCode: property.zipCode,
                iCalFeeds: feeds,
                isLocked: true, // All properties locked by default
                color: property.color
            )
        }
    }
    
    func addNewProperty() {
        // Auto-lock all currently unlocked properties before adding new one
        for index in properties.indices {
            if !properties[index].isLocked {
                properties[index].isLocked = true
                print("🔒 Auto-locked property: \(properties[index].displayName)")
            }
        }
        
        // Save changes before adding new property
        saveChanges()
        
        let nextUnit = getNextUnitNumber()
        let color = availableColors[properties.count % availableColors.count]
        
        let newProperty = PropertyConfig(
            id: UUID().uuidString,
            complexName: "",
            unitName: "Unit#\(nextUnit)",
            isLocked: false, // New properties start unlocked for editing
            color: color
        )
        
        properties.append(newProperty)
        print("➕ Added new property: \(newProperty.displayName) (unlocked for editing)")
    }
    
    func updateProperty(_ updated: PropertyConfig) {
        if let index = properties.firstIndex(where: { $0.id == updated.id }) {
            properties[index] = updated
        }
    }
    
    func deleteProperty(_ property: PropertyConfig) {
        // Only allow deletion if unlocked
        guard !property.isLocked else { return }
        properties.removeAll { $0.id == property.id }
        saveChanges()  // Save to PropertyService and trigger notification
    }
    
    func toggleLock(_ property: PropertyConfig) {
        if let index = properties.firstIndex(where: { $0.id == property.id }) {
            properties[index].isLocked.toggle()
            
            // If locking the property, save to PropertyService
            if properties[index].isLocked {
                print("🔒 Locking property and saving to PropertyService: \(properties[index].displayName)")
                saveChanges()
            }
        }
    }
    
    func saveChanges() {
        // Convert PropertyConfig back to Property model and save
        PropertyService.shared.updateProperties(properties)
    }
    
    private func getNextUnitNumber() -> Int {
        let existingNumbers = properties.compactMap { config -> Int? in
            let name = config.unitName
            if name.hasPrefix("Unit#") {
                return Int(name.replacingOccurrences(of: "Unit#", with: ""))
            }
            return nil
        }
        
        if let max = existingNumbers.max() {
            return max + 1
        }
        return 1
    }
}




// MARK: - Onboarding Sheet

struct OnboardingSheet: View {
    let onPlatformSelected: (String) -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Handle bar
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 12)
            
            // Welcome content
            VStack(spacing: 16) {
                // Logo
                Image("bnbshift-logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                
                // Title
                Text("Welcome to BnBShift!")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Description
                Text("Get started by adding your first property with iCal URLs from your booking platforms.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                // Platform links
                VStack(spacing: 12) {
                    Text("Tap to view instructions:")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    PlatformLinkButton(
                        icon: "house.fill",
                        title: "Airbnb Instructions",
                        color: .red
                    ) {
                        onPlatformSelected("airbnb")
                    }
                    
                    PlatformLinkButton(
                        icon: "building.2.fill",
                        title: "VRBO Instructions",
                        color: .blue
                    ) {
                        onPlatformSelected("vrbo")
                    }
                    
                    PlatformLinkButton(
                        icon: "bed.double.fill",
                        title: "Booking.com Instructions",
                        color: .orange
                    ) {
                        onPlatformSelected("booking")
                    }
                }
                .padding(.horizontal, 24)
            }
            
            Spacer()
            
            // Got it button
            Button(action: onDismiss) {
                Text("Got it")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
    }
}

struct PlatformLinkButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                    .frame(width: 30)
                
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
        }
    }
}

