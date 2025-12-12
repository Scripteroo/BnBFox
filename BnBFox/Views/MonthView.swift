//
//  MonthView.swift
//  BnBFox
//
//  Created on 12/11/2025.
//

import SwiftUI

struct MonthView: View {
    let month: Date
    let bookings: [Booking]
    
    private let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    
    var body: some View {
        VStack(spacing: 8) {
            // Month title
            Text(month.monthName())
                .font(.system(size: 18, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 8)
            
            // Day headers
            HStack(spacing: 0) {
                ForEach(Array(daysOfWeek.enumerated()), id: \.offset) { index, day in
                    Text(day)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 4)
            
            // Calendar grid
            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(generateCalendarDays(), id: \.offset) { item in
                    if let date = item.date {
                        let dayBookings = bookings.filter { $0.overlapsDate(date) }
                        DayCell(
                            date: date,
                            bookings: dayBookings,
                            isCurrentMonth: item.isCurrentMonth
                        )
                    } else {
                        // Empty cell for padding
                        Color.clear
                            .frame(height: 80)
                            .overlay(
                                Rectangle()
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                            )
                    }
                }
            }
        }
        .padding(.horizontal, 8)
    }
    
    private func generateCalendarDays() -> [(date: Date?, isCurrentMonth: Bool, offset: Int)] {
        let calendar = Calendar.current
        let startOfMonth = month.startOfMonth()
        let firstWeekday = month.firstWeekdayOfMonth()
        let daysInMonth = month.daysInMonth()
        
        var days: [(date: Date?, isCurrentMonth: Bool, offset: Int)] = []
        var offset = 0
        
        // Add empty cells for days before the first day of the month
        for _ in 1..<firstWeekday {
            days.append((date: nil, isCurrentMonth: false, offset: offset))
            offset += 1
        }
        
        // Add cells for each day in the month
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append((date: date, isCurrentMonth: true, offset: offset))
                offset += 1
            }
        }
        
        // Add empty cells to complete the last week
        let remainingCells = 7 - (days.count % 7)
        if remainingCells < 7 {
            for _ in 0..<remainingCells {
                days.append((date: nil, isCurrentMonth: false, offset: offset))
                offset += 1
            }
        }
        
        return days
    }
}
