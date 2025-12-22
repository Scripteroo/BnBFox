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
    var displayName: String  // Changed from 'let' to 'var' to allow editing
    let shortName: String
    var colorHex: String  // Changed from 'let' to 'var' to allow color updates
    let sources: [CalendarSource]
    
    // Address information
    var streetAddress: String
    var unit: String
    var city: String
    var state: String
    var zipCode: String
    
    // Owner information
    var ownerName: String
    var ownerPhone: String
    var ownerEmail: String
    
    // Access codes and property info
    var doorCode: String
    var bikeLocks: String
    var camera: String
    var thermostat: String
    var other: String
    
    // Listing URLs
    var airbnbListingURL: String
    var vrboListingURL: String
    var bookingComListingURL: String
    
    // Notes
    var notes: String
    
    // Cleaning status: "clean", "in-progress", "needs-cleaning"
    var cleaningStatus: String
    
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
    
    // Full address for display
    var fullAddress: String {
        var address = ""
        if !streetAddress.isEmpty {
            address += streetAddress
        }
        if !unit.isEmpty {
            address += "\n" + unit
        }
        if !city.isEmpty || !state.isEmpty || !zipCode.isEmpty {
            address += "\n"
            if !city.isEmpty {
                address += city
            }
            if !state.isEmpty {
                if !city.isEmpty {
                    address += ", "
                }
                address += state
            }
            if !zipCode.isEmpty {
                if !city.isEmpty || !state.isEmpty {
                    address += " "
                }
                address += zipCode
            }
        }
        return address.isEmpty ? "No address set" : address
    }
    
    // Maps URL for opening in Maps app
    var mapsURL: URL? {
        let addressComponents = [streetAddress, unit, city, state, zipCode]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
        
        guard !addressComponents.isEmpty else { return nil }
        
        let encodedAddress = addressComponents.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "maps://?address=\(encodedAddress)")
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        displayName: String,
        shortName: String,
        colorHex: String,
        sources: [CalendarSource],
        streetAddress: String = "",
        unit: String = "",
        city: String = "",
        state: String = "",
        zipCode: String = "",
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
        notes: String = "",
        cleaningStatus: String = "needs-cleaning"
    ) {
        self.id = id
        self.name = name
        self.displayName = displayName
        self.shortName = shortName
        self.colorHex = colorHex
        self.sources = sources
        self.streetAddress = streetAddress
        self.unit = unit
        self.city = city
        self.state = state
        self.zipCode = zipCode
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
        self.cleaningStatus = cleaningStatus
    }
    
    static func == (lhs: Property, rhs: Property) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

