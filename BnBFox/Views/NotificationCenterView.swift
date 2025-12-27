//
//  NotificationCenterView.swift
//  BnBShift
//
//  Optimized version using Copilot's architecture recommendations
//  - Uses @StateObject for persistent view model
//  - Per-row ObservableObjects for granular updates
//  - Async/await for non-blocking updates
//

import SwiftUI

struct NotificationCenterView: View {
    // MARK: - State
    @StateObject private var viewModel = NotificationCenterViewModel()
    @Environment(\.dismiss) var dismiss
    @State private var upcomingToday: [UpcomingEvent] = []
    @State private var currentTime = Date()
    
    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    var onNotificationTap: (Date) -> Void
    
    // MARK: - Body
    var body: some View {
        let _ = BadgeManager.shared.clearBadge()  // Clear badge when opening
        ZStack {
            List {
                // COMING UP TODAY Section
                if !upcomingToday.isEmpty {
                    Section(header: Text(NSLocalizedString("coming_up_today", comment: "")).font(.subheadline).foregroundColor(.secondary)) {
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
                Section(header: Text(NSLocalizedString("pending_tasks", comment: "")).font(.subheadline).foregroundColor(.secondary)) {
                    if viewModel.rowViewModels.isEmpty && upcomingToday.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 60))
                                .foregroundColor(.green)
                            Text(NSLocalizedString("all_caught_up", comment: ""))
                                .font(.headline)
                            Text(NSLocalizedString("no_pending_cleaning_tasks", comment: ""))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .listRowBackground(Color.clear)
                    } else if viewModel.rowViewModels.isEmpty {
                        Text(NSLocalizedString("no_pending_tasks", comment: ""))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 20)
                    } else {
                        ForEach(viewModel.rowViewModels) { rowVM in
                            NotificationRow(
                                rowViewModel: rowVM,
                                onToast: { message, icon in
                                    viewModel.showToastMessage(message, icon: icon)
                                }
                            )
                        }
                    }
                }
                
                // UPCOMING CLEANINGS Section (Next 30 Days)
                Section(header: Text(NSLocalizedString("upcoming_cleanings_30_days", comment: "")).font(.subheadline).foregroundColor(.secondary)) {
                    let upcomingCleanings = getUpcomingCleanings()
                    
                    if upcomingCleanings.isEmpty {
                        Text(NSLocalizedString("no_upcoming_cleanings", comment: ""))
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
            .navigationTitle(NSLocalizedString("cleaning_tasks", comment: ""))
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
                loadUpcomingToday()
            }
            
            // Toast overlay
            if viewModel.showToast {
                VStack {
                    Spacer()
                    HStack {
                        Text(viewModel.toastIcon)
                            .font(.title2)
                        Text(viewModel.toastMessage)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .padding()
                    .background(Color.black.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.bottom, 50)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.3), value: viewModel.showToast)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadUpcomingToday() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let properties = PropertyService.shared.getAllProperties()
        var events: [UpcomingEvent] = []
        
        for property in properties {
            let bookings = BookingService.shared.getCachedBookings(for: property)
            
            for booking in bookings {
                let checkoutDate = calendar.startOfDay(for: booking.endDate)
                let checkinDate = calendar.startOfDay(for: booking.startDate)
                
                if checkoutDate == today {
                    events.append(UpcomingEvent(
                        id: "\(booking.id)-checkout",
                        propertyName: property.displayName,
                        eventType: .checkout,
                        eventDate: booking.endDate
                    ))
                }
                
                if checkinDate == today {
                    events.append(UpcomingEvent(
                        id: "\(booking.id)-checkin",
                        propertyName: property.displayName,
                        eventType: .checkin,
                        eventDate: booking.startDate
                    ))
                }
            }
        }
        
        upcomingToday = events.sorted { $0.eventDate < $1.eventDate }
    }
    
    private func getUpcomingCleanings() -> [UpcomingCleaning] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let thirtyDaysFromNow = calendar.date(byAdding: .day, value: 30, to: today) else {
            return []
        }
        
        let properties = PropertyService.shared.getAllProperties()
        var cleanings: [UpcomingCleaning] = []
        
        for property in properties {
            let bookings = BookingService.shared.getCachedBookings(for: property)
            
            for booking in bookings {
                let checkoutDate = calendar.startOfDay(for: booking.endDate)
                
                if checkoutDate > today && checkoutDate <= thirtyDaysFromNow {
                    let isSameDayTurnover = bookings.contains { nextBooking in
                        calendar.isDate(nextBooking.startDate, inSameDayAs: booking.endDate) && nextBooking.id != booking.id
                    }
                    
                    let daysUntil = calendar.dateComponents([.day], from: today, to: checkoutDate).day ?? 0
                    
                    cleanings.append(UpcomingCleaning(
                        id: booking.id,
                        propertyName: property.shortName,
                        checkoutDate: booking.endDate,
                        isSameDayTurnover: isSameDayTurnover,
                        daysUntil: daysUntil
                    ))
                }
            }
        }
        
        return cleanings.sorted { $0.checkoutDate < $1.checkoutDate }
    }
}

// MARK: - NotificationRow (Optimized)

struct NotificationRow: View {
    @ObservedObject var rowViewModel: CleaningStatusRowViewModel
    let onToast: (String, String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Property name and status icon
            HStack {
                Circle()
                    .fill(Color.yellow)
                    .frame(width: 12, height: 12)
                
                Text(rowViewModel.propertyName)
                    .font(.headline)
                
                Spacer()
                
                // Show appropriate icon based on day's activity
                switch rowViewModel.dayActivityType {
                case .both:
                    Image("checkout-checkin")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                    Text(NSLocalizedString("checkout_checkin", comment: ""))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        
                case .checkinOnly:
                    Image("checkin")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                    Text(NSLocalizedString("check_in", comment: ""))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        
                case .checkoutOnly:
                    Image("checkout")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                    Text(NSLocalizedString("check_out", comment: ""))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Cleaning Status Buttons
            Text(NSLocalizedString("cleaning_status", comment: ""))
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 0) {
                Spacer()
                CleaningStatusButton(
                    imageName: "red-cleaning-button",
                    label: NSLocalizedString("dirty", comment: ""),
                    sublabel: NSLocalizedString("dirty_spanish", comment: ""),
                    isSelected: rowViewModel.currentStatus == .todo,
                    action: {
                        Task {
                            await rowViewModel.updateStatus(to: .todo, showToast: onToast)
                        }
                    }
                )
                
                Spacer()
                
                CleaningStatusButton(
                    imageName: "amber-cleaning-button",
                    label: NSLocalizedString("cleaning", comment: ""),
                    sublabel: NSLocalizedString("cleaning_spanish", comment: ""),
                    isSelected: rowViewModel.currentStatus == .inProgress,
                    action: {
                        Task {
                            await rowViewModel.updateStatus(to: .inProgress, showToast: onToast)
                        }
                    }
                )
                
                Spacer()
                
                CleaningStatusButton(
                    imageName: "green-cleaning-button",
                    label: NSLocalizedString("clean", comment: ""),
                    sublabel: NSLocalizedString("clean_spanish", comment: ""),
                    isSelected: rowViewModel.currentStatus == .done,
                    action: {
                        Task {
                            await rowViewModel.updateStatus(to: .done, showToast: onToast)
                        }
                    }
                )
                
                Spacer()
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - CleaningStatusButton (Unchanged)

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

// MARK: - Supporting Types (keep existing implementations)

struct UpcomingEvent: Identifiable {
    let id: String
    let propertyName: String
    let eventType: EventType
    let eventDate: Date
    
    enum EventType {
        case checkout, checkin
    }
}

struct UpcomingCleaning: Identifiable {
    let id: String
    let propertyName: String
    let checkoutDate: Date
    let isSameDayTurnover: Bool
    let daysUntil: Int
}

struct UpcomingEventRow: View {
    let event: UpcomingEvent
    let currentTime: Date
    
    // Calculate if we should show this row based on deadline
    private var shouldShow: Bool {
        let calendar = Calendar.current
        let deadline: Date
        
        if event.eventType == .checkout {
            // Checkout deadline is 10:00 AM
            deadline = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: event.eventDate) ?? event.eventDate
        } else {
            // Checkin deadline is 4:00 PM (16:00)
            deadline = calendar.date(bySettingHour: 16, minute: 0, second: 0, of: event.eventDate) ?? event.eventDate
        }
        
        return currentTime < deadline
    }
    
    // Calculate time remaining until deadline
    private var timeRemaining: String {
        let calendar = Calendar.current
        let deadline: Date
        
        if event.eventType == .checkout {
            deadline = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: event.eventDate) ?? event.eventDate
        } else {
            deadline = calendar.date(bySettingHour: 16, minute: 0, second: 0, of: event.eventDate) ?? event.eventDate
        }
        
        let components = calendar.dateComponents([.hour, .minute], from: currentTime, to: deadline)
        let hours = max(0, components.hour ?? 0)
        let minutes = max(0, components.minute ?? 0)
        
        return String(format: "%02d:%02d", hours, minutes)
    }
    
    var body: some View {
        if shouldShow {
            HStack {
                Image(systemName: event.eventType == .checkout ? "arrow.right.circle.fill" : "arrow.left.circle.fill")
                    .foregroundColor(event.eventType == .checkout ? .red : .green)
                
                VStack(alignment: .leading) {
                    Text(event.propertyName)
                        .font(.headline)
                    Text(event.eventType == .checkout ? NSLocalizedString("check_out", comment: "") : NSLocalizedString("check_in", comment: ""))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(event.eventType == .checkout ? NSLocalizedString("time_until_checkout", comment: "") : NSLocalizedString("time_until_checkin", comment: ""))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(timeRemaining)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

struct UpcomingCleaningListRow: View {
    let cleaning: UpcomingCleaning
    
    var body: some View {
        HStack {
            if cleaning.isSameDayTurnover {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
            }
            
            VStack(alignment: .leading) {
                Text(cleaning.propertyName)
                    .font(.headline)
                Text(cleaning.checkoutDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
                if cleaning.isSameDayTurnover {
                    Text(NSLocalizedString("same_day_turnover", comment: ""))
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                }
            }
            
            Spacer()
            
            Text("\(cleaning.daysUntil) \(NSLocalizedString("days", comment: ""))")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}


