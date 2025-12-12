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
            
            // Calendar weeks
            ForEach(Array(generateWeeks().enumerated()), id: \.offset) { weekIndex, week in
                WeekRow(
                    week: week,
                    bookings: bookings,
                    currentMonth: month
                )
            }
        }
        .padding(.horizontal, 8)
    }
    
    private func generateWeeks() -> [[Date?]] {
        let calendar = Calendar.current
        let startOfMonth = month.startOfMonth()
        let firstWeekday = month.firstWeekdayOfMonth()
        let daysInMonth = month.daysInMonth()
        
        var weeks: [[Date?]] = []
        var currentWeek: [Date?] = []
        
        // Add empty cells before the first day
        for _ in 1..<firstWeekday {
            currentWeek.append(nil)
        }
        
        // Add all days of the month
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                currentWeek.append(date)
                
                // Start new week on Sunday
                if currentWeek.count == 7 {
                    weeks.append(currentWeek)
                    currentWeek = []
                }
            }
        }
        
        // Fill the last week with empty cells
        while currentWeek.count < 7 && currentWeek.count > 0 {
            currentWeek.append(nil)
        }
        
        if !currentWeek.isEmpty {
            weeks.append(currentWeek)
        }
        
        return weeks
    }
}

struct WeekRow: View {
    let week: [Date?]
    let bookings: [Booking]
    let currentMonth: Date
    
    var body: some View {
        VStack(spacing: 0) {
            // Day numbers row
            HStack(spacing: 0) {
                ForEach(Array(week.enumerated()), id: \.offset) { index, date in
                    if let date = date {
                        Text("\(date.dayNumber())")
                            .font(.system(size: 14))
                            .fontWeight(date.isToday() ? .bold : .regular)
                            .foregroundColor(isInCurrentMonth(date) ? .primary : .gray.opacity(0.5))
                            .frame(width: 24, height: 24)
                            .background(
                                Circle()
                                    .fill(date.isToday() ? Color.blue : Color.clear)
                            )
                            .foregroundColor(date.isToday() ? .white : (isInCurrentMonth(date) ? .primary : .gray.opacity(0.5)))
                            .frame(maxWidth: .infinity)
                    } else {
                        Color.clear
                            .frame(maxWidth: .infinity, minHeight: 24)
                    }
                }
            }
            .padding(.top, 4)
            
            // Booking bars
            VStack(alignment: .leading, spacing: 2) {
                ForEach(getWeekBookings(), id: \.id) { booking in
                    if let property = booking.getProperty() {
                        HorizontalBookingBar(
                            booking: booking,
                            property: property,
                            week: week
                        )
                    }
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 4)
            .frame(minHeight: 60)
        }
        .background(Color.white)
        .overlay(
            Rectangle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
        )
    }
    
    private func isInCurrentMonth(_ date: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
    }
    
    private func getWeekBookings() -> [Booking] {
        guard let firstDate = week.compactMap({ $0 }).first,
              let lastDate = week.compactMap({ $0 }).last else {
            return []
        }
        
        return bookings.filter { booking in
            // Check if booking overlaps with this week
            let bookingStart = booking.startDate
            let bookingEnd = booking.endDate
            
            return (bookingStart...bookingEnd).overlaps(firstDate...lastDate)
        }
    }
}

struct HorizontalBookingBar: View {
    let booking: Booking
    let property: Property
    let week: [Date?]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(week.enumerated()), id: \.offset) { index, date in
                if let date = date {
                    if booking.overlapsDate(date) {
                        // Show booking bar segment
                        Text(labelText(for: date))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                            .background(property.color)
                            .cornerRadius(2)
                    } else {
                        // Empty space
                        Color.clear
                            .frame(maxWidth: .infinity)
                    }
                } else {
                    // Empty cell
                    Color.clear
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .frame(height: 22)
    }
    
    private func labelText(for date: Date) -> String {
        // Show property short name on the first day of the booking
        if booking.isFirstDay(of: date) {
            return property.shortName
        }
        return ""
    }
}
