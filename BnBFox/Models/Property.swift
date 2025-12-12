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
    
    init(id: UUID = UUID(), name: String, displayName: String, shortName: String, colorHex: String, sources: [CalendarSource]) {
        self.id = id
        self.name = name
        self.displayName = displayName
        self.shortName = shortName
        self.colorHex = colorHex
        self.sources = sources
    }
    
    static func == (lhs: Property, rhs: Property) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
