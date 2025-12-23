//
//  PropertyService.swift
//  BnBShift
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
                ],
                ownerName: "Daniel DelPercio",
                ownerPhone: "+19144860800",
                ownerEmail: "ddelpercio@gmail.com",
                streetAddress: "123 Kawama Lane",
                unit: "C-2",
                city: "Key West",
                state: "FL",
                zipCode: "33040",
                doorCode: "1157",
                bikeLocks: "1157",
                camera: "",
                thermostat: "",
                other: "",
                airbnbListingURL: "https://airbnb.com/h/kawama-c2",
                vrboListingURL: "https://vrbo.com/3058755",
                bookingComListingURL: "",
                notes: ""
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
                ],
                ownerName: "Daniel DelPercio",
                ownerPhone: "+19144860800",
                ownerEmail: "ddelpercio@gmail.com",
                streetAddress: "",
                unit: "",
                city: "",
                state: "",
                zipCode: "",
                doorCode: "8578",
                bikeLocks: "8578",
                camera: "",
                thermostat: "",
                other: "",
                airbnbListingURL: "https://airbnb.com/h/kawama-e5",
                vrboListingURL: "https://vrbo.com/2659755",
                bookingComListingURL: "",
                notes: ""
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
                ],
                ownerName: "",
                ownerPhone: "",
                ownerEmail: "",
                streetAddress: "",
                unit: "",
                city: "",
                state: "",
                zipCode: "",
                doorCode: "",
                bikeLocks: "",
                camera: "",
                thermostat: "",
                other: "",
                airbnbListingURL: "",
                vrboListingURL: "",
                bookingComListingURL: "",
                notes: ""
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
    
    func getProperty(byId propertyId: String) -> Property? {
        return properties.first { $0.id.uuidString == propertyId }
    }
    
    // Get all bookings from all properties
    func getAllBookings() async -> [Booking] {
        var allBookings: [Booking] = []
        
        for property in properties {
            let bookings = await BookingService.shared.fetchAllBookings(for: property)
            allBookings.append(contentsOf: bookings)
        }
        
        return allBookings
    }
    
    // Update properties from admin panel
    func updateProperties(_ configs: [PropertyConfig]) {
        properties = configs.map { config in
            // Convert iCalFeeds array to CalendarSource array
            let sources = config.iCalFeeds.compactMap { feed -> CalendarSource? in
                guard !feed.url.isEmpty, let url = URL(string: feed.url) else { return nil }
                
                // Map platform name to Platform enum
                let platform: Platform
                switch feed.platformName.lowercased() {
                case "airbnb":
                    platform = .airbnb
                case "vrbo":
                    platform = .vrbo
                case "booking.com":
                    platform = .bookingCom
                default:
                    platform = .airbnb // Default for custom feeds
                }
                
                return CalendarSource(platform: platform, url: url)
            }
            
            let shortName = config.unitName
            let name = config.displayName.lowercased().replacingOccurrences(of: " ", with: "-")
            
            return Property(
                name: name,
                displayName: config.displayName,
                shortName: shortName,
                colorHex: config.color.toHex(),
                sources: sources,
                ownerName: "",
                ownerPhone: "",
                ownerEmail: "",
                streetAddress: config.streetAddress,
                unit: config.unit,
                city: config.city,
                state: config.state,
                zipCode: config.zipCode,
                doorCode: "",
                bikeLocks: "",
                camera: "",
                thermostat: "",
                other: "",
                airbnbListingURL: "",
                vrboListingURL: "",
                bookingComListingURL: "",
                notes: ""
            )
        }
        
        saveProperties()
        
        // Post notification to refresh calendar
        NotificationCenter.default.post(name: .propertiesDidChange, object: nil)
    }
    
    // NEW: Update a single property from PropertyConfig (for bidirectional sync)
    func updatePropertyFromConfig(_ config: PropertyConfig) {
        guard let existingProperty = properties.first(where: { $0.id.uuidString == config.id }) else {
            return
        }
        
        // Convert iCalFeeds array to CalendarSource array
        let sources = config.iCalFeeds.compactMap { feed -> CalendarSource? in
            guard !feed.url.isEmpty, let url = URL(string: feed.url) else { return nil }
            
            // Map platform name to Platform enum
            let platform: Platform
            switch feed.platformName.lowercased() {
            case "airbnb":
                platform = .airbnb
            case "vrbo":
                platform = .vrbo
            case "booking.com":
                platform = .bookingCom
            default:
                platform = .airbnb // Default for custom feeds
            }
            
            return CalendarSource(platform: platform, url: url)
        }
        
        let shortName = config.unitName
        let name = config.displayName.lowercased().replacingOccurrences(of: " ", with: "-")
        
        let updatedProperty = Property(
            id: existingProperty.id,
            name: name,
            displayName: config.displayName,
            shortName: shortName,
            colorHex: config.color.toHex(),
            sources: sources,
            ownerName: existingProperty.ownerName,
            ownerPhone: existingProperty.ownerPhone,
            ownerEmail: existingProperty.ownerEmail,
            streetAddress: config.streetAddress,
            unit: config.unit,
            city: config.city,
            state: config.state,
            zipCode: config.zipCode,
            doorCode: existingProperty.doorCode,
            bikeLocks: existingProperty.bikeLocks,
            camera: existingProperty.camera,
            thermostat: existingProperty.thermostat,
            other: existingProperty.other,
            airbnbListingURL: existingProperty.airbnbListingURL,
            vrboListingURL: existingProperty.vrboListingURL,
            bookingComListingURL: existingProperty.bookingComListingURL,
            notes: existingProperty.notes
        )
        
        updateProperty(updatedProperty)
    }
}

