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
    let columnIndex: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let date = date {
                // Day number at top
                Text("\(date.dayNumber())")
                    .font(.system(size: 14))
                    .fontWeight(date.isToday() ? .bold : .regular)
                    .foregroundColor(isCurrentMonth ? .primary : .gray.opacity(0.5))
                    .frame(width: 24, height: 24)
                    .background(
                        Circle()
                            .fill(date.isToday() ? Color.blue : Color.clear)
                    )
                    .foregroundColor(date.isToday() ? .white : (isCurrentMonth ? .primary : .gray.opacity(0.5)))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 4)
                
                // Booking bars stacked vertically
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(bookings, id: \.id) { booking in
                        if let property = booking.getProperty() {
                            BookingBar(
                                booking: booking,
                                property: property,
                                startDate: date,
                                daysVisible: 1
                            )
                        }
                    }
                }
                .padding(.horizontal, 2)
                .padding(.top, 4)
                .padding(.bottom, 4)
                
                Spacer()
            }
        }
        .frame(height: 100)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .overlay(
            Rectangle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
        )
    }
}
