//
//  Property.swift
//  BnBFox
//
//  Created on 12/11/2025.
//

import Foundation
import SwiftUI

struct Property: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let displayName: String
    let shortName: String
    let colorHex: String
    let sources: [CalendarSource]
    
    // Owner information
    var ownerName: String
    var ownerPhone: String
    var ownerEmail: String
    
    // Access codes and property info
    var doorCode: String
    var bikeLocks: String
    var camera: String          // NEW
    var thermostat: String      // NEW
    var other: String           // NEW
    
    // Listing URLs
    var airbnbListingURL: String      // NEW
    var vrboListingURL: String        // NEW
    var bookingComListingURL: String  // NEW
    
    // Notes
    var notes: String
    
    var color: Color {
        Color(hex: colorHex) ?? .blue
    }
    
    var complexName: String {
        // Extract complex name from displayName (e.g., "Kawama" from "Kawama C-2")
        let components = displayName.split(separator: " ")
        return components.count > 1 ? String(components[0]) : "Complex"
    }
    
    var unitName: String {
        // Extract unit name from displayName (e.g., "C-2" from "Kawama C-2")
        let components = displayName.split(separator: " ")
        return components.count > 1 ? components.dropFirst().joined(separator: " ") : displayName
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        displayName: String,
        shortName: String,
        colorHex: String,
        sources: [CalendarSource],
        ownerName: String = "",
        ownerPhone: String = "",
        ownerEmail: String = "",
        doorCode: String = "",
        bikeLocks: String = "",
        camera: String = "",
        thermostat: String = "",
        other: String = "",
        airbnbListingURL: String = "",
        vrboListingURL: String = "",
        bookingComListingURL: String = "",
        notes: String = ""
    ) {
        self.id = id
        self.name = name
        self.displayName = displayName
        self.shortName = shortName
        self.colorHex = colorHex
        self.sources = sources
        self.ownerName = ownerName
        self.ownerPhone = ownerPhone
        self.ownerEmail = ownerEmail
        self.doorCode = doorCode
        self.bikeLocks = bikeLocks
        self.camera = camera
        self.thermostat = thermostat
        self.other = other
        self.airbnbListingURL = airbnbListingURL
        self.vrboListingURL = vrboListingURL
        self.bookingComListingURL = bookingComListingURL
        self.notes = notes
    }
    
    static func == (lhs: Property, rhs: Property) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
