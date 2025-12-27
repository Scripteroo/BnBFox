//
//  NotificationService.swift
//  BnBFox
//
//  Simplified with single configurable notification time (default 9 AM)
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
            Logger.log("Error requesting notification authorization: \(error)")
            return false
        }
    }
    
    // Schedule cleaning alerts for all upcoming checkouts
    func scheduleCleaningAlerts() {
        Task {
            // First, ensure we have permission
            let authorized = await requestAuthorization()
            guard authorized else {
                Logger.log("Notification permission denied")
                return
            }
            
            // Cancel existing alerts before scheduling new ones
            cancelAllCleaningAlerts()
            
            // Get all bookings
            let bookings = await PropertyService.shared.getAllBookings()
            
            // Get alert time from settings
            let settings = AppSettings.shared
            guard settings.cleaningAlertsEnabled else {
                Logger.log("Cleaning alerts are disabled in settings")
                return
            }
            
            let calendar = Calendar.current
            let alertComponents = calendar.dateComponents([.hour, .minute], from: settings.alertTime)
            let alertHour = alertComponents.hour ?? 9  // Default to 9 AM
            let alertMinute = alertComponents.minute ?? 0
            
            Logger.log("📅 Scheduling cleaning alerts for \(alertHour):\(String(format: "%02d", alertMinute))")
            
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
            var scheduledCount = 0
            for (propertyId, dateBookings) in cleaningDays {
                guard let property = PropertyService.shared.getProperty(by: propertyId) else {
                    continue
                }
                
                for (checkoutDate, _) in dateBookings {
                    // Only schedule for future dates (including today)
                    let today = calendar.startOfDay(for: Date())
                    guard checkoutDate >= today else { continue }
                    
                    // Only schedule alerts for next 60 days
                    guard let maxDate = calendar.date(byAdding: .day, value: 60, to: today),
                          checkoutDate <= maxDate else { continue }
                    
                    // Check if there's a same-day turnover (checkout and checkin on same day)
                    let hasCheckin = bookings.contains { booking in
                        booking.propertyId == propertyId &&
                        calendar.isDate(booking.startDate, inSameDayAs: checkoutDate)
                    }
                    
                    let isUrgent = hasCheckin
                    
                    // Schedule single notification at configured time
                    let success = await scheduleNotification(
                        property: property,
                        checkoutDate: checkoutDate,
                        hour: alertHour,
                        minute: alertMinute,
                        isUrgent: isUrgent,
                        identifier: "cleaning_\(propertyId)_\(checkoutDate.timeIntervalSince1970)",
                        settings: settings
                    )
                    
                    if success {
                        scheduledCount += 1
                    }
                }
            }
            
            Logger.log("✅ Scheduled \(scheduledCount) cleaning notifications (next 60 days)")
        }
    }
    
    // Helper function to schedule a single notification
    private func scheduleNotification(
        property: Property,
        checkoutDate: Date,
        hour: Int,
        minute: Int,
        isUrgent: Bool,
        identifier: String,
        settings: AppSettings
    ) async -> Bool {
        let calendar = Calendar.current
        
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
        
        // Schedule for specific time on checkout date
        var notificationDate = calendar.dateComponents([.year, .month, .day], from: checkoutDate)
        notificationDate.hour = hour
        notificationDate.minute = minute
        
        // Check if notification time has already passed today
        if let notificationDateTime = calendar.date(from: notificationDate),
           notificationDateTime <= Date() {
            return false
        }
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: notificationDate, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        // Schedule the notification
        do {
            try await UNUserNotificationCenter.current().add(request)
            
            // Verbose logging removed for performance
            
            return true
        } catch {
            Logger.log("❌ Error scheduling notification for \(property.shortName): \(error)")
            return false
        }
    }
    
    // Cancel all cleaning alerts
    func cancelAllCleaningAlerts() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let cleaningIdentifiers = requests
                .filter { $0.identifier.starts(with: "cleaning_") }
                .map { $0.identifier }
            
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: cleaningIdentifiers)
            Logger.log("🗑️  Cancelled \(cleaningIdentifiers.count) previous cleaning alerts")
        }
    }
    
    // Get count of pending alerts (for display in settings)
    func getPendingAlertsCount() async -> Int {
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        return requests.filter { $0.identifier.starts(with: "cleaning_") }.count
    }
    
    // Debug: List all pending notifications
    func listPendingNotifications() async {
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        let cleaningRequests = requests.filter { $0.identifier.starts(with: "cleaning_") }
        
        Logger.log("\n📋 Pending Cleaning Notifications (\(cleaningRequests.count) total):")
        
        for request in cleaningRequests.sorted(by: { req1, req2 in
            guard let trigger1 = req1.trigger as? UNCalendarNotificationTrigger,
                  let trigger2 = req2.trigger as? UNCalendarNotificationTrigger,
                  let date1 = trigger1.nextTriggerDate(),
                  let date2 = trigger2.nextTriggerDate() else {
                return false
            }
            return date1 < date2
        }) {
            if let trigger = request.trigger as? UNCalendarNotificationTrigger,
               let nextTriggerDate = trigger.nextTriggerDate() {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
                Logger.log("  • \(request.content.title)")
                Logger.log("    \(request.content.body)")
                Logger.log("    Scheduled: \(formatter.string(from: nextTriggerDate))")
            }
        }
        Logger.log("")
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
                Logger.log("Error scheduling new booking notification: \(error)")
            } else {
                Logger.log("Scheduled new booking notification for \(propertyName)")
            }
        }
    }
    
    // Initialize previous bookings on first load
    func initializeBookingTracking(_ bookings: [Booking]) {
        previousBookingIds = Set(bookings.map { $0.id })
    }
    
    // MARK: - AC Filter Maintenance
    
    // Schedule quarterly AC filter change notifications
    func scheduleACFilterNotifications() {
        Task {
            // First, ensure we have permission
            let authorized = await requestAuthorization()
            guard authorized else {
                Logger.log("Notification permission denied")
                return
            }
            
            // Cancel existing AC filter alerts
            cancelACFilterNotifications()
            
            let calendar = Calendar.current
            let now = Date()
            
            // Get alert time from settings (same as cleaning alerts)
            let settings = AppSettings.shared
            let alertComponents = calendar.dateComponents([.hour, .minute], from: settings.alertTime)
            let alertHour = alertComponents.hour ?? 9
            let alertMinute = alertComponents.minute ?? 0
            
            Logger.log("🔧 Scheduling quarterly AC filter notifications")
            
            // Schedule 4 notifications for the next year (quarterly)
            for quarter in 0..<4 {
                guard let notificationDate = calendar.date(byAdding: .month, value: quarter * 3, to: now) else {
                    continue
                }
                
                // Set the time to the configured alert time
                var components = calendar.dateComponents([.year, .month, .day], from: notificationDate)
                components.hour = alertHour
                components.minute = alertMinute
                
                guard let scheduledDate = calendar.date(from: components),
                      scheduledDate > now else {
                    continue
                }
                
                // Create notification content
                let content = UNMutableNotificationContent()
                content.title = "🔧 Maintenance Reminder"
                content.body = "Time to change AC filters in all properties"
                content.categoryIdentifier = "MAINTENANCE"
                
                // Add sound if enabled
                if settings.alertSoundEnabled {
                    content.sound = .default
                }
                
                // Create trigger
                let triggerComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: scheduledDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
                
                // Create request
                let identifier = "ac_filter_\(quarter)"
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                
                // Schedule
                do {
                    try await UNUserNotificationCenter.current().add(request)
                    let formatter = DateFormatter()
                    formatter.dateStyle = .medium
                    formatter.timeStyle = .short
                    Logger.log("  ✅ Scheduled AC filter notification for \(formatter.string(from: scheduledDate))")
                } catch {
                    Logger.log("  ❌ Error scheduling AC filter notification: \(error)")
                }
            }
        }
    }
    
    // Cancel all AC filter notifications
    func cancelACFilterNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let acFilterIdentifiers = requests
                .filter { $0.identifier.starts(with: "ac_filter_") }
                .map { $0.identifier }
            
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: acFilterIdentifiers)
            Logger.log("🗑️  Cancelled \(acFilterIdentifiers.count) AC filter notifications")
        }
    }
    
    // MARK: - Test Notification (for debugging)
    
    func sendTestNotification() async {
        let content = UNMutableNotificationContent()
        content.title = "🧪 Test Notification"
        content.body = "BnBFox notifications are working!"
        content.sound = .default
        
        // Trigger in 5 seconds
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "test_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            Logger.log("✅ Test notification scheduled for 5 seconds from now")
        } catch {
            Logger.log("❌ Error scheduling test notification: \(error)")
        }
    }
}



