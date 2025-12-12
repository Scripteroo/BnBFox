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
                    GeometryReader { geometry in
                        let width = geometry.size.width
                        let daySegment = getDaySegment(for: date)
                        
                        if daySegment != .none {
                            HStack(spacing: 0) {
                                // Left spacer for check-in day (starts at 50%)
                                if daySegment == .checkInOnly || daySegment == .checkInMiddle {
                                    Color.clear
                                        .frame(width: width * 0.5)
                                }
                                
                                // Booking bar segment
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(property.color)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 4)
                                                .stroke(Color.black, lineWidth: 1.5)
                                        )
                                    
                                    // Label on check-in day
                                    if booking.isFirstDay(of: date) {
                                        Text(property.shortName)
                                            .font(.system(size: 10, weight: .semibold))
                                            .foregroundColor(.white)
                                            .padding(.leading, 4)
                                    }
                                }
                                .frame(width: segmentWidth(for: daySegment, totalWidth: width))
                                
                                // Right spacer for check-out day (ends at 50%)
                                if daySegment == .checkOutOnly || daySegment == .checkOutMiddle {
                                    Color.clear
                                        .frame(width: width * 0.5)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    // Empty cell
                    Color.clear
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .frame(height: 24)
    }
    
    private enum DaySegment {
        case none
        case checkInOnly        // Check-in day only (no checkout same day) - starts at 50%
        case checkOutOnly       // Check-out day only - ends at 50%
        case checkInMiddle      // Check-in day with continuation - starts at 50%, full width after
        case checkOutMiddle     // Check-out day with continuation - full width before, ends at 50%
        case fullDay            // Middle day - full width
    }
    
    private func getDaySegment(for date: Date) -> DaySegment {
        let calendar = Calendar.current
        let isCheckIn = calendar.isDate(booking.startDate, inSameDayAs: date)
        let isCheckOut = calendar.isDate(booking.endDate, inSameDayAs: date)
        let isMiddle = date > booking.startDate && date < booking.endDate
        
        if isCheckIn && isCheckOut {
            // Same day check-in and check-out (shouldn't happen in practice)
            return .checkInOnly
        } else if isCheckIn {
            return .checkInMiddle
        } else if isCheckOut {
            return .checkOutMiddle
        } else if isMiddle {
            return .fullDay
        } else {
            return .none
        }
    }
    
    private func segmentWidth(for segment: DaySegment, totalWidth: CGFloat) -> CGFloat {
        switch segment {
        case .none:
            return 0
        case .checkInOnly:
            return totalWidth * 0.5  // Right half only
        case .checkOutOnly:
            return totalWidth * 0.5  // Left half only
        case .checkInMiddle:
            return totalWidth * 0.5  // Right half of check-in day
        case .checkOutMiddle:
            return totalWidth * 0.5  // Left half of check-out day
        case .fullDay:
            return totalWidth        // Full day
        }
    }
}
