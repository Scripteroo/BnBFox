//
//  PropertyService.swift
//  BnBFox
//
//  Created on 12/11/2025.
//

import Foundation

class PropertyService {
    static let shared = PropertyService()
    
    private init() {}
    
    private let properties: [Property] = [
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
        )
    ]
    
    func getAllProperties() -> [Property] {
        return properties
    }
    
    func getProperty(by id: UUID) -> Property? {
        return properties.first { $0.id == id }
    }
    
    func getProperty(by name: String) -> Property? {
        return properties.first { $0.name == name }
    }
}
