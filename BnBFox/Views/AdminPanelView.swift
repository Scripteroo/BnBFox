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
    @State private var airbnbURL: String
    @State private var vrboURL: String
    @State private var bookingURL: String
    @State private var showDeleteConfirmation = false
    
    init(property: PropertyConfig, onUpdate: @escaping (PropertyConfig) -> Void, onDelete: @escaping () -> Void, onToggleLock: @escaping () -> Void) {
        self.property = property
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        self.onToggleLock = onToggleLock
        _complexName = State(initialValue: property.complexName)
        _unitName = State(initialValue: property.unitName)
        _airbnbURL = State(initialValue: property.airbnbURL)
        _vrboURL = State(initialValue: property.vrboURL)
        _bookingURL = State(initialValue: property.bookingURL)
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
            
            // iCal URL fields - disabled when locked
            VStack(spacing: 8) {
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
        updated.airbnbURL = airbnbURL
        updated.vrboURL = vrboURL
        updated.bookingURL = bookingURL
        onUpdate(updated)
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
            PropertyConfig(
                id: property.id.uuidString,
                complexName: property.complexName,
                unitName: property.unitName,
                airbnbURL: property.sources.first(where: { $0.platform == .airbnb })?.url.absoluteString ?? "",
                vrboURL: property.sources.first(where: { $0.platform == .vrbo })?.url.absoluteString ?? "",
                bookingURL: property.sources.first(where: { $0.platform == .bookingCom })?.url.absoluteString ?? "",
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


