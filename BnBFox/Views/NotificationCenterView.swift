//
//  NotificationCenterView.swift
//  BnBFox
//
//  Created on 12/15/25.
//

import SwiftUI

struct NotificationCenterView: View {
    @ObservedObject var statusManager = CleaningStatusManager.shared
    @StateObject private var settings = AppSettings.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var upcomingCleanings: [CleaningDay] = []
    
    var onNotificationTap: (Date) -> Void
    
    var body: some View {
        let _ = BadgeManager.shared.clearBadge()  // Clear badge when opening
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Pending Cleaning Tasks Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Pending Tasks")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                        
                        let pendingStatuses = statusManager.getPendingStatuses()
                        
                        if pendingStatuses.isEmpty {
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
                        } else {
                            ForEach(pendingStatuses) { status in
                                PendingTaskCard(status: status)
                                    .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.top)
                    
                    // Upcoming Cleanings Section
                    if settings.cleaningAlertsEnabled && !upcomingCleanings.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Upcoming Cleanings (Next 30 Days)")
                                .font(.headline)
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                            
                            ForEach(upcomingCleanings) { cleaning in
                                CleaningDayCard(cleaning: cleaning)
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.bottom, 32)
            }
            .navigationTitle("Cleaning Tasks")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                loadUpcomingCleanings()
            }
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
            guard let property = PropertyService.shared.getProperty(by: propertyId) else {
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

// Card view for pending task with inline cleaning buttons
struct PendingTaskCard: View {
    let status: CleaningStatus
    @State private var showYellowTooltip = false
    @State private var showGreenTooltip = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with property name and date
            VStack(alignment: .leading, spacing: 4) {
                Text(status.propertyName)
                    .font(.system(size: 20, weight: .bold))
                
                HStack(spacing: 8) {
                    Text(formattedDate)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(status.status.displayName)
                        .font(.subheadline)
                        .foregroundColor(statusColor)
                }
            }
            
            Divider()
            
            // Cleaning Status Buttons
            VStack(spacing: 12) {
                Text("Cleaning Status")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                
                CleaningStatusButtons(
                    propertyName: status.propertyName,
                    date: status.date,
                    bookingId: status.bookingId,
                    showYellowTooltip: $showYellowTooltip,
                    showGreenTooltip: $showGreenTooltip
                )
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private var statusColor: Color {
        switch status.status {
        case .pending:
            return .gray
        case .todo:
            return .red
        case .inProgress:
            return .orange
        case .done:
            return .green
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: status.date)
    }
}

// Card view for upcoming cleaning
struct CleaningDayCard: View {
    let cleaning: CleaningDay
    
    var body: some View {
        HStack {
            // Urgency indicator
            if cleaning.isUrgent {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                    .font(.system(size: 20))
            } else {
                Image(systemName: "sparkles")
                    .foregroundColor(.blue)
                    .font(.system(size: 20))
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
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
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

// Model for cleaning day display
struct CleaningDay: Identifiable {
    let id: String
    let propertyName: String
    let date: Date
    let isUrgent: Bool
    let checkoutCount: Int
}

