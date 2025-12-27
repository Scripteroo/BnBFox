//
//  MonthView.swift
//  BnBShift
//
//  Updated with vertical scrolling for booking bars
//

import SwiftUI

struct MonthView: View {
    let month: Date
    let bookings: [Booking]
    let properties: [Property]  // NEW: Accept properties from CalendarViewModel
    var showMonthTitle: Bool = true  // Allow hiding the title to prevent duplicates
    var showDayHeaders: Bool = true  // Allow hiding day headers to prevent duplicates
    
    private let daysOfWeek = [
        DayOfWeek(id: 0, label: "S"),
        DayOfWeek(id: 1, label: "M"),
        DayOfWeek(id: 2, label: "T"),
        DayOfWeek(id: 3, label: "W"),
        DayOfWeek(id: 4, label: "T"),
        DayOfWeek(id: 5, label: "F"),
        DayOfWeek(id: 6, label: "S")
    ]
    
    private struct DayOfWeek: Identifiable {
        let id: Int
        let label: String
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Month title (optional)
            if showMonthTitle {
                Text(month.monthName())
                    .font(.system(size: 18, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
            }
            
            // Day headers (optional)
            if showDayHeaders {
                HStack(spacing: 0) {
                    ForEach(daysOfWeek) { day in
                        Text(day.label)
                            .font(.system(size: 13, weight: day.id == 0 ? .regular : .bold))
                            .foregroundColor(day.id == 0 ? .red : .black)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.bottom, 8)
            }
            
            // Calendar weeks
            ForEach(Array(generateWeeks().enumerated()), id: \.offset) { weekIndex, week in
                WeekSection(
                    week: week,
                    bookings: bookings,
                    currentMonth: month,
                    properties: properties  // Use passed properties
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
        
        // Add dates from previous month before the first day
        if firstWeekday > 1 {
            let daysToAdd = firstWeekday - 1
            for dayOffset in (1...daysToAdd).reversed() {
                if let prevDate = calendar.date(byAdding: .day, value: -dayOffset, to: startOfMonth) {
                    currentWeek.append(prevDate)
                }
            }
        }
        
        // Add all days of the current month
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
        
        // Fill the last week with dates from next month
        if currentWeek.count > 0 && currentWeek.count < 7 {
            let lastDayOfMonth = calendar.date(byAdding: .day, value: daysInMonth - 1, to: startOfMonth)!
            var dayOffset = 1
            while currentWeek.count < 7 {
                if let nextDate = calendar.date(byAdding: .day, value: dayOffset, to: lastDayOfMonth) {
                    currentWeek.append(nextDate)
                    dayOffset += 1
                }
            }
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
    
    @State private var dayDetailItem: DayDetailItem?
    
    // Calculate dynamic height based on number of properties
    private var weekHeight: CGFloat {
        let baseHeight: CGFloat = 50 // Height for day numbers and padding
        let propertyRowHeight: CGFloat = 22 // Height per property row (14px bar + 8px spacing)
        let maxVisibleRows: CGFloat = 6 // Show 6 properties before scrolling
        let scrollAreaHeight = min(CGFloat(properties.count), maxVisibleRows) * propertyRowHeight
        return baseHeight + scrollAreaHeight
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Background grid
            HStack(spacing: 0) {
                ForEach(Array(week.enumerated()), id: \.offset) { index, date in
                    let hasCheckout = date != nil ? dateHasCheckout(date!) : false
                    Rectangle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        .background(
                            hasCheckout ? Color.green.opacity(0.15) :
                            (isInCurrentMonth(date) ? Color.white : Color.gray.opacity(0.05))
                        )
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(height: weekHeight)
            
            VStack(alignment: .leading, spacing: 0) {
                // Day numbers row
                HStack(spacing: 0) {
                    ForEach(Array(week.enumerated()), id: \.offset) { index, date in
                        ZStack {
                            if let date = date {
                                let hasActivity = dateHasActivity(date)
                                
                                Text("\(date.dayNumber())")
                                    .font(.system(size: 15))
                                    .fontWeight(date.isToday() ? .bold : .regular)
                                    .foregroundColor(
                                        date.isToday() ? .white :
                                        (hasActivity ? .blue :
                                        (isInCurrentMonth(date) ? .primary : .gray.opacity(0.5)))
                                    )
                                    .underline(hasActivity && !date.isToday())
                                    .frame(width: 28, height: 28)
                                    .background(
                                        Circle()
                                            .fill(date.isToday() ? Color.blue : Color.clear)
                                    )
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        if hasActivity {
                                            let activities = getActivitiesForDate(date)
                                            if !activities.isEmpty {
                                                dayDetailItem = DayDetailItem(date: date, activities: activities)
                                            }
                                        }
                                    }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .frame(height: 28)
                .padding(.top, 2)
                
                Spacer()
                
                // Scrollable property rows area
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 3) {
                        ForEach(properties) { property in
                            PropertyRow(
                                property: property,
                                week: week,
                                bookings: getBookingsForProperty(property),
                                allBookings: bookings,
                                currentMonth: currentMonth
                            )
                        }
                    }
                    .padding(.horizontal, 2)
                }
                .frame(height: weekHeight - 50) // Subtract day numbers area
                .padding(.bottom, 4)
            }
            .frame(height: weekHeight)
        }
        .sheet(item: $dayDetailItem) { item in
            DayDetailView(date: item.date, activities: item.activities)
        }
    }
    
    private func isInCurrentMonth(_ date: Date?) -> Bool {
        guard let date = date else { return false }
        let calendar = Calendar.current
        return calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
    }
    
    private func dateHasCheckout(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        
        // Check if any property has check-out on this date
        for property in properties {
            let propertyBookings = bookings.filter { $0.propertyId == property.id }
            
            for booking in propertyBookings {
                let bookingEnd = calendar.startOfDay(for: booking.endDate)
                
                if calendar.isDate(bookingEnd, inSameDayAs: dayStart) {
                    return true
                }
            }
        }
        
        return false
    }
    
    private func dateHasActivity(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        
        // Check if any property has check-in or check-out on this date
        for property in properties {
            let propertyBookings = bookings.filter { $0.propertyId == property.id }
            
            for booking in propertyBookings {
                let bookingStart = calendar.startOfDay(for: booking.startDate)
                let bookingEnd = calendar.startOfDay(for: booking.endDate)
                
                // Check-in on this date
                if calendar.isDate(bookingStart, inSameDayAs: dayStart) {
                    return true
                }
                
                // Check-out on this date
                if calendar.isDate(bookingEnd, inSameDayAs: dayStart) {
                    return true
                }
            }
        }
        
        // NEW: Check if any property needs cleaning on this date
        if dateHasCleaningActivity(date) {
            return true
        }
        
        return false
    }
    
    // NEW: Check if any property has a cleaning dot (needs cleaning) on this date
    private func dateHasCleaningActivity(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let now = calendar.startOfDay(for: Date())
        
        for property in properties {
            // Get current gap info for this property
            if let gap = CleaningGapCache.shared.getCurrentGapInfo(propertyId: property.id, bookings: bookings) {
                // Check if this date is in the gap range and conditions match CleaningStatusDot logic
                if dayStart >= gap.gapStart && dayStart <= gap.gapEnd && now <= gap.gapEnd && dayStart <= now {
                    // Make sure this date is not during an active booking
                    if !isDuringActiveBooking(propertyId: property.id, date: dayStart) {
                        // Check if property needs cleaning (not marked as done)
                        if let status = CleaningStatusManager.shared.getStatus(propertyName: property.displayName, date: gap.checkoutDate) {
                            // Make clickable if status is NOT done (red, orange, or gray dots)
                            if status.status != .done {
                                return true
                            }
                        } else {
                            // No status set = needs cleaning (red dot) = clickable
                            return true
                        }
                    }
                }
            }
        }
        
        return false
    }
    
    // NEW: Helper to check if a date is during an active booking
    private func isDuringActiveBooking(propertyId: UUID, date: Date) -> Bool {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        
        let propertyBookings = bookings.filter { $0.propertyId == propertyId }
        
        for booking in propertyBookings {
            let bookingStart = calendar.startOfDay(for: booking.startDate)
            let bookingEnd = calendar.startOfDay(for: booking.endDate)
            // Check if this day is DURING a booking (day AFTER checkin through day before checkout)
            if dayStart > bookingStart && dayStart < bookingEnd {
                return true
            }
        }
        return false
    }
    
    private func getActivitiesForDate(_ date: Date) -> [PropertyActivity] {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        var activities: [PropertyActivity] = []
        
        for property in properties {
            let propertyBookings = bookings.filter { $0.propertyId == property.id }
            
            var checkin: BookingInfo?
            var checkout: BookingInfo?
            
            for booking in propertyBookings {
                let bookingStart = calendar.startOfDay(for: booking.startDate)
                let bookingEnd = calendar.startOfDay(for: booking.endDate)
                
                // Check-in on this date
                if calendar.isDate(bookingStart, inSameDayAs: dayStart) {
                    checkin = BookingInfo(
                        guestName: booking.guestName,
                        booking: booking
                    )
                }
                
                // Check-out on this date
                if calendar.isDate(bookingEnd, inSameDayAs: dayStart) {
                    checkout = BookingInfo(
                        guestName: booking.guestName,
                        booking: booking
                    )
                }
            }
            
            // Only add if there's activity
            if checkin != nil || checkout != nil {
                activities.append(PropertyActivity(
                    property: property,
                    checkin: checkin,
                    checkout: checkout
                ))
            }
        }
        
        return activities
    }
    
    private func getBookingsForProperty(_ property: Property) -> [Booking] {
        guard let firstDate = week.compactMap({ $0 }).first,
              let lastDate = week.compactMap({ $0 }).last else {
            return []
        }
        
        // Get the day after lastDate to check for bookings that end on the next day
        let calendar = Calendar.current
        let dayAfterLast = calendar.date(byAdding: .day, value: 1, to: lastDate) ?? lastDate
        
        return bookings.filter { booking in
            booking.propertyId == property.id &&
            booking.startDate < dayAfterLast &&
            booking.endDate >= firstDate
        }
    }
}

// PropertyRow remains unchanged - just copy from original file
// (Lines 319-529 from original MonthView.swift)

struct PropertyRow: View {
    let property: Property
    let week: [Date?]
    let bookings: [Booking]
    let allBookings: [Booking]
    let currentMonth: Date
    
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
                        cellWidth: cellWidth,
                        allBookings: allBookings,
                        currentMonth: currentMonth
                    )
                }
                
                // Draw cleaning status dots in gap areas (between bookings)
                ForEach(Array(week.enumerated()), id: \.offset) { index, date in
                    if let date = date {
                        CleaningStatusDot(
                            propertyName: property.displayName,
                            propertyId: property.id,
                            date: date,
                            allBookings: allBookings
                        )
                        .id("\(property.id)-\(date.timeIntervalSince1970)") // Unique ID per property+date
                        .offset(x: CGFloat(index) * cellWidth + cellWidth / 2 - 4) // Center in day cell
                    }
                }
            }
        }
        .frame(height: 14) // Ultra-thin bars to fit more properties
    }
}

struct ContinuousBookingBar: View {
    let booking: Booking
    let property: Property
    let week: [Date?]
    let cellWidth: CGFloat
    let allBookings: [Booking]
    let currentMonth: Date
    
    var body: some View {
        let barGeometry = calculateBarGeometry()
        
        if barGeometry.width > 0 {
            HStack(spacing: 0) {
                // Render bar as segments, one per day (for color variation)
                ForEach(Array(barGeometry.segments.enumerated()), id: \.offset) { index, segment in
                    Rectangle()
                        .fill(segment.isInCurrentMonth ? property.color : Color.gray.opacity(0.4))
                        .frame(width: segment.width)
                }
            }
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: barGeometry.roundedStart ? 8 : 0,
                    bottomLeadingRadius: barGeometry.roundedStart ? 8 : 0,
                    bottomTrailingRadius: barGeometry.roundedEnd ? 8 : 0,
                    topTrailingRadius: barGeometry.roundedEnd ? 8 : 0
                )
            )
            .overlay(
                UnevenRoundedRectangle(
                    topLeadingRadius: barGeometry.roundedStart ? 8 : 0,
                    bottomLeadingRadius: barGeometry.roundedStart ? 8 : 0,
                    bottomTrailingRadius: barGeometry.roundedEnd ? 8 : 0,
                    topTrailingRadius: barGeometry.roundedEnd ? 8 : 0
                )
                .stroke(Color.black, lineWidth: 1.5)
            )
            .overlay(
                // Property label on the right end
                HStack(spacing: 2) {
                    Spacer()
                    
                    Text(property.shortName)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(textColor(for: property.color))
                }
                .padding(.trailing, 6)
            )
            .offset(x: barGeometry.offset)
        }
    }
    
    private func textColor(for backgroundColor: Color) -> Color {
        // Use white text for dark backgrounds (like blue), black for light backgrounds
        // Check if color is dark by comparing to a threshold
        // For simplicity, use white for blue and black for orange/yellow
        let colorHex = property.colorHex
        
        // Blue color (007AFF) should use white text
        if colorHex.uppercased().contains("007AFF") || colorHex.uppercased().contains("0000FF") {
            return .white
        }
        
        // Default to black for lighter colors (orange, yellow)
        return .black
    }
    
    private func calculateBarGeometry() -> (offset: CGFloat, width: CGFloat, roundedStart: Bool, roundedEnd: Bool, segments: [(width: CGFloat, isInCurrentMonth: Bool)]) {
        let calendar = Calendar.current
        var startIndex: Int?
        var endIndex: Int?
        var startOffset: CGFloat = 0
        var endOffset: CGFloat = 0
        var isActualStart = false
        var isActualEnd = false
        var segments: [(width: CGFloat, isInCurrentMonth: Bool)] = []
        
        // Find which days in this week the booking spans
        for (index, date) in week.enumerated() {
            guard let date = date else { continue }
            let dayStart = calendar.startOfDay(for: date)
            let bookingStart = calendar.startOfDay(for: booking.startDate)
            let bookingEnd = calendar.startOfDay(for: booking.endDate)
            
            // Include the checkout day in the range
            if dayStart >= bookingStart && dayStart <= bookingEnd {
                if startIndex == nil {
                    startIndex = index
                    // Check if this is the check-in day
                    if calendar.isDate(booking.startDate, inSameDayAs: date) {
                        isActualStart = true
                        startOffset = 0.67 // Start at 4PM (16/24 ≈ 0.67)
                    } else {
                        isActualStart = false
                        startOffset = 0 // Continues from previous week
                    }
                }
                
                endIndex = index
            }
        }
        
        // After finding the range, determine if this is the actual end or continues
        if let end = endIndex, let endDate = week[end] {
            // Check if this is the checkout day
            if calendar.isDate(booking.endDate, inSameDayAs: endDate) {
                isActualEnd = true
                endOffset = 0.42 // End at 10AM (10/24 ≈ 0.42)
            } else {
                // Booking continues beyond this week - square edge
                isActualEnd = false
                endOffset = 1.0 // Continues to next week
            }
        }
        
        guard let start = startIndex, let end = endIndex else {
            return (0, 0, false, false, [])
        }
        
        // Build segments for each day
        for dayIndex in start...end {
            guard let date = week[dayIndex] else { continue }
            
            let isInMonth = calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
            let isFirstDay = dayIndex == start
            let isLastDay = dayIndex == end
            
            var segmentWidth: CGFloat
            if isFirstDay && isLastDay {
                // Single day booking
                segmentWidth = (endOffset - startOffset) * cellWidth
            } else if isFirstDay {
                // First day
                segmentWidth = (1.0 - startOffset) * cellWidth
            } else if isLastDay {
                // Last day
                segmentWidth = endOffset * cellWidth
            } else {
                // Middle day
                segmentWidth = cellWidth
            }
            
            segments.append((width: segmentWidth, isInCurrentMonth: isInMonth))
        }
        
        let offset = (CGFloat(start) + startOffset) * cellWidth
        let totalWidth = segments.reduce(0) { $0 + $1.width }
        
        return (offset, totalWidth, isActualStart, isActualEnd, segments)
    }
    
    private func getCheckoutDate() -> Date? {
        // Return the checkout date (end date) of this booking
        return booking.endDate
    }
}

// Add this struct for item-based sheet presentation
struct DayDetailItem: Identifiable {
    let id = UUID()
    let date: Date
    let activities: [PropertyActivity]
}



