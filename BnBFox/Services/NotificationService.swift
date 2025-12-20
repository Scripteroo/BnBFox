//
//  NotificationService.swift
//  BnBFox
//
//  Created on 12/12/2025.
//

import Foundation
import UserNotifications

class NotificationService {
    static let shared = NotificationService()
    
    private init() {}
    
    // Request notification permissions
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            return granted
        } catch {
            print("Error requesting notification authorization: \(error)")
            return false
        }
    }
    
    // Schedule cleaning alerts for all upcoming checkouts
    func scheduleCleaningAlerts() {
        Task {
            // First, ensure we have permission
            let authorized = await requestAuthorization()
            guard authorized else {
                print("Notification permission denied")
                return
            }
            
            // Cancel existing alerts before scheduling new ones
            cancelAllCleaningAlerts()
            
            // Get all bookings
            let bookings = await PropertyService.shared.getAllBookings()
            
            // Get alert time from settings
            let settings = AppSettings.shared
            guard settings.cleaningAlertsEnabled else { return }
            
            let calendar = Calendar.current
            let alertComponents = calendar.dateComponents([.hour, .minute], from: settings.alertTime)
            let alertHour = alertComponents.hour ?? 8
            let alertMinute = alertComponents.minute ?? 0
            
            // Group bookings by property and date
            var cleaningDays: [UUID: [Date: [Booking]]] = [:]
            
            for booking in bookings {
                let propertyId = booking.propertyId
                let checkoutDate = calendar.startOfDay(for: booking.endDate)
                
                if cleaningDays[propertyId] == nil {
                    cleaningDays[propertyId] = [:]
                }
                if cleaningDays[propertyId]![checkoutDate] == nil {
                    cleaningDays[propertyId]![checkoutDate] = []
                }
                cleaningDays[propertyId]![checkoutDate]!.append(booking)
            }
            
            // Schedule notifications for each cleaning day
            for (propertyId, dateBookings) in cleaningDays {
                guard let property = PropertyService.shared.getProperty(by: propertyId) else {
                    continue
                }
                
                for (checkoutDate, _) in dateBookings {
                    // Only schedule for future dates
                    guard checkoutDate >= calendar.startOfDay(for: Date()) else { continue }
                    
                    // Check if there's a same-day turnover (checkout and checkin on same day)
                    let hasCheckin = bookings.contains { booking in
                        booking.propertyId == propertyId &&
                        calendar.isDate(booking.startDate, inSameDayAs: checkoutDate)
                    }
                    
                    let isUrgent = hasCheckin
                    
                    // Create notification content
                    let content = UNMutableNotificationContent()
                    
                    if isUrgent {
                        content.title = "🚨 URGENT: Same-Day Turnover"
                        content.body = "\(property.shortName) needs cleaning TODAY - checkout AND checkin scheduled!"
                    } else {
                        content.title = "🧹 Cleaning Day"
                        content.body = "\(property.shortName) checkout today - ready for cleaning"
                    }
                    
                    content.categoryIdentifier = "CLEANING_ALERT"
                    
                    if settings.alertSoundEnabled {
                        content.sound = .default
                    }
                    
                    // Set badge number
                    content.badge = 1
                    
                    // Schedule for alert time on checkout date
                    var notificationDate = calendar.dateComponents([.year, .month, .day], from: checkoutDate)
                    notificationDate.hour = alertHour
                    notificationDate.minute = alertMinute
                    
                    let trigger = UNCalendarNotificationTrigger(dateMatching: notificationDate, repeats: false)
                    
                    // Create unique identifier
                    let identifier = "cleaning_\(propertyId)_\(checkoutDate.timeIntervalSince1970)"
                    
                    let request = UNNotificationRequest(
                        identifier: identifier,
                        content: content,
                        trigger: trigger
                    )
                    
                    // Schedule the notification
                    do {
                        try await UNUserNotificationCenter.current().add(request)
                        // Scheduled cleaning alert for \(property.shortName) on \(checkoutDate)
                    } catch {
                        print("Error scheduling notification: \(error)")
                    }
                }
            }
            
            // NEW: Schedule daily reminders for properties in cleaning gaps
            await scheduleDailyCleaningReminders(bookings: bookings, alertHour: alertHour, alertMinute: alertMinute)
        }
    }
    
    // Schedule daily notifications for each day a property needs cleaning
    private func scheduleDailyCleaningReminders(bookings: [Booking], alertHour: Int, alertMinute: Int) async {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let settings = AppSettings.shared
        
        // Get all properties
        let allProperties = PropertyService.shared.getAllProperties()
        
        // For each property, find cleaning gaps and schedule daily notifications
        for property in allProperties {
            let propertyBookings = bookings.filter { $0.propertyId == property.id }.sorted { $0.endDate < $1.endDate }
            
            // Find all cleaning gaps for this property
            for i in 0..<propertyBookings.count {
                let checkoutDate = calendar.startOfDay(for: propertyBookings[i].endDate)
                
                // Find next checkin after this checkout
                var nextCheckin: Date?
                for j in 0..<propertyBookings.count {
                    let checkinDate = calendar.startOfDay(for: propertyBookings[j].startDate)
                    if checkinDate > checkoutDate {
                        if nextCheckin == nil || checkinDate < nextCheckin! {
                            nextCheckin = checkinDate
                        }
                    }
                }
                
                guard let checkin = nextCheckin else { continue }
                
                // Schedule notification for each day in the gap (checkout through checkin)
                var currentDate = checkoutDate
                while currentDate <= checkin {
                    // Only schedule for future dates
                    if currentDate >= today {
                        // Check if there's a same-day turnover
                        let hasCheckin = calendar.isDate(checkin, inSameDayAs: currentDate)
                        
                        // Create notification content
                        let content = UNMutableNotificationContent()
                        
                        if hasCheckin {
                            content.title = "🚨 URGENT: Checkin Today"
                            content.body = "\(property.shortName) must be cleaned by 4:00 PM - guests checking in today!"
                        } else {
                            let daysUntilCheckin = calendar.dateComponents([.day], from: currentDate, to: checkin).day ?? 0
                            if daysUntilCheckin == 0 {
                                content.title = "🧹 Cleaning Reminder"
                                content.body = "\(property.shortName) needs cleaning today"
                            } else if daysUntilCheckin == 1 {
                                content.title = "🧹 Cleaning Reminder"
                                content.body = "\(property.shortName) needs cleaning - checkin tomorrow!"
                            } else {
                                content.title = "🧹 Cleaning Reminder"
                                content.body = "\(property.shortName) needs cleaning - checkin in \(daysUntilCheckin) days"
                            }
                        }
                        
                        content.categoryIdentifier = "CLEANING_REMINDER"
                        
                        if settings.alertSoundEnabled {
                            content.sound = .default
                        }
                        
                        content.badge = 1
                        
                        // Schedule for alert time on this date
                        var notificationDate = calendar.dateComponents([.year, .month, .day], from: currentDate)
                        notificationDate.hour = alertHour
                        notificationDate.minute = alertMinute
                        
                        let trigger = UNCalendarNotificationTrigger(dateMatching: notificationDate, repeats: false)
                        
                        // Create unique identifier
                        let identifier = "cleaning_daily_\(property.id)_\(currentDate.timeIntervalSince1970)"
                        
                        let request = UNNotificationRequest(
                            identifier: identifier,
                            content: content,
                            trigger: trigger
                        )
                        
                        // Schedule the notification
                        do {
                            try await UNUserNotificationCenter.current().add(request)
                            // Scheduled daily cleaning reminder for \(property.shortName) on \(currentDate)
                        } catch {
                            print("Error scheduling daily reminder: \(error)")
                        }
                    }
                    
                    // Move to next day
                    currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
                }
            }
        }
    }
    
    // Cancel all cleaning alerts (including daily reminders)
    func cancelAllCleaningAlerts() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let cleaningIdentifiers = requests
                .filter { $0.identifier.starts(with: "cleaning_") || $0.identifier.starts(with: "cleaning_daily_") }
                .map { $0.identifier }
            
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: cleaningIdentifiers)
            // Cancelled \(cleaningIdentifiers.count) cleaning alerts and reminders
        }
    }
    
    // Get count of pending alerts (for display in settings)
    func getPendingAlertsCount() async -> Int {
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        return requests.filter { $0.identifier.starts(with: "cleaning_") || $0.identifier.starts(with: "cleaning_daily_") }.count
    }
    
    // MARK: - New Booking Alerts
    
    // Store previous bookings to detect new ones
    private var previousBookingIds: Set<String> = []
    
    // Check for new bookings and send notifications
    func checkForNewBookings(_ currentBookings: [Booking]) {
        guard AppSettings.shared.newBookingAlertsEnabled else { return }
        
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: Date())
        let currentYear = calendar.component(.year, from: Date())
        
        // Get current booking IDs
        let currentBookingIds = Set(currentBookings.map { $0.id })
        
        // Find new bookings (in current IDs but not in previous)
        let newBookingIds = currentBookingIds.subtracting(previousBookingIds)
        
        // Only alert for bookings in current month
        for bookingId in newBookingIds {
            guard let booking = currentBookings.first(where: { $0.id == bookingId }) else { continue }
            
            // Check if booking is in current month
            let bookingMonth = calendar.component(.month, from: booking.startDate)
            let bookingYear = calendar.component(.year, from: booking.startDate)
            
            if bookingMonth == currentMonth && bookingYear == currentYear {
                // Get property name
                guard let property = PropertyService.shared.getProperty(by: booking.propertyId) else { continue }
                
                // Send notification immediately
                sendNewBookingNotification(propertyName: property.displayName, booking: booking)
            }
        }
        
        // Update stored booking IDs
        previousBookingIds = currentBookingIds
    }
    
    private func sendNewBookingNotification(propertyName: String, booking: Booking) {
        let content = UNMutableNotificationContent()
        content.title = "📅 New Booking"
        content.body = "New booking in \(propertyName)"
        
        // Add sound if enabled
        if AppSettings.shared.alertSoundEnabled {
            content.sound = .default
        }
        
        // Format dates for subtitle
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let startDate = dateFormatter.string(from: booking.startDate)
        let endDate = dateFormatter.string(from: booking.endDate)
        content.subtitle = "\(startDate) - \(endDate)"
        
        // Create trigger to fire immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        // Create request
        let identifier = "new_booking_\(booking.id)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Schedule notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling new booking notification: \(error)")
            }
            // Scheduled new booking notification for \(propertyName) if no error
        }
    }
    
    // Initialize previous bookings on first load
    func initializeBookingTracking(_ bookings: [Booking]) {
        previousBookingIds = Set(bookings.map { $0.id })
    }
}


