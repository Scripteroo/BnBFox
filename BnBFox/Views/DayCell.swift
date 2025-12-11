//
//  DayCell.swift
//  BnBFox
//
//  Created on 12/11/2025.
//

import SwiftUI

struct DayCell: View {
    let date: Date?
    let bookings: [Booking]
    let isCurrentMonth: Bool
    
    private let maxVisibleBookings = 3
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let date = date {
                // Day number
                HStack {
                    Spacer()
                    Text("\(date.dayNumber())")
                        .font(.system(size: 14))
                        .fontWeight(date.isToday() ? .bold : .regular)
                        .foregroundColor(isCurrentMonth ? .primary : .gray.opacity(0.5))
                        .frame(width: 24, height: 24)
                        .background(
                            Circle()
                                .fill(date.isToday() ? Color.blue : Color.clear)
                        )
                        .foregroundColor(date.isToday() ? .white : .primary)
                    Spacer()
                }
                
                // Bookings
                VStack(alignment: .leading, spacing: 1) {
                    ForEach(Array(bookings.prefix(maxVisibleBookings)), id: \.id) { booking in
                        BookingBadge(
                            booking: booking,
                            date: date,
                            isCompact: bookings.count > 2
                        )
                    }
                    
                    if bookings.count > maxVisibleBookings {
                        Text("+\(bookings.count - maxVisibleBookings)")
                            .font(.system(size: 8))
                            .foregroundColor(.gray)
                            .padding(.leading, 2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(height: 80)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .overlay(
            Rectangle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
        )
    }
}
