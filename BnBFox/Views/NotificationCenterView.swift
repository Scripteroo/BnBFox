//
//  NotificationCenterView.swift
//  BnBFox
//
//  Updated to show ALL events today (checkout, checkin, or both) with appropriate icons
//

import SwiftUI

struct NotificationCenterView: View {
    @ObservedObject var statusManager = CleaningStatusManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var upcomingToday: [UpcomingEvent] = []
    @State private var currentTime = Date()
    
    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    var onNotificationTap: (Date) -> Void
    
    var body: some View {
        let _ = BadgeManager.shared.clearBadge()  // Clear badge when opening
            List {
                // COMING UP TODAY Section
                if !upcomingToday.isEmpty {
                    Section(header: Text("Coming up today...").font(.subheadline).foregroundColor(.secondary)) {
                        ForEach(upcomingToday) { event in
                            UpcomingEventRow(event: event, currentTime: currentTime)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    onNotificationTap(event.eventDate)
                                    dismiss()
                                }
                        }
                    }
                }
                
                // PENDING TASKS Section
                Section(header: Text("Pending Tasks").font(.subheadline).foregroundColor(.secondary)) {
                    let pendingStatuses = statusManager.getPendingStatuses()
                    
                    if pendingStatuses.isEmpty && upcomingToday.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 60))
                                .foregroundColor(.green)
                            Text("All caught up!")
                                .font(.headline)
                            Text("No pending cleaning tasks")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .listRowBackground(Color.clear)
                    } else if pendingStatuses.isEmpty {
                        Text("No pending tasks")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 20)
                    } else {
                        ForEach(pendingStatuses) { status in
                            NotificationRow(status: status)
                        }
                    }
                }
                
                // UPCOMING CLEANINGS Section (Next 30 Days)
                Section(header: Text("Upcoming Cleanings (Next 30 Days)").font(.subheadline).foregroundColor(.secondary)) {
                    let upcomingCleanings = getUpcomingCleanings()
                    
                    if upcomingCleanings.isEmpty {
                        Text("No upcoming cleanings")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 20)
                    } else {
                        ForEach(upcomingCleanings) { cleaning in
                            UpcomingCleaningListRow(cleaning: cleaning)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    onNotificationTap(cleaning.checkoutDate)
                                    dismiss()
                                }
                        }
                    }
                }
            }
            .navigationTitle("Cleaning Tasks")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                Task {
                    // Auto-create cleaning tasks for checkouts that have occurred
                    await CleaningStatusManager.shared.autoCreateCleaningTasks()
                    // Load upcoming events
                    loadUpcomingToday()
                }
            }
            .onReceive(timer) { _ in
                currentTime = Date()
            }
    }
    
    private func loadUpcomingToday() {
        Task {
            let bookings = await PropertyService.shared.getAllBookings()
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let now = Date()
            
            var todayEvents: [UpcomingEvent] = []
            
            // Group bookings by property
            var eventsByProperty: [UUID: PropertyEvents] = [:]
            
            for booking in bookings {
                let checkoutDate = calendar.startOfDay(for: booking.endDate)
                let checkinDate = calendar.startOfDay(for: booking.startDate)
                
                // Check if checkout is today
                let hasCheckoutToday = calendar.isDate(checkoutDate, inSameDayAs: today)
                
                // Check if checkin is today
                let hasCheckinToday = calendar.isDate(checkinDate, inSameDayAs: today)
                
                if hasCheckoutToday || hasCheckinToday {
                    if eventsByProperty[booking.propertyId] == nil {
                        eventsByProperty[booking.propertyId] = PropertyEvents(
                            propertyId: booking.propertyId,
                            hasCheckout: false,
                            hasCheckin: false
                        )
                    }
                    
                    if hasCheckoutToday {
                        eventsByProperty[booking.propertyId]?.hasCheckout = true
                    }
                    if hasCheckinToday {
                        eventsByProperty[booking.propertyId]?.hasCheckin = true
                    }
                }
            }
            
            // Create UpcomingEvent objects
            for (propertyId, events) in eventsByProperty {
                guard let property = PropertyService.shared.getProperty(by: propertyId) else { continue }
                
                // Determine event type
                let eventType: EventType
                if events.hasCheckout && events.hasCheckin {
                    eventType = .checkoutAndCheckin
                } else if events.hasCheckout {
                    eventType = .checkoutOnly
                } else {
                    eventType = .checkinOnly
                }
                
                // For countdown, use checkout time if there's a checkout, otherwise checkin time
                var eventTime = calendar.dateComponents([.year, .month, .day], from: today)
                if events.hasCheckout {
                    eventTime.hour = 10  // Checkout at 10 AM
                } else {
                    eventTime.hour = 15  // Checkin at 3 PM
                }
                eventTime.minute = 0
                
                guard let eventDateTime = calendar.date(from: eventTime) else { continue }
                
                // Only show if event hasn't happened yet
                if eventDateTime > now {
                    let event = UpcomingEvent(
                        id: UUID(),
                        propertyName: property.displayName,
                        propertyShortName: property.shortName,
                        eventDate: eventDateTime,
                        eventType: eventType
                    )
                    
                    todayEvents.append(event)
                }
            }
            
            await MainActor.run {
                upcomingToday = todayEvents.sorted { $0.eventDate < $1.eventDate }
            }
        }
    }
    
    private func getUpcomingCleanings() -> [UpcomingCleaning] {
        let bookings = PropertyService.shared.getAllBookingsSync()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let thirtyDaysFromNow = calendar.date(byAdding: .day, value: 30, to: today) ?? today
        
        var cleanings: [UpcomingCleaning] = []
        var checkoutsByProperty: [UUID: [Date: [Booking]]] = [:]
        
        for booking in bookings {
            let checkoutDate = calendar.startOfDay(for: booking.endDate)
            
            // Only include future dates (not today, that's in "Coming up today")
            guard checkoutDate > today && checkoutDate <= thirtyDaysFromNow else { continue }
            
            if checkoutsByProperty[booking.propertyId] == nil {
                checkoutsByProperty[booking.propertyId] = [:]
            }
            if checkoutsByProperty[booking.propertyId]![checkoutDate] == nil {
                checkoutsByProperty[booking.propertyId]![checkoutDate] = []
            }
            checkoutsByProperty[booking.propertyId]![checkoutDate]!.append(booking)
        }
        
        for (propertyId, dateBookings) in checkoutsByProperty {
            guard let property = PropertyService.shared.getProperty(by: propertyId) else { continue }
            
            for (checkoutDate, _) in dateBookings {
                let hasCheckin = bookings.contains { booking in
                    booking.propertyId == propertyId &&
                    calendar.isDate(booking.startDate, inSameDayAs: checkoutDate)
                }
                
                let cleaning = UpcomingCleaning(
                    id: UUID(),
                    propertyName: property.displayName,
                    propertyShortName: property.shortName,
                    checkoutDate: checkoutDate,
                    isSameDayTurnover: hasCheckin
                )
                
                cleanings.append(cleaning)
            }
        }
        
        return cleanings.sorted { $0.checkoutDate < $1.checkoutDate }
    }
}

