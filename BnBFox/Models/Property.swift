//
//  Property.swift
//  BnBShift
//
//  Created on 12/11/2025.
//

import Foundation
import SwiftUI

struct Property: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    var displayName: String  // Changed from 'let' to 'var' to allow editing
    let shortName: String
    var colorHex: String  // Changed from 'let' to 'var' to allow color updates
    let sources: [CalendarSource]
    
    // Owner information
    var ownerName: String
    var ownerPhone: String
    var ownerEmail: String
    
    // Address information
    var streetAddress: String
    var unit: String
    var city: String
    var state: String
    var zipCode: String
    
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
    
    // Property photo
    var frontPhotoData: Data?
    
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
    
    var fullAddress: String {
        // Compute full address from components
        var parts: [String] = []
        if !streetAddress.isEmpty { parts.append(streetAddress) }
        if !unit.isEmpty { parts.append(unit) }
        if !city.isEmpty || !state.isEmpty || !zipCode.isEmpty {
            let cityStateZip = [city, state, zipCode].filter { !$0.isEmpty }.joined(separator: " ")
            if !cityStateZip.isEmpty { parts.append(cityStateZip) }
        }
        return parts.joined(separator: ", ")
    }
    
    var mapsURL: URL? {
        // Generate Apple Maps URL from address
        guard !fullAddress.isEmpty else { return nil }
        let encodedAddress = fullAddress.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "http://maps.apple.com/?address=\(encodedAddress)")
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
        streetAddress: String = "",
        unit: String = "",
        city: String = "",
        state: String = "",
        zipCode: String = "",
        doorCode: String = "",
        bikeLocks: String = "",
        camera: String = "",
        thermostat: String = "",
        other: String = "",
        airbnbListingURL: String = "",
        vrboListingURL: String = "",
        bookingComListingURL: String = "",
        notes: String = "",
        frontPhotoData: Data? = nil
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
        self.streetAddress = streetAddress
        self.unit = unit
        self.city = city
        self.state = state
        self.zipCode = zipCode
        self.doorCode = doorCode
        self.bikeLocks = bikeLocks
        self.camera = camera
        self.thermostat = thermostat
        self.other = other
        self.airbnbListingURL = airbnbListingURL
        self.vrboListingURL = vrboListingURL
        self.bookingComListingURL = bookingComListingURL
        self.notes = notes
        self.frontPhotoData = frontPhotoData
    }
    
    static func == (lhs: Property, rhs: Property) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}


