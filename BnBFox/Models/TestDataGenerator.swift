//
//  TestDataGenerator.swift
//  BnBShift
//
//  Test data generator for calendar testing
//

import Foundation
import SwiftUI

class TestDataGenerator {
    static let shared = TestDataGenerator()
    private init() {}
    
    // Cache test properties to ensure consistent IDs
    private var cachedTestProperties: [Property]?
    
    func resetCache() {
        cachedTestProperties = nil
    }
    
    private let propertyNames = [
        ("Sunset Villa", "Unit A"),
        ("Ocean View", "Unit B"),
        ("Mountain Lodge", "Unit C"),
        ("Beach House", "Unit D"),
        ("City Loft", "Unit E"),
        ("Garden Suite", "Unit F"),
        ("Harbor View", "Unit G"),
        ("Forest Cabin", "Unit H"),
        ("Lake House", "Unit I"),
        ("Desert Oasis", "Unit J"),
        ("River Cottage", "Unit K"),
        ("Valley Ranch", "Unit L")
    ]
    
    private let colors: [String] = [
        "FF6B35", // Orange
        "FFD23F", // Yellow
        "007AFF", // Blue
        "34C759", // Green
        "AF52DE", // Purple
        "FF2D55", // Pink
        "FF9500", // Amber
        "5AC8FA", // Cyan
        "FF3B30", // Red
        "32ADE6", // Light Blue
        "8E8E93", // Gray
        "BF5AF2"  // Magenta
    ]
    
    func generateTestProperties() -> [Property] {
        // Return cached properties if they exist
        if let cached = cachedTestProperties {
            return cached
        }
        
        var properties: [Property] = []
        
        for (index, (complex, unit)) in propertyNames.enumerated() {
            let property = Property(
                name: "\(complex.lowercased().replacingOccurrences(of: " ", with: "-"))-\(unit.lowercased())",
                displayName: "\(complex) \(unit)",
                shortName: unit,
                colorHex: colors[index],
                sources: [], // No real iCal sources in test mode
                ownerName: "Test Owner",
                ownerPhone: "+1234567890",
                ownerEmail: "test@example.com",
                streetAddress: "123 Test Street",
                unit: unit,
                city: "Test City",
                state: "TS",
                zipCode: "12345",
                doorCode: "1234",
                bikeLocks: "1234",
                camera: "",
                thermostat: "",
                other: "",
                airbnbListingURL: "",
                vrboListingURL: "",
                bookingComListingURL: "",
                notes: "Test property"
            )
            properties.append(property)
        }
        
        // Cache the properties
        cachedTestProperties = properties
        return properties
    }
    
    func generateTestBookings(for properties: [Property]) -> [Booking] {
        var bookings: [Booking] = []
        let calendar = Calendar.current
        let today = Date()
        
        // Generate bookings for the next 6 months
        for property in properties {
            // Each property gets 8-15 random bookings
            let bookingCount = Int.random(in: 8...15)
            
            for i in 0..<bookingCount {
                // Random start date within next 6 months
                let daysOffset = Int.random(in: -30...180)
                guard let startDate = calendar.date(byAdding: .day, value: daysOffset, to: today) else { continue }
                
                // Random duration 2-14 days
                let duration = Int.random(in: 2...14)
                guard let endDate = calendar.date(byAdding: .day, value: duration, to: startDate) else { continue }
                
                // Random guest name
                let guestNames = ["John Smith", "Jane Doe", "Bob Johnson", "Alice Williams", "Charlie Brown", "Diana Prince", "Eve Adams", "Frank Miller"]
                let guestName = guestNames.randomElement() ?? "Guest"
                
                // Random platform
                let platforms: [Platform] = [.airbnb, .vrbo, .bookingCom]
                let platform = platforms.randomElement() ?? .airbnb
                
                let booking = Booking(
                    id: "TEST-\(property.id.uuidString)-\(i)",
                    startDate: startDate,
                    endDate: endDate,
                    guestName: guestName,
                    platform: platform,
                    propertyId: property.id
                )
                
                bookings.append(booking)
            }
        }
        
        return bookings.sorted { $0.startDate < $1.startDate }
    }
}