// Helper struct to track property events
struct PropertyEvents {
    let propertyId: UUID
    var hasCheckout: Bool
    var hasCheckin: Bool
}

// Event type enum
enum EventType {
    case checkoutOnly
    case checkinOnly
    case checkoutAndCheckin
    
    var iconName: String {
        switch self {
        case .checkoutOnly:
            return "checkout"
        case .checkinOnly:
            return "checkin"
        case .checkoutAndCheckin:
            return "checkout-checkin"
        }
    }
    
    var displayText: String {
        switch self {
        case .checkoutOnly:
            return "Check-out"
        case .checkinOnly:
            return "Check-in"
        case .checkoutAndCheckin:
            return "Check-out\n& Check-in"
        }
    }
    
    var isUrgent: Bool {
        return self == .checkoutAndCheckin
    }
}

// Model for upcoming events
struct UpcomingEvent: Identifiable {
    let id: UUID
    let propertyName: String
    let propertyShortName: String
    let eventDate: Date
    let eventType: EventType
}

// Model for upcoming cleanings
struct UpcomingCleaning: Identifiable {
    let id: UUID
    let propertyName: String
    let propertyShortName: String
    let checkoutDate: Date
    let isSameDayTurnover: Bool
}

// Row for "Coming up today" section with countdown
struct UpcomingEventRow: View {
    let event: UpcomingEvent
    let currentTime: Date
    
