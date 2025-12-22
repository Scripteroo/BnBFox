//
//  SettingsView.swift
//  BnBFox
//
//  Updated with notification debugging tools
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var settings = AppSettings.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var pendingAlertsCount = 0
    @State private var upcomingCleanings: [CleaningDay] = []
    @State private var notificationStatus = "Checking..."
    @State private var showingTestAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                // Notification Status Section
                Section(header: Text("Notification Status")) {
                    HStack {
                        Text("Permission Status")
                        Spacer()
                        Text(notificationStatus)
                            .foregroundColor(notificationStatus == "Authorized" ? .green : .red)
                    }
                    
                    if notificationStatus != "Authorized" {
                        Button(action: {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack {
                                Image(systemName: "gear")
                                Text("Open Settings to Enable")
                                Spacer()
                                Image(systemName: "arrow.up.right.square")
                            }
                        }
                    }
                    
                    Button(action: {
                        Task {
                            await sendTestNotification()
                        }
                    }) {
                        HStack {
                            Image(systemName: "bell.badge")
                            Text("Send Test Notification")
                            Spacer()
                            Image(systemName: "paperplane")
                        }
                    }
                    
                    Button(action: {
                        Task {
                            await listScheduledNotifications()
                        }
                    }) {
                        HStack {
                            Image(systemName: "list.bullet")
                            Text("View Scheduled Notifications")
                            Spacer()
                            Image(systemName: "eye")
                        }
                    }
                }
                
                // Cleaning Alerts Section
                Section(header: Text("Cleaning Day Alerts")) {
                    Toggle("Enable Alerts", isOn: $settings.cleaningAlertsEnabled)
                        .onChange(of: settings.cleaningAlertsEnabled) { _ in
                            Task {
                                await updatePendingCount()
                            }
                        }
                    
                    Toggle("Alert Sound", isOn: $settings.alertSoundEnabled)
                        .disabled(!settings.cleaningAlertsEnabled)
                    
                    DatePicker(
                        "Alert Time",
                        selection: $settings.alertTime,
                        displayedComponents: .hourAndMinute
                    )
                    .disabled(!settings.cleaningAlertsEnabled)
                    .onChange(of: settings.alertTime) { _ in
                        Task {
                            // Reschedule notifications when time changes
                            await updatePendingCount()
                        }
                    }
                    
                    if settings.cleaningAlertsEnabled {
                        HStack {
                            Text("Pending Alerts")
                            Spacer()
                            Text("\(pendingAlertsCount)")
                                .foregroundColor(.secondary)
                        }
                        
                        Button(action: {
                            Task {
                                await forceRescheduleNotifications()
                            }
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Reschedule All Notifications")
                            }
                        }
                    }
                }
                
                // New Booking Alerts Section
                Section(header: Text("New Booking Alerts")) {
                    Toggle("Enable New Booking Alerts", isOn: $settings.newBookingAlertsEnabled)
                    
                    if settings.newBookingAlertsEnabled {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                            Text("Get notified when new bookings appear in the current month")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Upcoming Cleanings Section
                if settings.cleaningAlertsEnabled && !upcomingCleanings.isEmpty {
                    Section(header: Text("Upcoming Cleanings (Next 30 Days)")) {
                        ForEach(upcomingCleanings) { cleaning in
                            CleaningDayRow(cleaning: cleaning)
                        }
                    }
                }
                
                // Product Backlog Section
                Section(header: Text("Coming Soon")) {
                    HStack {
                        Image(systemName: "camera.fill")
                            .foregroundColor(.gray)
                        Text("Completion Photos")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("Planned")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.2))
                            .cornerRadius(4)
                    }
                    
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.gray)
                        Text("Damage Reporting")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("Planned")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                Task {
                    await checkNotificationStatus()
                    await updatePendingCount()
                    loadUpcomingCleanings()
                }
            }
            .alert("Test Notification Sent", isPresented: $showingTestAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("A test notification will appear in 5 seconds. Make sure the app is in the background to see it.")
            }
        }
    }
    
    private func checkNotificationStatus() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        
        await MainActor.run {
            switch settings.authorizationStatus {
            case .authorized:
                notificationStatus = "Authorized"
            case .denied:
                notificationStatus = "Denied"
            case .notDetermined:
                notificationStatus = "Not Requested"
            case .provisional:
                notificationStatus = "Provisional"
            case .ephemeral:
                notificationStatus = "Ephemeral"
            @unknown default:
                notificationStatus = "Unknown"
            }
        }
    }
    
    private func sendTestNotification() async {
        await NotificationService.shared.sendTestNotification()
        await MainActor.run {
            showingTestAlert = true
        }
    }
    
    private func listScheduledNotifications() async {
        await NotificationService.shared.listPendingNotifications()
        // Output will be in Xcode console
    }
    
    private func forceRescheduleNotifications() async {
        print("🔄 Force rescheduling all notifications...")
        NotificationService.shared.scheduleCleaningAlerts()
        await updatePendingCount()
    }
    
    private func updatePendingCount() async {
        let count = await NotificationService.shared.getPendingAlertsCount()
        await MainActor.run {
            pendingAlertsCount = count
        }
    }
    
    private func loadUpcomingCleanings() {
        Task {
            let allBookings = await PropertyService.shared.getAllBookings()
            await MainActor.run {
                processBookings(allBookings)
            }
        }
    }
    
    private func processBookings(_ bookings: [Booking]) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let thirtyDaysFromNow = calendar.date(byAdding: .day, value: 30, to: today)!
        
        var cleaningDays: [UUID: [Date: [Booking]]] = [:]
        
        // Group bookings by property and checkout date
        for booking in bookings {
            let checkoutDate = calendar.startOfDay(for: booking.endDate)
            
            // Only include future dates within 30 days
            guard checkoutDate >= today && checkoutDate <= thirtyDaysFromNow else { continue }
            
            if cleaningDays[booking.propertyId] == nil {
                cleaningDays[booking.propertyId] = [:]
            }
            if cleaningDays[booking.propertyId]![checkoutDate] == nil {
                cleaningDays[booking.propertyId]![checkoutDate] = []
            }
            cleaningDays[booking.propertyId]![checkoutDate]!.append(booking)
        }
        
        // Create CleaningDay objects
        var cleanings: [CleaningDay] = []
        for (propertyId, dateBookings) in cleaningDays {
            guard let property = PropertyService.shared.getProperty(by: propertyId) else { continue }
            
            for (checkoutDate, _) in dateBookings {
                // Check if there's a same-day checkin
                let hasCheckin = bookings.contains { booking in
                    booking.propertyId == propertyId &&
                    calendar.isDate(booking.startDate, inSameDayAs: checkoutDate)
                }
                
                let cleaning = CleaningDay(
                    id: UUID(),
                    propertyName: property.displayName,
                    date: checkoutDate,
                    isSameDayTurnover: hasCheckin
                )
                cleanings.append(cleaning)
            }
        }
        
        upcomingCleanings = cleanings.sorted { $0.date < $1.date }
    }
}

struct CleaningDay: Identifiable {
    let id: UUID
    let propertyName: String
    let date: Date
    let isSameDayTurnover: Bool
}

struct CleaningDayRow: View {
    let cleaning: CleaningDay
    
    var body: some View {
        HStack {
            if cleaning.isSameDayTurnover {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(cleaning.propertyName)
                    .font(.headline)
                
                HStack {
                    Text(formattedDate)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if cleaning.isSameDayTurnover {
                        Text("• SAME-DAY TURNOVER")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            
            Spacer()
            
            Text(relativeDays)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: cleaning.date)
    }
    
    private var relativeDays: String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let days = calendar.dateComponents([.day], from: today, to: cleaning.date).day ?? 0
        
        if days == 0 {
            return "Today"
        } else if days == 1 {
            return "Tomorrow"
        } else {
            return "\(days) days"
        }
    }
}


