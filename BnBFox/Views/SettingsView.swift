//
//  SettingsView.swift
//  BnBFox
//
//  Created on 12/12/2025.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var settings = AppSettings.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var pendingAlertsCount = 0
    @State private var upcomingCleanings: [CleaningDay] = []
    
    var body: some View {
        NavigationView {
            Form {
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
                    
                    if settings.cleaningAlertsEnabled {
                        HStack {
                            Text("Pending Alerts")
                            Spacer()
                            Text("\(pendingAlertsCount)")
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
                
                // About Section
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("3.3")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await updatePendingCount()
                loadUpcomingCleanings()
            }
        }
    }
    
    private func updatePendingCount() async {
        pendingAlertsCount = await NotificationService.shared.getPendingAlertsCount()
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
        
        var cleaningDays: [String: [Date: [Booking]]] = [:]
        
        // Group bookings by property and checkout date
        for booking in bookings {
            let checkoutDate = calendar.startOfDay(for: booking.endDate)
            
            // Only include future cleanings within 30 days
            guard checkoutDate >= today && checkoutDate <= thirtyDaysFromNow else { continue }
            
            let propertyId = booking.propertyId
            
            if cleaningDays[propertyId] == nil {
                cleaningDays[propertyId] = [:]
            }
            if cleaningDays[propertyId]![checkoutDate] == nil {
                cleaningDays[propertyId]![checkoutDate] = []
            }
            cleaningDays[propertyId]![checkoutDate]!.append(booking)
        }
        
        // Convert to CleaningDay objects
        var cleanings: [CleaningDay] = []
        
        for (propertyId, dateBookings) in cleaningDays {
            guard let property = PropertyService.shared.getProperty(byId: propertyId) else {
                continue
            }
            
            for (checkoutDate, bookingsOnDate) in dateBookings {
                // Check if there's a same-day turnover
                let hasCheckin = bookings.contains { booking in
                    booking.propertyId == propertyId &&
                    calendar.isDate(booking.startDate, inSameDayAs: checkoutDate)
                }
                
                cleanings.append(CleaningDay(
                    id: "\(propertyId)_\(checkoutDate.timeIntervalSince1970)",
                    propertyName: property.shortName,
                    date: checkoutDate,
                    isUrgent: hasCheckin,
                    checkoutCount: bookingsOnDate.count
                ))
            }
        }
        
        // Sort: Urgent first, then by date
        upcomingCleanings = cleanings.sorted { a, b in
            if a.isUrgent != b.isUrgent {
                return a.isUrgent // Urgent first
            }
            return a.date < b.date // Then by date
        }
    }
}

// Model for cleaning day display
struct CleaningDay: Identifiable {
    let id: String
    let propertyName: String
    let date: Date
    let isUrgent: Bool
    let checkoutCount: Int
}

// Row view for cleaning day
struct CleaningDayRow: View {
    let cleaning: CleaningDay
    
    var body: some View {
        HStack {
            // Urgency indicator
            if cleaning.isUrgent {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
            } else {
                Image(systemName: "sparkles")
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(cleaning.propertyName)
                    .font(.headline)
                
                HStack {
                    Text(cleaning.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if cleaning.isUrgent {
                        Text("SAME-DAY TURNOVER")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    }
                }
            }
            
            Spacer()
            
            // Days until cleaning
            Text(daysUntilText)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private var daysUntilText: String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let cleaningDate = calendar.startOfDay(for: cleaning.date)
        
        if calendar.isDateInToday(cleaningDate) {
            return "Today"
        } else if calendar.isDateInTomorrow(cleaningDate) {
            return "Tomorrow"
        } else {
            let days = calendar.dateComponents([.day], from: today, to: cleaningDate).day ?? 0
            return "\(days) days"
        }
    }
}

#Preview {
    SettingsView()
}