// Codable wrapper for Property - UPDATED WITH NEW FIELDS
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
    let streetAddress: String
    let unit: String
    let city: String
    let state: String
    let zipCode: String
    let doorCode: String
    let bikeLocks: String
    let camera: String              // NEW
    let thermostat: String          // NEW
    let other: String               // NEW
    let airbnbListingURL: String    // NEW
    let vrboListingURL: String      // NEW
    let bookingComListingURL: String // NEW
    let notes: String
    let frontPhotoData: Data?       // NEW - Property photo
    
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
        self.streetAddress = property.streetAddress
        self.unit = property.unit
        self.city = property.city
        self.state = property.state
        self.zipCode = property.zipCode
        self.doorCode = property.doorCode
        self.bikeLocks = property.bikeLocks
        self.camera = property.camera                       // NEW
        self.thermostat = property.thermostat               // NEW
        self.other = property.other                         // NEW
        self.airbnbListingURL = property.airbnbListingURL   // NEW
        self.vrboListingURL = property.vrboListingURL       // NEW
        self.bookingComListingURL = property.bookingComListingURL // NEW
        self.notes = property.notes
        self.frontPhotoData = property.frontPhotoData       // NEW
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
            streetAddress: streetAddress,
            unit: unit,
            city: city,
            state: state,
            zipCode: zipCode,
            doorCode: doorCode,
            bikeLocks: bikeLocks,
            camera: camera,                         // NEW
            thermostat: thermostat,                 // NEW
            other: other,                           // NEW
            airbnbListingURL: airbnbListingURL,     // NEW
            vrboListingURL: vrboListingURL,         // NEW
            bookingComListingURL: bookingComListingURL, // NEW
            notes: notes,
            frontPhotoData: frontPhotoData          // NEW
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

// iCal Feed struct for dynamic feeds
struct ICalFeed: Identifiable, Codable, Equatable {
    let id: String
    var platformName: String
    var url: String
    let isDefault: Bool // true for AirBnB, VRBO, Booking.com
    
    init(id: String = UUID().uuidString, platformName: String, url: String = "", isDefault: Bool = false) {
        self.id = id
        self.platformName = platformName
        self.url = url
        self.isDefault = isDefault
    }
}

// PropertyConfig with DYNAMIC iCAL FEEDS
struct PropertyConfig: Identifiable, Codable {
    let id: String
    var complexName: String
    var unitName: String
    var streetAddress: String
    var unit: String
    var city: String
    var state: String
    var zipCode: String
    var iCalFeeds: [ICalFeed]
    var isLocked: Bool
    let colorHex: String
    
    var color: Color {
        Color(hex: colorHex) ?? .blue
    }
    
    var displayName: String {
        "\(complexName) \(unitName)"
    }
    
    init(id: String,
         complexName: String,
         unitName: String,
         streetAddress: String = "",
         unit: String = "",
         city: String = "",
         state: String = "",
         zipCode: String = "",
         iCalFeeds: [ICalFeed]? = nil,
         isLocked: Bool = true,
         color: Color) {
        self.id = id
        self.complexName = complexName
        self.unitName = unitName
        self.streetAddress = streetAddress
        self.unit = unit
        self.city = city
        self.state = state
        self.zipCode = zipCode
        
        // Default 3 feeds if none provided
        self.iCalFeeds = iCalFeeds ?? [
            ICalFeed(platformName: "AirBnB", isDefault: true),
            ICalFeed(platformName: "VRBO", isDefault: true),
            ICalFeed(platformName: "Booking.com", isDefault: true)
        ]
        
        self.isLocked = isLocked
        self.colorHex = color.toHex()
    }
}

// Color init(hex:) extension is defined in DateExtensions.swift


