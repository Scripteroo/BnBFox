//
//  Property.swift
//  BnBFox
//
//  Created on 12/11/2025.
//

import Foundation

struct Property: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let displayName: String
    let sources: [CalendarSource]
    
    init(id: UUID = UUID(), name: String, displayName: String, sources: [CalendarSource]) {
        self.id = id
        self.name = name
        self.displayName = displayName
        self.sources = sources
    }
    
    static func == (lhs: Property, rhs: Property) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
