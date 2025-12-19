//
//  CleaningStatusDot.swift
//  BnBFox
//
//  Created on 12/16/2025.
//  Updated on 12/19/2025 - Added debug logging and fixed View conformance
//

import SwiftUI

struct CleaningStatusDot: View {
    let propertyName: String
    let propertyId: UUID
    let date: Date  // The date we're checking for
    let allBookings: [Booking]
    
    @ObservedObject var statusManager = CleaningStatusManager.shared
    
    var body: some View {
        Group {
            // Only show dot if this date is in the cleaning period
            if shouldShowDot() {
                if let status = statusManager.getStatus(propertyName: propertyName, date: date) {
                    Circle()
                        .fill(statusColor(status.status))
                        .frame(width: 8, height: 8)
                        .onAppear {
                            print("🟢 [CleaningStatusDot] Showing \(status.status.rawValue) dot for '\(propertyName)' on \(formatDate(date))")
                        }
                } else {
                    // Default to red (dirty/todo) if no status set yet
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .onAppear {
                            print("🔴 [CleaningStatusDot] No status found, showing RED dot for '\(propertyName)' on \(formatDate(date))")
                        }
                }
            } else {
                EmptyView()
                    .onAppear {
                        print("⚪️ [CleaningStatusDot] shouldShowDot=false for '\(propertyName)' on \(formatDate(date))")
                    }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    private func shouldShowDot() -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: date)
        let now = calendar.startOfDay(for: Date())  // Actual current date
        
        // Get all bookings for this property, sorted by end date
        let propertyBookings = allBookings
            .filter { $0.propertyId == propertyId }
            .sorted { $0.endDate < $1.endDate }
        
        // Debug logging
        let shouldLog = calendar.isDate(date, inSameDayAs: Date()) ||
                       (calendar.component(.day, from: date) == 18 &&
                        calendar.component(.month, from: date) == 12)
        
        if shouldLog {
            print("🔍 [CleaningStatusDot] Checking '\(propertyName)' on \(formatDate(date))")
            print("   - Property bookings count: \(propertyBookings.count)")
        }
        
        // Check if today falls in a gap between two consecutive bookings
        for i in 0..<propertyBookings.count {
            let currentBooking = propertyBookings[i]
            let checkoutDate = calendar.startOfDay(for: currentBooking.endDate)
            
            if shouldLog {
                print("   - Booking \(i): checkout=\(formatDate(checkoutDate)), now=\(formatDate(now))")
            }
            
            // IMPORTANT: Only show dots for checkouts that have already happened
            // Don't show dots for future checkouts
            if checkoutDate > now {
                if shouldLog {
                    print("   - Skipping future checkout")
                }
                continue  // Skip future bookings
            }
            
            // Check if there's a next booking
            if i + 1 < propertyBookings.count {
                let nextBooking = propertyBookings[i + 1]
                let nextCheckinDate = calendar.startOfDay(for: nextBooking.startDate)
                
                // Is today in the gap between this checkout and next check-in?
                if today >= checkoutDate && today <= nextCheckinDate {
                    // Only show if the gap is current or future (not past)
                    if nextCheckinDate >= now {
                        if shouldLog {
                            print("   ✅ Should show dot: in gap between bookings")
                        }
                        return true
                    }
                }
            } else {
                // This is the last booking - show dot if today is after checkout
                if today >= checkoutDate {
                    if shouldLog {
                        print("   ✅ Should show dot: after last checkout")
                    }
                    return true
                }
            }
        }
        
        if shouldLog {
            print("   ❌ Should NOT show dot")
        }
        return false
    }
    
    private func statusColor(_ status: CleaningStatus.Status) -> Color {
        switch status {
        case .pending:
            return .gray
        case .todo:
            return .red
        case .inProgress:
            return .orange  // Yellow/amber
        case .done:
            return .green
        }
    }
}

