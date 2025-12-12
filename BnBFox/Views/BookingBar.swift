//
//  BookingBar.swift
//  BnBFox
//
//  Created on 12/11/2025.
//

import SwiftUI

struct BookingBar: View {
    let booking: Booking
    let property: Property
    let startDate: Date
    let daysVisible: Int
    
    var body: some View {
        HStack(spacing: 0) {
            Text(labelText)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(property.color)
        .cornerRadius(4)
    }
    
    private var labelText: String {
        // Show property short name on the first visible day
        if Calendar.current.isDate(booking.startDate, inSameDayAs: startDate) {
            return property.shortName
        }
        return ""
    }
}
