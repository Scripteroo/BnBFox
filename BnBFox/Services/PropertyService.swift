//
//  PropertyService.swift
//  BnBFox
//
//  Created on 12/11/2025.
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
    
    // Default properties for initial setup
    private func getDefaultProperties() -> [Property] {
        return [
            Property(
                name: "kawama-c2",
                displayName: "Kawama C-2",
                shortName: "C-2",
                colorHex: "FF8C00", // Orange
                sources: [
                    CalendarSource(
                        platform: .vrbo,
                        url: URL(string: "https://www.vrbo.com/icalendar/94283b4ad57643e0a348d8e8da0ef091.ics?nonTentative")!
                    ),
                    CalendarSource(
                        platform: .airbnb,
                        url: URL(string: "https://www.airbnb.com/calendar/ical/778254930255723354.ics?s=c0d103adb18b28b018a6c6484a5f04ee")!
                    )
                ]
            ),
            Property(
                name: "kawama-e5",
                displayName: "Kawama E-5",
                shortName: "E-5",
                colorHex: "FFD700", // Gold/Yellow
                sources: [
                    CalendarSource(
                        platform: .vrbo,
                        url: URL(string: "https://www.vrbo.com/icalendar/66d4d3b376f4426083c6971263059c26.ics?nonTentative")!
                    ),
                    CalendarSource(
                        platform: .airbnb,
                        url: URL(string: "https://www.airbnb.com/calendar/ical/634088790463336883.ics?s=aa7722940a08ab86e82b802120481e3d")!
                    )
                ]
            ),
            Property(
                name: "kawama-c5",
                displayName: "Kawama C-5",
                shortName: "C-5",
                colorHex: "007AFF", // Blue
                sources: [
                    CalendarSource(
                        platform: .vrbo,
                        url: URL(string: "https://www.vrbo.com/icalendar/42211aa1409741bd9ad359d1ccd9f522.ics")!
                    ),
                    CalendarSource(
                        platform: .airbnb,
                        url: URL(string: "https://www.airbnb.com/calendar/ical/1329041307852345218.ics?s=380d406f0019dfb3fe07b61f94f8f0fa&locale=en")!
                    )
                ]
            )
        ]
    }
    
    private func loadProperties() {
        if let data = userDefaults.data(forKey: propertiesKey),
           let decoded = try? JSONDecoder().decode([PropertyData].self, from: data) {
            properties = decoded.map { $0.toProperty() }
        } else {
            // First launch - use default properties
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
    
    func updateProperty(_ updatedProperty: Property) {
        if let index = properties.firstIndex(where: { $0.id == updatedProperty.id }) {
            properties[index] = updatedProperty
            saveProperties()
            NotificationCenter.default.post(name: .propertiesDidChange, object: nil)
        }
    }
    
    func getProperty(by id: UUID) -> Property? {
        return properties.first { $0.id == id }
    }
    
    func getProperty(by name: String) -> Property? {
        return properties.first { $0.name == name }
    }
    
    // Update properties from admin panel
    func updateProperties(_ configs: [PropertyConfig]) {
        properties = configs.map { config in
            var sources: [CalendarSource] = []
            
            if !config.airbnbURL.isEmpty, let url = URL(string: config.airbnbURL) {
                sources.append(CalendarSource(platform: .airbnb, url: url))
            }
            
            if !config.vrboURL.isEmpty, let url = URL(string: config.vrboURL) {
                sources.append(CalendarSource(platform: .vrbo, url: url))
            }
            
            if !config.bookingURL.isEmpty, let url = URL(string: config.bookingURL) {
                sources.append(CalendarSource(platform: .bookingCom, url: url))
            }
            
            let shortName = config.unitName
            let name = config.displayName.lowercased().replacingOccurrences(of: " ", with: "-")
            
            return Property(
                name: name,
                displayName: config.displayName,
                shortName: shortName,
                colorHex: config.color.toHex(),
                sources: sources
            )
        }
        
        saveProperties()
        
        // Post notification to refresh calendar
        NotificationCenter.default.post(name: .propertiesDidChange, object: nil)
    }
}

// Codable wrapper for Property
struct PropertyData: Codable {
    let id: String
    let name: String
    let displayName: String
    let shortName: String
    let colorHex: String
    let sources: [CalendarSourceData]
    let ownerName: String
    let ownerPhone: String
    let ownerEmail: String
    let doorCode: String
    let bikeLocks: String
    let notes: String
    
    init(from property: Property) {
        self.id = property.id.uuidString
        self.name = property.name
        self.displayName = property.displayName
        self.shortName = property.shortName
        self.colorHex = property.colorHex
        self.sources = property.sources.map { CalendarSourceData(from: $0) }
        self.ownerName = property.ownerName
        self.ownerPhone = property.ownerPhone
        self.ownerEmail = property.ownerEmail
        self.doorCode = property.doorCode
        self.bikeLocks = property.bikeLocks
        self.notes = property.notes
    }
    
    func toProperty() -> Property {
        return Property(
            id: UUID(uuidString: id) ?? UUID(),
            name: name,
            displayName: displayName,
            shortName: shortName,
            colorHex: colorHex,
            sources: sources.map { $0.toCalendarSource() },
            ownerName: ownerName,
            ownerPhone: ownerPhone,
            ownerEmail: ownerEmail,
            doorCode: doorCode,
            bikeLocks: bikeLocks,
            notes: notes
        )
    }
}

struct CalendarSourceData: Codable {
    let platform: String
    let urlString: String
    
    init(from source: CalendarSource) {
        self.platform = source.platform.rawValue
        self.urlString = source.url.absoluteString
    }
    
    func toCalendarSource() -> CalendarSource {
        let platform = Platform(rawValue: platform) ?? .airbnb
        let url = URL(string: urlString) ?? URL(string: "https://example.com")!
        return CalendarSource(platform: platform, url: url)
    }
}

// Extension to convert Color to hex
extension Color {
    func toHex() -> String {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let rgb = Int(red * 255) << 16 | Int(green * 255) << 8 | Int(blue * 255)
        return String(format: "%06X", rgb)
    }
}

// Notification for property changes
extension Notification.Name {
    static let propertiesDidChange = Notification.Name("propertiesDidChange")
}

// Import PropertyConfig from AdminPanelView
struct PropertyConfig: Identifiable, Codable {
    let id: String
    var complexName: String
    var unitName: String
    var airbnbURL: String
    var vrboURL: String
    var bookingURL: String
    var isLocked: Bool
    let colorHex: String
    
    var color: Color {
        Color(hex: colorHex) ?? .blue
    }
    
    var displayName: String {
        "\(complexName) \(unitName)"
    }
    
    init(id: String, complexName: String, unitName: String, airbnbURL: String = "", vrboURL: String = "", bookingURL: String = "", isLocked: Bool = true, color: Color) {
        self.id = id
        self.complexName = complexName
        self.unitName = unitName
        self.airbnbURL = airbnbURL
        self.vrboURL = vrboURL
        self.bookingURL = bookingURL
        self.isLocked = isLocked
        self.colorHex = color.toHex()
    }
}

// Color init(hex:) extension is defined in DateExtensions.swift
