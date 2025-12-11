//
//  Platform.swift
//  BnBFox
//
//  Created on 12/11/2025.
//

import SwiftUI

enum Platform: String, Codable, CaseIterable {
    case airbnb = "AirBnB"
    case vrbo = "VRBO"
    case bookingCom = "Booking.com"
    
    var displayName: String {
        return self.rawValue
    }
    
    var color: Color {
        switch self {
        case .airbnb:
            return Color(red: 1.0, green: 0.36, blue: 0.45) // AirBnB pink/red
        case .vrbo:
            return Color(red: 0.0, green: 0.42, blue: 0.76) // VRBO blue
        case .bookingCom:
            return Color(red: 0.0, green: 0.27, blue: 0.64) // Booking.com dark blue
        }
    }
    
    var shortName: String {
        switch self {
        case .airbnb:
            return "AirBnB"
        case .vrbo:
            return "VRBO"
        case .bookingCom:
            return "Booking"
        }
    }
}
