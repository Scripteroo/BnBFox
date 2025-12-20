//
//  CleaningStatusDot.swift
//  BnBFox
//
//  Created on 12/16/2025.
//

import SwiftUI

struct CleaningStatusDot: View {
    let propertyName: String
    let propertyId: UUID
    let date: Date  // The date we're checking for
    let allBookings: [Booking]
    
    @ObservedObject var statusManager = CleaningStatusManager.shared
    
    var body: some View {
        // Only show dot if this date is in the cleaning period
        if shouldShowDot(), let checkoutDate = getCurrentGapCheckoutDate() {
            // Use status from the checkout date for ALL days in the gap
            if let status = statusManager.getStatus(propertyName: propertyName, date: checkoutDate) {
                Circle()
                    .fill(statusColor(status.status))
                    .frame(width: 8, height: 8)
            } else {
                // Default to red (dirty/todo) if no status set yet
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
            }
        }
    }
    
    private func getCurrentGapCheckoutDate() -> Date? {
        let calendar = Calendar.current
        let now = calendar.startOfDay(for: Date())
        
        let propertyBookings = allBookings
            .filter { $0.propertyId == propertyId }
            .sorted { $0.endDate < $1.endDate }
        
        // Find the checkout that creates a gap containing TODAY
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
            
            // Check if TODAY falls in this gap
            if let checkin = nextCheckin {
                // Gap extends through checkin day until next morning (after first night)
                let dayAfterCheckin = calendar.date(byAdding: .day, value: 1, to: checkin) ?? checkin
                if now >= checkoutDate && now < dayAfterCheckin {
                    return checkoutDate
                }
            } else {
                // No next booking - gap extends 7 days
                let weekLater = calendar.date(byAdding: .day, value: 7, to: checkoutDate) ?? checkoutDate
                if now >= checkoutDate && now <= weekLater {
                    return checkoutDate
                }
            }
        }
        
        return nil
    }
    
    private func shouldShowDot() -> Bool {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let now = calendar.startOfDay(for: Date())
        
        // Get all bookings for this property
        let propertyBookings = allBookings.filter { $0.propertyId == propertyId }
        
        // DON'T show dots on days that have an active booking
        for booking in propertyBookings {
            let bookingStart = calendar.startOfDay(for: booking.startDate)
            let bookingEnd = calendar.startOfDay(for: booking.endDate)
            // Check if this day is DURING a booking (day AFTER checkin through day before checkout)
            // Checkin day is NOT considered active booking (guests arrive at 4 PM, cleaning happens before)
            if dayStart > bookingStart && dayStart < bookingEnd {
                return false  // Active booking, no dot
            }
        }
        
        // Find the checkout that creates a gap containing TODAY
        var currentGapCheckout: Date?
        var currentGapCheckin: Date?
        
        for booking in propertyBookings {
            let checkoutDate = calendar.startOfDay(for: booking.endDate)
            
            // Find next checkin after this checkout
            var nextCheckin: Date?
            for nextBooking in propertyBookings {
                let checkinDate = calendar.startOfDay(for: nextBooking.startDate)
                if checkinDate > checkoutDate {
                    if nextCheckin == nil || checkinDate < nextCheckin! {
                        nextCheckin = checkinDate
                    }
                }
            }
            
            // Check if TODAY falls in this gap
            if let checkin = nextCheckin {
                // Gap extends through checkin day until next morning
                let dayAfterCheckin = calendar.date(byAdding: .day, value: 1, to: checkin) ?? checkin
                if now >= checkoutDate && now < dayAfterCheckin {
                    currentGapCheckout = checkoutDate
                    currentGapCheckin = checkin  // Store actual checkin, not day after
                    break
                }
            } else {
                // No next booking - gap extends 7 days
                let weekLater = calendar.date(byAdding: .day, value: 7, to: checkoutDate) ?? checkoutDate
                if now >= checkoutDate && now <= weekLater {
                    currentGapCheckout = checkoutDate
                    currentGapCheckin = weekLater
                    break
                }
            }
        }
        
        // Only show dot if we found a current gap AND this day is in it
        guard let gapStart = currentGapCheckout, let gapEnd = currentGapCheckin else {
            return false
        }
        
        // Show dot from checkout day through checkin day (inclusive)
        // BUT only show dots on dates that are today or in the past (not future dates)
        return dayStart >= gapStart && dayStart <= gapEnd && dayStart <= now
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



