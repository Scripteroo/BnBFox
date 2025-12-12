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
    private let propertyService = PropertyService.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Month title
            Text(month.monthName())
                .font(.system(size: 18, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 12)
            
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
            
            // Calendar weeks with property rows
            ForEach(Array(generateWeeks().enumerated()), id: \.offset) { weekIndex, week in
                WeekSection(
                    week: week,
                    bookings: bookings,
                    currentMonth: month,
                    properties: propertyService.getAllProperties()
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

struct WeekSection: View {
    let week: [Date?]
    let bookings: [Booking]
    let currentMonth: Date
    let properties: [Property]
    
    var body: some View {
        VStack(spacing: 0) {
            // Day numbers row
            HStack(spacing: 0) {
                ForEach(Array(week.enumerated()), id: \.offset) { index, date in
                    ZStack {
                        // Grid line background
                        Rectangle()
                            .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                        
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
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 32)
            
            // Property rows
            ForEach(properties) { property in
                PropertyRow(
                    property: property,
                    week: week,
                    bookings: getBookingsForProperty(property)
                )
            }
        }
        .background(Color.white)
    }
    
    private func isInCurrentMonth(_ date: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
    }
    
    private func getBookingsForProperty(_ property: Property) -> [Booking] {
        guard let firstDate = week.compactMap({ $0 }).first,
              let lastDate = week.compactMap({ $0 }).last else {
            return []
        }
        
        return bookings.filter { booking in
            booking.propertyId == property.id &&
            (booking.startDate...booking.endDate).overlaps(firstDate...lastDate)
        }
    }
}

struct PropertyRow: View {
    let property: Property
    let week: [Date?]
    let bookings: [Booking]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(week.enumerated()), id: \.offset) { index, date in
                ZStack {
                    // Grid line background
                    Rectangle()
                        .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                        .background(Color.white)
                    
                    if let date = date {
                        // Check if there's a booking on this date
                        if let booking = bookings.first(where: { $0.overlapsDate(date) }) {
                            BookingSegment(
                                booking: booking,
                                property: property,
                                date: date
                            )
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 24)
    }
}

struct BookingSegment: View {
    let booking: Booking
    let property: Property
    let date: Date
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let segment = getSegmentType()
            
            HStack(spacing: 0) {
                // Left spacer for check-in day
                if segment == .checkIn {
                    Color.clear
                        .frame(width: width * 0.5)
                }
                
                // Booking bar
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(property.color)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(Color.black, lineWidth: 1.5)
                        )
                    
                    // Property label on first day
                    if Calendar.current.isDate(booking.startDate, inSameDayAs: date) {
                        Text(property.shortName)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.leading, 4)
                    }
                }
                .frame(width: getSegmentWidth(segment, totalWidth: width))
                
                // Right spacer for check-out day
                if segment == .checkOut {
                    Color.clear
                        .frame(width: width * 0.5)
                }
            }
        }
    }
    
    private enum SegmentType {
        case checkIn    // First day - starts at 50%
        case checkOut   // Last day - ends at 50%
        case full       // Middle day - full width
    }
    
    private func getSegmentType() -> SegmentType {
        let calendar = Calendar.current
        let isFirst = calendar.isDate(booking.startDate, inSameDayAs: date)
        let isLast = calendar.isDate(booking.endDate, inSameDayAs: date)
        
        if isFirst {
            return .checkIn
        } else if isLast {
            return .checkOut
        } else {
            return .full
        }
    }
    
    private func getSegmentWidth(_ segment: SegmentType, totalWidth: CGFloat) -> CGFloat {
        switch segment {
        case .checkIn, .checkOut:
            return totalWidth * 0.5
        case .full:
            return totalWidth
        }
    }
}
