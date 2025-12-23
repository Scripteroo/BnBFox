//
//  AdminPanelView.swift
//  BnBShift
//
//  Created on 12/12/2025.
//

import SwiftUI

struct AdminPanelView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = AdminPanelViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Header with logo and title
                    HStack(spacing: 12) {
                        Image("bnbshift-logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Property Administration")
                                .font(.system(size: 22, weight: .bold))
                            
                            Text("Connect your AirBnB, VRBO and Booking.com Calendars")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
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
                        if viewModel.properties.count < 6 {
                            Button(action: {
                                viewModel.addNewProperty()
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.blue)
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
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
    @State private var streetAddress: String
    @State private var unit: String
    @State private var city: String
    @State private var state: String
    @State private var zipCode: String
    @State private var iCalFeeds: [ICalFeed]
    @State private var showDeleteConfirmation = false
    
    init(property: PropertyConfig, onUpdate: @escaping (PropertyConfig) -> Void, onDelete: @escaping () -> Void, onToggleLock: @escaping () -> Void) {
        self.property = property
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        self.onToggleLock = onToggleLock
        _complexName = State(initialValue: property.complexName)
        _unitName = State(initialValue: property.unitName)
        _streetAddress = State(initialValue: property.streetAddress)
        _unit = State(initialValue: property.unit)
        _city = State(initialValue: property.city)
        _state = State(initialValue: property.state)
        _zipCode = State(initialValue: property.zipCode)
        _iCalFeeds = State(initialValue: property.iCalFeeds)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with property name and buttons
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    // Complex name - editable when unlocked
                    if property.isLocked {
                        Text(complexName.isEmpty ? "Complex" : complexName)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    } else {
                        TextField("", text: $complexName, prompt: Text("Complex").foregroundColor(.gray.opacity(0.5)))
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
            
            // Address fields - disabled when locked
            if !property.isLocked {
                VStack(spacing: 6) {
                    TextField("Street Address", text: $streetAddress)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.caption)
                        .onChange(of: streetAddress) { _ in updateProperty() }
                    
                    TextField("Unit", text: $unit)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.caption)
                        .onChange(of: unit) { _ in updateProperty() }
                    
                    HStack(spacing: 6) {
                        TextField("City", text: $city)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.caption)
                            .onChange(of: city) { _ in updateProperty() }
                        
                        TextField("State", text: $state)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.caption)
                            .frame(width: 60)
                            .onChange(of: state) { _ in updateProperty() }
                        
                        TextField("ZIP", text: $zipCode)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.caption)
                            .frame(width: 80)
                            .onChange(of: zipCode) { _ in updateProperty() }
                    }
                }
                .padding(.bottom, 8)
            }
            
            // Instructional text with hyperlink
            HStack(spacing: 4) {
                Text("Enter iCal information below.")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Button(action: {
                    // TODO: Link to instruction page
                    print("Open iCal instructions")
                }) {
                    Text("Where to find iCal information...")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .underline()
                }
            }
            .padding(.bottom, 4)
            
            // Dynamic iCal URL fields
            VStack(spacing: 8) {
                ForEach($iCalFeeds) { $feed in
                    HStack(spacing: 8) {
                        DynamicURLTextField(
                            feed: $feed,
                            isDisabled: property.isLocked,
                            onChange: { updateProperty() }
                        )
                        
                        // Delete button for custom feeds (not default ones)
                        if !property.isLocked && !feed.isDefault {
                            Button(action: {
                                deleteFeed(feed)
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
                
                // Add button for new custom feeds
                if !property.isLocked {
                    Button(action: {
                        addCustomFeed()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.blue)
                            Text("Add Custom iCal Feed")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.top, 4)
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
        updated.streetAddress = streetAddress
        updated.unit = unit
        updated.city = city
        updated.state = state
        updated.zipCode = zipCode
        updated.iCalFeeds = iCalFeeds
        onUpdate(updated)
    }
    
    private func addCustomFeed() {
        let newFeed = ICalFeed(platformName: "Custom", url: "", isDefault: false)
        iCalFeeds.append(newFeed)
        updateProperty()
    }
    
    private func deleteFeed(_ feed: ICalFeed) {
        iCalFeeds.removeAll { $0.id == feed.id }
        updateProperty()
    }
}

struct DynamicURLTextField: View {
    @Binding var feed: ICalFeed
    let isDisabled: Bool
    let onChange: () -> Void
    
    var body: some View {
        VStack(spacing: 4) {
            if isDisabled {
                // Show as read-only text when locked
                VStack(alignment: .leading, spacing: 2) {
                    Text(feed.platformName)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.gray)
                    
                    Text(feed.url.isEmpty ? "No URL" : feed.url)
                        .font(.system(size: 14))
                        .foregroundColor(feed.url.isEmpty ? .gray.opacity(0.5) : .primary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(5)
            } else {
                // Editable when unlocked
                VStack(spacing: 4) {
                    // Platform name field (editable for custom feeds)
                    if feed.isDefault {
                        Text(feed.platformName)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        TextField("Platform Name", text: $feed.platformName)
                            .font(.system(size: 11, weight: .medium))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: feed.platformName) { _ in
                                onChange()
                            }
                    }
                    
                    // URL field
                    TextField(feed.isDefault ? "\(feed.platformName) iCal URL" : "Custom iCal URL", text: $feed.url)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .font(.system(size: 14))
                        .onChange(of: feed.url) { _ in
                            onChange()
                        }
                }
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
            // Convert CalendarSource array to ICalFeed array
            var feeds: [ICalFeed] = []
            
            // Add default feeds with URLs if they exist
            let airbnbSource = property.sources.first(where: { $0.platform == .airbnb })
            feeds.append(ICalFeed(
                platformName: "AirBnB",
                url: airbnbSource?.url.absoluteString ?? "",
                isDefault: true
            ))
            
            let vrboSource = property.sources.first(where: { $0.platform == .vrbo })
            feeds.append(ICalFeed(
                platformName: "VRBO",
                url: vrboSource?.url.absoluteString ?? "",
                isDefault: true
            ))
            
            let bookingSource = property.sources.first(where: { $0.platform == .bookingCom })
            feeds.append(ICalFeed(
                platformName: "Booking.com",
                url: bookingSource?.url.absoluteString ?? "",
                isDefault: true
            ))
            
            // Add any additional custom sources
            let customSources = property.sources.filter { source in
                // Count how many times this source appears in default feeds
                let isAirbnb = source.platform == .airbnb && airbnbSource != nil
                let isVrbo = source.platform == .vrbo && vrboSource != nil
                let isBooking = source.platform == .bookingCom && bookingSource != nil
                return !isAirbnb && !isVrbo && !isBooking
            }
            
            for customSource in customSources {
                feeds.append(ICalFeed(
                    platformName: "Custom",
                    url: customSource.url.absoluteString,
                    isDefault: false
                ))
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
        guard properties.count < 6 else { return }
        
        let nextUnit = getNextUnitNumber()
        let color = availableColors[properties.count % availableColors.count]
        
        let newProperty = PropertyConfig(
            id: UUID().uuidString,
            complexName: "Complex",
            unitName: "Unit#\(nextUnit)",
            isLocked: false, // New properties start unlocked for editing
            color: color
        )
        
        properties.append(newProperty)
    }
    
    func updateProperty(_ updated: PropertyConfig) {
        if let index = properties.firstIndex(where: { $0.id == updated.id }) {
            properties[index] = updated
            
            // Sync to PropertyService for bidirectional updates
            PropertyService.shared.updatePropertyFromConfig(updated)
        }
    }
    
    func deleteProperty(_ property: PropertyConfig) {
        // Only allow deletion if unlocked
        guard !property.isLocked else { return }
        properties.removeAll { $0.id == property.id }
    }
    
    func toggleLock(_ property: PropertyConfig) {
        if let index = properties.firstIndex(where: { $0.id == property.id }) {
            properties[index].isLocked.toggle()
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


