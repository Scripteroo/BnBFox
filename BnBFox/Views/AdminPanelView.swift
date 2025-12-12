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
                    Text("Kawama Maintenance\nAdministration Panel")
                        .font(.system(size: 20, weight: .bold))
                        .multilineTextAlignment(.center)
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
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        viewModel.saveChanges()
                        dismiss()
                    }
                }
            }
        }
    }
}

struct PropertyConfigCard: View {
    let property: PropertyConfig
    let onUpdate: (PropertyConfig) -> Void
    let onDelete: () -> Void
    
    @State private var airbnbURL: String
    @State private var vrboURL: String
    @State private var bookingURL: String
    
    init(property: PropertyConfig, onUpdate: @escaping (PropertyConfig) -> Void, onDelete: @escaping () -> Void) {
        self.property = property
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        _airbnbURL = State(initialValue: property.airbnbURL)
        _vrboURL = State(initialValue: property.vrboURL)
        _bookingURL = State(initialValue: property.bookingURL)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with property name and delete button
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(property.complexName)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    Text(property.displayName)
                        .font(.system(size: 20, weight: .bold))
                }
                
                Spacer()
                
                if !property.isDefault {
                    Button(action: onDelete) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.red)
                    }
                }
            }
            
            Divider()
                .padding(.vertical, 4)
            
            // iCal URL fields
            VStack(spacing: 8) {
                URLTextField(
                    placeholder: "AirBnB iCal",
                    text: $airbnbURL,
                    onChange: { updateProperty() }
                )
                
                URLTextField(
                    placeholder: "VRBO iCal",
                    text: $vrboURL,
                    onChange: { updateProperty() }
                )
                
                URLTextField(
                    placeholder: "Booking.com iCal",
                    text: $bookingURL,
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
    }
    
    private func updateProperty() {
        var updated = property
        updated.airbnbURL = airbnbURL
        updated.vrboURL = vrboURL
        updated.bookingURL = bookingURL
        onUpdate(updated)
    }
}

struct URLTextField: View {
    let placeholder: String
    @Binding var text: String
    let onChange: () -> Void
    
    var body: some View {
        TextField(placeholder, text: $text)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .autocapitalization(.none)
            .disableAutocorrection(true)
            .onChange(of: text) { _ in
                onChange()
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
                complexName: "Kawama",
                displayName: property.displayName,
                airbnbURL: property.sources.first(where: { $0.platform == .airbnb })?.url.absoluteString ?? "",
                vrboURL: property.sources.first(where: { $0.platform == .vrbo })?.url.absoluteString ?? "",
                bookingURL: property.sources.first(where: { $0.platform == .bookingCom })?.url.absoluteString ?? "",
                isDefault: true,
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
            displayName: "Unit#\(nextUnit)",
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
        properties.removeAll { $0.id == property.id }
    }
    
    func saveChanges() {
        // Convert PropertyConfig back to Property model and save
        PropertyService.shared.updateProperties(properties)
    }
    
    private func getNextUnitNumber() -> Int {
        let existingNumbers = properties.compactMap { config -> Int? in
            let name = config.displayName
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
