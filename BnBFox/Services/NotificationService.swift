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
            var cleaningDays: [String: [Date: [Booking]]] = [:]
            
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
                guard let property = PropertyService.shared.getProperty(byId: propertyId) else {
                    continue
                }
                
                for (checkoutDate, bookingsOnDate) in dateBookings {
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
                        print("Scheduled cleaning alert for \(property.shortName) on \(checkoutDate)")
                    } catch {
                        print("Error scheduling notification: \(error)")
                    }
                }
            }
        }
    }
    
    // Cancel all cleaning alerts
    func cancelAllCleaningAlerts() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let cleaningIdentifiers = requests
                .filter { $0.identifier.starts(with: "cleaning_") }
                .map { $0.identifier }
            
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: cleaningIdentifiers)
            print("Cancelled \(cleaningIdentifiers.count) cleaning alerts")
        }
    }
    
    // Get count of pending alerts (for display in settings)
    func getPendingAlertsCount() async -> Int {
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        return requests.filter { $0.identifier.starts(with: "cleaning_") }.count
    }
}