    var body: some View {
        HStack(spacing: 12) {
            // Property name
            VStack(alignment: .leading, spacing: 4) {
                Text(event.propertyShortName)
                    .font(.title2)
                    .fontWeight(.bold)
                
                HStack(spacing: 8) {
                    // Event icon
                    Image(event.eventType.iconName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                    
                    // Event text
                    Text(event.eventType.displayText)
                        .font(.caption)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            // Countdown timer
            VStack(alignment: .trailing, spacing: 4) {
                Text(timeUntilEvent)
                    .font(.headline)
                    .foregroundColor(event.eventType.isUrgent ? .red : .orange)
                Text(countdownLabel)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
    
    private var timeUntilEvent: String {
        let timeInterval = event.eventDate.timeIntervalSince(currentTime)
        
        if timeInterval <= 0 {
            return "Now"
        }
        
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private var countdownLabel: String {
        switch event.eventType {
        case .checkoutOnly:
            return "until checkout"
        case .checkinOnly:
            return "until checkin"
        case .checkoutAndCheckin:
            return "until checkout"
        }
    }
}

// Row for "Upcoming Cleanings" list
struct UpcomingCleaningListRow: View {
    let cleaning: UpcomingCleaning
    
    var body: some View {
        HStack(spacing: 12) {
            // Warning icon for same-day turnovers
            if cleaning.isSameDayTurnover {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                    .font(.title3)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(cleaning.propertyShortName)
                    .font(.headline)
                
                HStack(spacing: 8) {
                    Text(formattedDate)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if cleaning.isSameDayTurnover {
                        Text("SAME-DAY TURNOVER")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    }
                }
            }
            
            Spacer()
            
            Text(relativeDays)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: cleaning.checkoutDate)
    }
    
    private var relativeDays: String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let days = calendar.dateComponents([.day], from: today, to: cleaning.checkoutDate).day ?? 0
        
        if days == 0 {
            return "Today"
        } else if days == 1 {
            return "Tomorrow"
        } else {
            return "\(days) days"
        }
    }
}

struct NotificationRow: View {
    let status: CleaningStatus
    @ObservedObject var statusManager = CleaningStatusManager.shared
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastIcon = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Property name and checkout/checkin status
            HStack {
                Circle()
                    .fill(.yellow)
                    .frame(width: 12, height: 12)
                Text(status.propertyName)
                    .font(.headline)
                
                Spacer()
                
                // Show simple "Check-out" label - we know it's a checkout because there's a cleaning task
                HStack(spacing: 4) {
                    Text("Check-out")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Image("checkout")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }
            }
            
            Divider()
            
            // Cleaning Status Buttons
            Text("Cleaning Status")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 0) {
                Spacer()
                CleaningStatusButton(
                    imageName: "red-cleaning-button",
                    label: "Dirty",
                    sublabel: "Sucio",
                    isSelected: status.status == .todo,
                    action: {
                        statusManager.setStatus(propertyName: status.propertyName, date: status.date, bookingId: status.bookingId, status: .todo)
                    }
                )
                
                Spacer()
                
                CleaningStatusButton(
                    imageName: "amber-cleaning-button",
                    label: "Cleaning",
                    sublabel: "Limpiando",
                    isSelected: status.status == .inProgress,
                    action: {
                        print("🔘 BUTTON TAPPED - Yellow/Cleaning")
                        statusManager.setStatus(propertyName: status.propertyName, date: status.date, bookingId: status.bookingId, status: .inProgress)
                        print("🔘 After setStatus call")
                        toastMessage = "I'm on my way"
                        toastIcon = "🚗"
                        showToast = true
                        print("🔘 Toast shown")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showToast = false
                        }
                    }
                )
                
                Spacer()
                
                CleaningStatusButton(
                    imageName: "green-cleaning-button",
                    label: "Clean",
                    sublabel: "Limpio",
                    isSelected: status.status == .done,
                    action: {
                        statusManager.setStatus(propertyName: status.propertyName, date: status.date, bookingId: status.bookingId, status: .done)
                        toastMessage = "Clean and Ready!"
                        toastIcon = "✨"
                        showToast = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showToast = false
                        }
                    }
                )
                
                Spacer()
            }
        }
        .padding(.vertical, 8)
        .overlay(
            Group {
                if showToast {
                    VStack {
                        Spacer()
                        HStack {
                            Text(toastIcon)
                            Text(toastMessage)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(20)
                        .padding(.bottom, 20)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(), value: showToast)
                }
            }
        )
    }
}

struct CleaningStatusButton: View {
    let imageName: String
    let label: String
    let sublabel: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .opacity(isSelected ? 1.0 : 0.5)
                
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
                Text(sublabel)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Extension to PropertyService for synchronous access
extension PropertyService {
    func getAllBookingsSync() -> [Booking] {
        var allBookings: [Booking] = []
        let properties = getAllProperties()
        
        for property in properties {
            // Fetch bookings synchronously using the existing cache
            let bookings = BookingService.shared.getCachedBookings(for: property)
            allBookings.append(contentsOf: bookings)
        }
        
        return allBookings
    }
}


