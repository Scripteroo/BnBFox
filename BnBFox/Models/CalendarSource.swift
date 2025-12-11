//
//  CalendarSource.swift
//  BnBFox
//
//  Created on 12/11/2025.
//

import Foundation

struct CalendarSource: Identifiable, Codable {
    let id: UUID
    let platform: Platform
    let url: URL
    
    init(id: UUID = UUID(), platform: Platform, url: URL) {
        self.id = id
        self.platform = platform
        self.url = url
    }
}
