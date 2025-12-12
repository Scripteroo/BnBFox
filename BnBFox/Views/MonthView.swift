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
            
            // Calendar weeks
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
        ZStack(alignment: .topLeading) {
            // Background grid
            HStack(spacing: 0) {
                ForEach(Array(week.enumerated()), id: \.offset) { index, date in
                    Rectangle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        .background(Color.white)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 100) // Tall cells with lots of white space
            
            VStack(alignment: .leading, spacing: 0) {
                // Day numbers row
                HStack(spacing: 0) {
                    ForEach(Array(week.enumerated()), id: \.offset) { index, date in
                        ZStack {
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
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .frame(height: 32)
                .padding(.top, 4)
                
                Spacer()
                
                // Property rows at bottom
                VStack(spacing: 2) {
                    ForEach(properties) { property in
                        PropertyRow(
                            property: property,
                            week: week,
                            bookings: getBookingsForProperty(property)
                        )
                    }
                }
                .padding(.bottom, 4)
                .padding(.horizontal, 2)
            }
            .frame(height: 100)
        }
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
        GeometryReader { geometry in
            let totalWidth = geometry.size.width
            let cellWidth = totalWidth / 7
            
            ZStack(alignment: .leading) {
                // Draw each booking as a continuous bar
                ForEach(bookings, id: \.id) { booking in
                    ContinuousBookingBar(
                        booking: booking,
                        property: property,
                        week: week,
                        cellWidth: cellWidth
                    )
                }
            }
        }
        .frame(height: 16) // Thin bars
    }
}

struct ContinuousBookingBar: View {
    let booking: Booking
    let property: Property
    let week: [Date?]
    let cellWidth: CGFloat
    
    var body: some View {
        let barGeometry = calculateBarGeometry()
        
        if barGeometry.width > 0 {
            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(property.color)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.black, lineWidth: 1.5)
                    )
                    .overlay(
                        // Property label
                        Text(property.shortName)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.trailing, 6)
                    )
            }
            .frame(width: barGeometry.width)
            .offset(x: barGeometry.offset)
        }
    }
    
    private func calculateBarGeometry() -> (offset: CGFloat, width: CGFloat) {
        let calendar = Calendar.current
        var startIndex: Int?
        var endIndex: Int?
        var startOffset: CGFloat = 0
        var endOffset: CGFloat = 0
        
        // Find which days in this week the booking spans
        for (index, date) in week.enumerated() {
            guard let date = date else { continue }
            
            if booking.overlapsDate(date) {
                if startIndex == nil {
                    startIndex = index
                    // Check if this is the actual start date
                    if calendar.isDate(booking.startDate, inSameDayAs: date) {
                        startOffset = 0.5 // Start at midday (4PM check-in)
                    } else {
                        startOffset = 0 // Continues from previous week
                    }
                }
                endIndex = index
                // Check if this is the actual end date
                if calendar.isDate(booking.endDate, inSameDayAs: date) {
                    endOffset = 0.5 // End at midday (10AM check-out)
                } else {
                    endOffset = 1.0 // Continues to next week
                }
            }
        }
        
        guard let start = startIndex, let end = endIndex else {
            return (0, 0)
        }
        
        let offset = (CGFloat(start) + startOffset) * cellWidth
        let width = (CGFloat(end - start) + endOffset - startOffset) * cellWidth
        
        return (offset, width)
    }
}
