//
//  PropertyService.swift
//  BnBFox
//
//  Updated: Removed hardcoded Kawama properties for v1.0.4
//

import Foundation
import SwiftUI

class PropertyService: ObservableObject {
    static let shared = PropertyService()
    
    private let userDefaults = UserDefaults.standard
    private let propertiesKey = "saved_properties"
    
    @Published private var properties: [Property] = []
    
    private init() {
        loadProperties()
    }
    
    // Default properties for initial setup - EMPTY for new users
    private func getDefaultProperties() -> [Property] {
        // Return empty array - users will add their own properties via Admin Panel
        return []
    }
    
    private func loadProperties() {
        if let data = userDefaults.data(forKey: propertiesKey),
           let decoded = try? JSONDecoder().decode([PropertyData].self, from: data) {
            properties = decoded.map { $0.toProperty() }
        } else {
            // First launch - start with empty properties
            properties = getDefaultProperties()
            saveProperties()
        }
    }
    
    private func saveProperties() {
        let propertyData = properties.map { PropertyData(from: $0) }
        if let encoded = try? JSONEncoder().encode(propertyData) {
            userDefaults.set(encoded, forKey: propertiesKey)
        }
    }
    
    func getAllProperties() -> [Property] {
        return properties
    }
    
    func getProperty(by id: UUID) -> Property? {
        return properties.first { $0.id == id }
    }
    
    func addProperty(_ property: Property) {
        properties.append(property)
        saveProperties()
    }
    
    func updateProperty(_ property: Property) {
        if let index = properties.firstIndex(where: { $0.id == property.id }) {
            properties[index] = property
            saveProperties()
        }
    }
    
    func deleteProperty(_ property: Property) {
        properties.removeAll { $0.id == property.id }
        saveProperties()
    }
    
    func updateProperties(_ newProperties: [Property]) {
        properties = newProperties
        saveProperties()
    }
}

// MARK: - PropertyData for Codable persistence
struct PropertyData: Codable {
    let id: UUID
    let complexName: String
    let unitName: String
    let streetAddress: String
    let unit: String
    let city: String
    let state: String
    let zipCode: String
    let sources: [CalendarSourceData]
    let isLocked: Bool
    let colorHex: String
    let photoData: Data?
    
    init(from property: Property) {
        self.id = property.id
        self.complexName = property.complexName
        self.unitName = property.unitName
        self.streetAddress = property.streetAddress
        self.unit = property.unit
        self.city = property.city
        self.state = property.state
        self.zipCode = property.zipCode
        self.sources = property.sources.map { CalendarSourceData(from: $0) }
        self.isLocked = property.isLocked
        self.colorHex = property.color.toHex()
        self.photoData = property.photoData
    }
    
    func toProperty() -> Property {
        return Property(
            id: id,
            complexName: complexName,
            unitName: unitName,
            streetAddress: streetAddress,
            unit: unit,
            city: city,
            state: state,
            zipCode: zipCode,
            sources: sources.map { $0.toCalendarSource() },
            isLocked: isLocked,
            color: Color(hex: colorHex) ?? .blue,
            photoData: photoData
        )
    }
}

struct CalendarSourceData: Codable {
    let platform: Platform
    let urlString: String
    
    init(from source: CalendarSource) {
        self.platform = source.platform
        self.urlString = source.url.absoluteString
    }
    
    func toCalendarSource() -> CalendarSource {
        return CalendarSource(
            platform: platform,
            url: URL(string: urlString) ?? URL(string: "https://example.com")!
        )
    }
}

// MARK: - Color Hex Extension
extension Color {
    func toHex() -> String {
        guard let components = UIColor(self).cgColor.components else { return "#000000" }
        
        let r = Int(components[0] * 255.0)
        let g = Int(components[1] * 255.0)
        let b = Int(components[2] * 255.0)
        
        return String(format: "#%02X%02X%02X", r, g, b)
    }
    
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
}

