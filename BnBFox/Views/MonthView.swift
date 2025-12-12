import SwiftUI

struct MonthView: View {
    let month: Date
    let bookings: [Booking]
    let properties: [Property]
    
    var body: some View {
        VStack(spacing: 0) {
            // Month title
            Text(month.formatted(.dateTime.month(.wide).year()))
                .font(.title2)
                .fontWeight(.bold)
                .padding(.vertical, 8)
            
            // Day of week headers
            HStack(spacing: 0) {
                ForEach(Array(["S", "M", "T", "W", "T", "F", "S"].enumerated()), id: \.offset) { index, day in
                    Text(day)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 2)
            .padding(.bottom, 4)
            
            // Weeks
            let weeks = generateWeeks(for: month)
            ForEach(Array(weeks.enumerated()), id: \.offset) { index, week in
                WeekSection(
                    week: week,
                    bookings: bookings,
                    currentMonth: month,
                    properties: properties
                )
            }
        }
    }
    
    private func generateWeeks(for month: Date) -> [[Date?]] {
        let calendar = Calendar.current
        
        // Get the first day of the month
        guard let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) else {
            return []
        }
        
        // Get the weekday of the first day (0 = Sunday, 6 = Saturday)
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth) - 1
        
        // Get the number of days in the month
        let range = calendar.range(of: .day, in: .month, for: month)!
        let numDays = range.count
        
        // Calculate days from previous month to fill first week
        var dates: [Date?] = []
        
        // Add dates from previous month
        if firstWeekday > 0 {
            if let prevMonthDate = calendar.date(byAdding: .month, value: -1, to: firstDayOfMonth),
               let prevMonthDays = calendar.range(of: .day, in: .month, for: prevMonthDate) {
                let prevMonthLastDay = prevMonthDays.count
                for day in (prevMonthLastDay - firstWeekday + 1)...prevMonthLastDay {
                    if let date = calendar.date(from: DateComponents(
                        year: calendar.component(.year, from: prevMonthDate),
                        month: calendar.component(.month, from: prevMonthDate),
                        day: day
                    )) {
                        dates.append(date)
                    }
                }
            }
        }
        
        // Add dates from current month
        for day in 1...numDays {
            if let date = calendar.date(from: DateComponents(
                year: calendar.component(.year, from: month),
                month: calendar.component(.month, from: month),
                day: day
            )) {
                dates.append(date)
            }
        }
        
        // Add dates from next month to complete the last week
        let remainingDays = (7 - (dates.count % 7)) % 7
        if remainingDays > 0 {
            if let nextMonthDate = calendar.date(byAdding: .month, value: 1, to: firstDayOfMonth) {
                for day in 1...remainingDays {
                    if let date = calendar.date(from: DateComponents(
                        year: calendar.component(.year, from: nextMonthDate),
                        month: calendar.component(.month, from: nextMonthDate),
                        day: day
                    )) {
                        dates.append(date)
                    }
                }
            }
        }
        
        // Split into weeks
        var weeks: [[Date?]] = []
        for i in stride(from: 0, to: dates.count, by: 7) {
            let week = Array(dates[i..<min(i + 7, dates.count)])
            weeks.append(week)
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
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Background grid
            HStack(spacing: 0) {
                ForEach(Array(week.enumerated()), id: \.offset) { index, date in
                    VStack(spacing: 0) {
                        if let date = date {
                            let hasActivity = dateHasActivity(date)
                            
                            ZStack {
                                Text("\(Calendar.current.component(.day, from: date))")
                                    .font(.system(size: 16))
                                    .foregroundColor(date.isToday() ? .white : (isInCurrentMonth(date) ? .primary : .gray.opacity(0.5)))
                                    .frame(width: 32, height: 32)
                                    .background(
                                        Circle()
                                            .fill(date.isToday() ? Color.blue : Color.clear)
                                    )
                                    .contentShape(Circle())
                                    .onTapGesture {
                                        if hasActivity {
                                            let activities = getActivitiesForDate(date)
                                            if !activities.isEmpty {
                                                dayDetailItem = DayDetailItem(date: date, activities: activities)
                                            }
                                        }
                                    }
                                
                                // Activity indicator dot
                                if hasActivity {
                                    Circle()
                                        .fill(Color.blue)
                                        .frame(width: 4, height: 4)
                                        .offset(y: 14)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 100)
                    .background(isInCurrentMonth(date) ? Color.white : Color.gray.opacity(0.05))
                    .overlay(
                        Rectangle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                    )
                }
            }
            
            // Booking bars for each property
            VStack(spacing: 2) {
                Spacer()
                    .frame(height: 38)
                
                ForEach(properties) { property in
                    PropertyRow(
                        week: week,
                        property: property,
                        bookings: getBookingsForProperty(property),
                        currentMonth: currentMonth
                    )
                }
                
                Spacer()
                    .frame(minHeight: 0)
            }
            .padding(.top, 0)
            .frame(height: 100)
            .allowsHitTesting(false)
            .padding(.horizontal, 2)
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
                    checkin = BookingInfo(guestName: booking.guestName, booking: booking)
                }
                
                // Check-out on this date
                if calendar.isDate(bookingEnd, inSameDayAs: dayStart) {
                    checkout = BookingInfo(guestName: booking.guestName, booking: booking)
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
        
        // Sort by property name
        return activities.sorted { $0.property.displayName < $1.property.displayName }
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

struct PropertyRow: View {
    let week: [Date?]
    let property: Property
    let bookings: [Booking]
    let currentMonth: Date
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Render booking bars
            ForEach(bookings) { booking in
                ContinuousBookingBar(
                    booking: booking,
                    property: property,
                    week: week,
                    currentMonth: currentMonth
                )
            }
        }
        .frame(height: 16)
    }
}

struct ContinuousBookingBar: View {
    let booking: Booking
    let property: Property
    let week: [Date?]
    let currentMonth: Date
    
    var body: some View {
        GeometryReader { geometry in
            let barGeometry = calculateBarGeometry(geometry: geometry)
            
            if barGeometry.width > 0 {
                HStack(spacing: 0) {
                    ForEach(Array(barGeometry.segments.enumerated()), id: \.offset) { index, segment in
                        Rectangle()
                            .fill(segment.isInCurrentMonth ? property.color : Color.gray.opacity(0.4))
                            .frame(width: segment.width)
                    }
                }
                .frame(width: barGeometry.width, height: 16)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.black, lineWidth: 1.5)
                        .mask(
                            HStack(spacing: 0) {
                                if barGeometry.isActualStart {
                                    RoundedRectangle(cornerRadius: 8)
                                        .frame(width: 10)
                                } else {
                                    Rectangle()
                                        .frame(width: 10)
                                }
                                
                                Rectangle()
                                
                                if barGeometry.isActualEnd {
                                    RoundedRectangle(cornerRadius: 8)
                                        .frame(width: 10)
                                } else {
                                    Rectangle()
                                        .frame(width: 10)
                                }
                            }
                        )
                )
                .clipShape(
                    RoundedCornerRectangle(
                        cornerRadius: 8,
                        corners: [
                            barGeometry.isActualStart ? .topLeft : [],
                            barGeometry.isActualStart ? .bottomLeft : [],
                            barGeometry.isActualEnd ? .topRight : [],
                            barGeometry.isActualEnd ? .bottomRight : []
                        ].reduce(into: UIRectCorner()) { $0.formUnion($1) }
                    )
                )
                .offset(x: barGeometry.startX)
                .overlay(
                    Text(property.shortName)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.trailing, 4)
                        .frame(maxWidth: .infinity, alignment: .trailing),
                    alignment: .trailing
                )
            }
        }
    }
    
