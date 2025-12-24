//
//  OwnerInfoPanelView.swift
//  BnBShift
//
//  Created on 12/11/2025.
//

import SwiftUI

struct OwnerInfoPanelView: View {
    let property: Property
    @Environment(\.dismiss) var dismiss
    @State private var currentMonth = Date()
    @State private var bookings: [Booking] = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with property name
                VStack(spacing: 8) {
                    Text("Kawama Maintenance")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Owner Info Panel")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 12) {
                        Text("Kawama")
                            .font(.title3)
                        Text(property.shortName)
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                    
                    HStack(spacing: 16) {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.red)
                            .font(.title2)
                        
                        Image(systemName: "pencil")
                            .foregroundColor(.gray)
                            .font(.title2)
                    }
                    
                    // Current status display
                    currentStatusView()
                        .padding(.top, 8)
                }
                .padding()
                .background(Color(.systemGray6))
                
                Divider()
                
                // Calendar section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Calendar - \(property.shortName)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    // Month navigation
                    HStack {
                        Button(action: { previousMonth() }) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                        }
                        
                        Spacer()
                        
                        Text(currentMonth.monthYearString())
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Button(action: { nextMonth() }) {
                            Image(systemName: "chevron.right")
                                .font(.title2)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Calendar grid with platform labels enabled
                    MonthView(
                        month: currentMonth,
                        bookings: getBookingsForProperty(),
                        properties: [property],
                        showMonthTitle: false,
                        showDayHeaders: true
                    )
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("done", comment: "Done button")) {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await loadBookings()
        }
    }
    
    private func loadBookings() async {
        bookings = await BookingService.shared.fetchAllBookings(for: property)
    }
    
    private func getBookingsForProperty() -> [Booking] {
        return bookings.filter { $0.propertyId == property.id }
    }
    
    private func previousMonth() {
        let calendar = Calendar.current
        if let newMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = newMonth
        }
    }
    
    private func nextMonth() {
        let calendar = Calendar.current
        if let newMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
            currentMonth = newMonth
        }
    }
    
    @ViewBuilder
    private func currentStatusView() -> some View {
        let today = Date()
        let isOccupied = isPropertyOccupied(on: today)
        
        VStack(spacing: 8) {
            if isOccupied {
                // Show occupied status with colored bar
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(property.color)
                        .frame(width: 60, height: 20)
                    Text("Occupied")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
            } else {
                // Show vacant status with cleaning state
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 20)
                    Text("Vacant")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                // Show cleaning status
                HStack(spacing: 8) {
                    Circle()
                        .fill(cleaningStatusColor())
                        .frame(width: 12, height: 12)
                    Text(cleaningStatusText())
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private func isPropertyOccupied(on date: Date) -> Bool {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        
        for booking in getBookingsForProperty() {
            let bookingStart = calendar.startOfDay(for: booking.startDate)
            let bookingEnd = calendar.startOfDay(for: booking.endDate)
            
            // Check if today is during an active booking (before checkout)
            if dayStart >= bookingStart && dayStart < bookingEnd {
                return true
            }
        }
        return false
    }
    
    private func cleaningStatusColor() -> Color {
        let today = Date()
        if let status = CleaningStatusManager.shared.getStatus(propertyName: property.displayName, date: today) {
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
        return .red // Default to "to be cleaned"
    }
    
    private func cleaningStatusText() -> String {
        let today = Date()
        if let status = CleaningStatusManager.shared.getStatus(propertyName: property.displayName, date: today) {
            switch status.status {
            case .pending:
                return "Pending"
            case .todo:
                return "To be cleaned"
            case .inProgress:
                return "Cleaning"
            case .done:
                return NSLocalizedString("clean", comment: "Cleaning status")
            }
        }
        return "To be cleaned" // Default
    }
}

extension Date {
    func monthYearString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: self)
    }
}