    private func calculateBarGeometry(geometry: GeometryProxy) -> BarGeometry {
        let calendar = Calendar.current
        let cellWidth = geometry.size.width / 7
        
        guard let firstDayInWeek = week.compactMap({ $0 }).first,
              let lastDayInWeek = week.compactMap({ $0 }).last else {
            return BarGeometry(startX: 0, width: 0, isActualStart: false, isActualEnd: false, segments: [])
        }
        
        let bookingStart = calendar.startOfDay(for: booking.startDate)
        let bookingEnd = calendar.startOfDay(for: booking.endDate)
        let weekStart = calendar.startOfDay(for: firstDayInWeek)
        let weekEnd = calendar.startOfDay(for: lastDayInWeek)
        
        // Determine if this is the actual start/end of the booking
        let isActualStart = calendar.isDate(bookingStart, inSameDayAs: firstDayInWeek) || bookingStart > weekStart
        let isActualEnd = calendar.isDate(bookingEnd, inSameDayAs: lastDayInWeek) || bookingEnd <= weekEnd
        
        var segments: [BarSegment] = []
        var startX: CGFloat = 0
        var totalWidth: CGFloat = 0
        var foundStart = false
        
        for (dayIndex, dateOpt) in week.enumerated() {
            guard let date = dateOpt else { continue }
            let dayStart = calendar.startOfDay(for: date)
            
            // Check if this day overlaps with the booking
            if dayStart >= bookingStart && dayStart < bookingEnd {
                if !foundStart {
                    foundStart = true
                    
                    // Calculate start offset for check-in time (4PM = 0.67 of day)
                    var startOffset: CGFloat = 0
                    if calendar.isDate(dayStart, inSameDayAs: bookingStart) {
                        startOffset = cellWidth * 0.67
                    }
                    
                    startX = CGFloat(dayIndex) * cellWidth + startOffset
                }
                
                // Calculate width for this day
                var dayWidth = cellWidth
                
                // Adjust for check-in day (starts at 4PM)
                if calendar.isDate(dayStart, inSameDayAs: bookingStart) {
                    dayWidth = cellWidth * 0.33
                }
                
                // Check if this is the last day (checkout day)
                let nextDay = calendar.date(byAdding: .day, value: 1, to: dayStart)!
                if calendar.isDate(nextDay, inSameDayAs: bookingEnd) || nextDay >= bookingEnd {
                    // This is the last occupied night, extend into checkout day
                    dayWidth = cellWidth * 1.42  // Full day + 42% of next day (10AM)
                }
                
                // Determine if this segment is in current month
                let isInMonth = calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
                
                segments.append(BarSegment(width: dayWidth, isInCurrentMonth: isInMonth))
                totalWidth += dayWidth
            }
        }
        
        return BarGeometry(
            startX: startX,
            width: totalWidth,
            isActualStart: isActualStart,
            isActualEnd: isActualEnd,
            segments: segments
        )
    }
}

struct BarGeometry {
    let startX: CGFloat
    let width: CGFloat
    let isActualStart: Bool
    let isActualEnd: Bool
    let segments: [BarSegment]
}

struct BarSegment {
    let width: CGFloat
    let isInCurrentMonth: Bool
}

struct RoundedCornerRectangle: Shape {
    var cornerRadius: CGFloat
    var corners: UIRectCorner
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)
        )
        return Path(path.cgPath)
    }
}

// Add this struct for item-based sheet presentation
struct DayDetailItem: Identifiable {
    let id = UUID()
    let date: Date
    let activities: [PropertyActivity]
}
